module mp4_tb;
`timescale 1ns/10ps

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
int stall_cycles;   /* the counter for cycles that no instruction is issued */
int icache_ops, icache_hits; /* counter for cache operations and hits */
int dcache_ops, dcache_hits;
logic [31:0] last_addr_i, last_addr_d;
int alu_usage, cmp_usage, lsb_usage;
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
end
/* increment counters */
always @(negedge cpu_clk) begin
    /* instruction issue counters */
    total_cycles <= total_cycles + 1;
    if(~dut.ooo_cpu.iq_shift) stall_cycles <= stall_cycles + 1;
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
    alu_usage <= alu_usage + dut.ooo_cpu.alu_rs_inst.busy[0] + dut.ooo_cpu.alu_rs_inst.busy[1] +
        dut.ooo_cpu.alu_rs_inst.busy[2] + dut.ooo_cpu.alu_rs_inst.busy[3] +
        dut.ooo_cpu.alu_rs_inst.busy[4];
    lsb_usage <= lsb_usage + dut.ooo_cpu.lsb_rs_inst.busy[0] + dut.ooo_cpu.lsb_rs_inst.busy[1] +
        dut.ooo_cpu.lsb_rs_inst.busy[2];
    cmp_usage <= cmp_usage + dut.ooo_cpu.cmp_rs_inst.busy[0] + dut.ooo_cpu.cmp_rs_inst.busy[1] +
        dut.ooo_cpu.cmp_rs_inst.busy[2];
end

/* print register values at the end of simulation */
always @(posedge rvfi.halt)begin 
    for (int i = 0; i < 32; ++i) begin
        $display("reg x%0d: 0x%8h", i, dut.ooo_cpu.regfile_inst.reg_vals[i]);
    end
    $display("\nExecution Time: %0dns", total_cycles * 10);
    $display("Total Cycles: %0d", total_cycles);
    $display("Stall Cycles: %0d", stall_cycles);
    $display("Percentage of issuing instructions: %f%%", 100.0*(total_cycles-stall_cycles)/total_cycles);
    $display("icache operations: %0d  icache hits: %0d", icache_ops, icache_hits);
    $display("icache hit rate: %f%%", 100.0*icache_hits/icache_ops);
    $display("dcache operations: %0d  dcache hits: %0d", dcache_ops, dcache_hits);
    $display("dcache hit rate: %f%%", 100.0*dcache_hits/dcache_ops);
    $display("ALU reservation station utilization: %f%%", 100.0*alu_usage/total_cycles/5);
    $display("LSB reservation station utilization: %f%%", 100.0*lsb_usage/total_cycles/3);
    $display("CMP reservation station utilization: %f%%", 100.0*cmp_usage/total_cycles/3);
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
