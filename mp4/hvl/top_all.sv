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
always @(rvfi.halt iff (rvfi.halt == 1'b1))begin 
    for (int i = 0; i < 32; ++i) begin
        $display("reg x%0d: 0x%8h", i, dut.ooo_cpu.regfile_inst.reg_vals[i]);
    end
end

// Set this to the proper value
// assign itf.registers = '{default: '0};

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
