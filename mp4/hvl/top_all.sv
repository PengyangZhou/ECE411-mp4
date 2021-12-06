module mp4_tb;
`timescale 1ns/10ps
import ooo_types::*;

/********************* Do not touch for proper compilation *******************/
// Instantiate Interfaces
tb_itf itf();
rvfi_itf rvfi(itf.clk, itf.rst);

// Instantiate Testbench
source_tb tb(
    .magic_mem_itf(itf),
    .mem_itf(itf),
    .sm_itf(itf),
    .tb_itf(itf),
    .rvfi(rvfi)
);

// For local simulation, add signal for Modelsim to display by default
// Note that this signal does nothing and is not used for anything
bit cpu_clk;
assign cpu_clk = itf.clk;

/****************************** End do not touch *****************************/

/************************ Signals necessary for monitor **********************/
// This section not required until CP2

assign rvfi.commit = dut.ooo_cpu.load_val_rob_reg | dut.ooo_cpu.br_predict; // Set high when a valid instruction is modifying regfile or PC
assign rvfi.halt = dut.ooo_cpu.trap;   // Set high when you detect an infinite loop
initial rvfi.order = 0;
always @(posedge itf.clk iff rvfi.commit) rvfi.order <= rvfi.order + 1; // Modify for OoO

/* set up counters for profiling */
int total_cycles;   /* the counter for total cycles elapsed */
int stall_cycles, stall_icache_read, stall_rs_full;   /* the counter for cycles that no instruction is issued */
int icache_ops, icache_hits; /* counter for cache operations and hits */
int dcache_ops, dcache_hits;
int num_branch, num_branch_correct; /* counter for branch prediction results */
int num_jalr, num_jalr_correct;
logic [31:0] last_addr_i, last_addr_d;
int alu_usage, cmp_usage, lsb_usage; 
int alu_working, cmp_working, lsb_working;
int alu_full, cmp_full, lsb_full, rob_full; /* rob_full indicates the # of cycles ROB is full */

initial begin
    total_cycles    = 0;
    stall_cycles    = 0;
    icache_ops      = 0;
    icache_hits     = 0;
    dcache_ops      = 0;
    dcache_hits     = 0; 
    last_addr_i     = 32'b0;
    last_addr_d     = 32'b0;
    alu_usage       = 0;
    cmp_usage       = 0;
    lsb_usage       = 0;
    rob_full        = 0;
    alu_working     = 0;
    cmp_working     = 0;
    lsb_working     = 0;
end
/* increment counters */
always @(negedge cpu_clk) begin
    /* instruction issue counters */
    total_cycles <= total_cycles + 1;
    if(~dut.ooo_cpu.iq_shift) begin
        stall_cycles <= stall_cycles + 1;
        if(dut.ooo_cpu.valid_decoder) stall_rs_full <= stall_rs_full + 1;
        else stall_icache_read <= stall_icache_read + 1;
    end
    /* icache counters */
    if(dut.icache.mem_address != last_addr_i)begin
        icache_ops <= icache_ops + 1;
        last_addr_i <= dut.icache.mem_address; /* update last address */
        if(dut.icache.control.hit == 1'b1) icache_hits <= icache_hits + 1;
    end
    /* dcache counters */
    if(dut.dcache.mem_address != last_addr_d && dut.dcache.control.state == 1)begin
        dcache_ops <= dcache_ops + 1;
        last_addr_d <= dut.dcache.mem_address;
        if(dut.dcache.control.hit) dcache_hits <= dcache_hits + 1;
    end
    /* reservation station counters */
    if(dut.ooo_cpu.alu_rs_inst.busy)begin 
        alu_usage <= alu_usage + dut.ooo_cpu.alu_rs_inst.busy[0] + dut.ooo_cpu.alu_rs_inst.busy[1] +
            dut.ooo_cpu.alu_rs_inst.busy[2] + dut.ooo_cpu.alu_rs_inst.busy[3] +
            dut.ooo_cpu.alu_rs_inst.busy[4];
        alu_working <= alu_working + 1;
    end
    if(dut.ooo_cpu.lsb_rs_inst.busy)begin
        lsb_usage <= lsb_usage + dut.ooo_cpu.lsb_rs_inst.busy[0] + dut.ooo_cpu.lsb_rs_inst.busy[1] +
            dut.ooo_cpu.lsb_rs_inst.busy[2] + dut.ooo_cpu.lsb_rs_inst.busy[3] +
            dut.ooo_cpu.lsb_rs_inst.busy[4] + dut.ooo_cpu.lsb_rs_inst.busy[5] +
            dut.ooo_cpu.lsb_rs_inst.busy[6];
        lsb_working <= lsb_working + 1;
    end
    if(dut.ooo_cpu.cmp_rs_inst.busy)begin
        cmp_usage <= cmp_usage + dut.ooo_cpu.cmp_rs_inst.busy[0] + dut.ooo_cpu.cmp_rs_inst.busy[1] +
            dut.ooo_cpu.cmp_rs_inst.busy[2];
        cmp_working <= cmp_working + 1;
    end
    /* fullness counter */
    if(~dut.ooo_cpu.alu_itf.ready) alu_full <= alu_full + 1;
    if(~dut.ooo_cpu.cmp_itf.ready) cmp_full <= cmp_full + 1;
    if(~dut.ooo_cpu.lsb_itf.ready) lsb_full <= lsb_full + 1;
    if(dut.ooo_cpu.rob_data.tag_ready == 0) rob_full <= rob_full + 1;
    /* branch prediction counters */
    if(dut.ooo_cpu.br_predict) begin
        num_branch <= num_branch + 1;
        if(dut.ooo_cpu.br_correct) num_branch_correct <= num_branch_correct + 1;
    end
    if(dut.ooo_cpu.jalr_predict) begin
        num_jalr <= num_jalr + 1;
        if(dut.ooo_cpu.jalr_correct) num_jalr_correct <= num_jalr_correct + 1;
    end
end

/* print register values at the end of simulation */
always @(posedge rvfi.halt)begin 
    for (int i = 0; i < 32; ++i) begin
        $display("reg x%0d: 0x%8h", i, dut.ooo_cpu.regfile_inst.reg_vals[i]);
    end
    $display("\nExecution Time: %0dns", total_cycles * 10);
    $display("Total Cycles: %0d", total_cycles);
    $display("Stall Cycles: %0d, %0d due to icache read, %0d due to RS fullness", stall_cycles, stall_icache_read, stall_rs_full);
    $display("Percentage of correctly predicted branch: %f%% (%0d/%0d)", 100.0*num_branch_correct/num_branch, num_branch_correct, num_branch);
    $display("Percentage of correctly predicted jalr: %f%% (%0d/%0d)", 100.0*num_jalr_correct/num_jalr, num_jalr_correct, num_jalr);
    $display("Percentage of correctly predicted branch/jal/jalr: %f%% (%0d/%0d) (all jal/jalr jumps are considered correct)", 
        100.0*(num_branch_correct+num_jalr)/(num_branch+num_jalr), num_branch_correct+num_jalr_correct, num_branch+num_jalr);
    $display("Percentage of issuing instructions: %f%%", 100.0*(total_cycles-stall_cycles)/total_cycles);
    $display("icache operations: %0d  icache hits: %0d", icache_ops, icache_hits);
    $display("icache hit rate: %f%%", 100.0*icache_hits/icache_ops);
    $display("dcache operations: %0d  dcache hits: %0d", dcache_ops, dcache_hits);
    $display("dcache hit rate: %f%%", 100.0*dcache_hits/dcache_ops);
    $display("ALU reservation station utilization: %f%%, ALU full cycles: %0d", 100.0*alu_usage/alu_working/5, alu_full);
    $display("LSB reservation station utilization: %f%%, LSB full cycles: %0d", 100.0*lsb_usage/lsb_working/3, lsb_full);
    $display("CMP reservation station utilization: %f%%, CMP full cycles: %0d", 100.0*cmp_usage/cmp_working/3, cmp_full);
    $display("ROB full cycles: %0d", rob_full);
    $display("\n");
end

/* connect to shadow memory */
assign itf.inst_read = dut.icache_read;
assign itf.inst_addr = dut.icache_address;
// assign itf.inst_resp = dut.icache_resp;
// assign itf.inst_rdata = dut.icache_rdata;
assign itf.data_read = dut.dcache_read;
assign itf.data_write = dut.dcache_write;
assign itf.data_mbe = dut.dcache_byte_enable;
assign itf.data_addr = dut.dcache_address;
assign itf.data_wdata = dut.dcache_wdata;
// assign itf.data_resp = dut.dcache_resp;
// assign itf.data_rdata = dut.dcache_rdata;

mp4 dut(
    .clk(itf.clk),
    .rst(itf.rst),
    .pmem_resp(itf.mem_resp),
    .pmem_rdata(itf.mem_rdata),
    .pmem_read(itf.mem_read),
    .pmem_write(itf.mem_write),
    .pmem_address(itf.mem_addr),
    .pmem_wdata(itf.mem_wdata)
);

endmodule
