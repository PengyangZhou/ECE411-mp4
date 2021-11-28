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

assign rvfi.commit = dut.ooo_cpu.load_val_rob_reg | dut.ooo_cpu.br_mispredict; // Set high when a valid instruction is modifying regfile or PC
assign rvfi.halt = dut.ooo_cpu.trap;   // Set high when you detect an infinite loop
initial rvfi.order = 0;
always @(posedge itf.clk iff rvfi.commit) rvfi.order <= rvfi.order + 1; // Modify for OoO

/* print register values at the end of simulation */
always @(posedge rvfi.halt)begin 
    for (int i = 0; i < 32; ++i) begin
        $display("reg x%0d: 0x%8h", i, dut.ooo_cpu.regfile_inst.reg_vals[i]);
    end
    $display("Total cycles: %0d\n", total_cycles);
    $display("Stall cycles: %0d\n", stall_cycles);
    
end

/* set up counters for profiling */
int total_cycles;   /* the counter for total cycles elapsed */
int stall_cycles;   /* the counter for cycles that no instruction is issued */
initial total_cycles = 0;
initial stall_cycles = 0;
always @(negedge cpu_clk) begin
    total_cycles <= total_cycles + 1;
    if(~dut.ooo_cpu.iq_shift) stall_cycles <= stall_cycles + 1;
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
