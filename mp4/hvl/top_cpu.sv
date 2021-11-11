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
// bit f;

/****************************** End do not touch *****************************/

/************************ Signals necessary for monitor **********************/
// This section not required until CP2

assign rvfi.commit = dut.load_val_rob_reg | dut.br_mispredict; // Set high when a valid instruction is modifying regfile or PC
assign rvfi.halt = dut.trap;   // Set high when you detect an infinite loop
initial rvfi.order = 0;
always @(posedge itf.clk iff rvfi.commit) rvfi.order <= rvfi.order + 1; // Modify for OoO

/* print register values at the end of simulation */
always @(rvfi.halt iff (rvfi.halt == 1'b1))begin 
    for (int i = 0; i < 32; ++i) begin
        $display("reg x%0d: %0h", i, dut.regfile_inst.reg_vals[i]);
    end
end


/*
The following signals need to be set:
Instruction and trap:
    rvfi.inst
    rvfi.trap

Regfile:
    rvfi.rs1_addr
    rvfi.rs2_add
    rvfi.rs1_rdata
    rvfi.rs2_rdata
    rvfi.load_regfile
    rvfi.rd_addr
    rvfi.rd_wdata

PC:
    rvfi.pc_rdata
    rvfi.pc_wdata

Memory:
    rvfi.mem_addr
    rvfi.mem_rmask
    rvfi.mem_wmask
    rvfi.mem_rdata
    rvfi.mem_wdata

Please refer to rvfi_itf.sv for more information.
*/

// assign rvfi_itf.inst = dut.inst_decoder;
// assign rvfi_itf.trap = dut.trap; /* NOT USED */
// assign rvfi_itf.rs1_addr = dut.rs1;
// assign rvfi_itf.rs2_addr = dut.rs2;
// assign rvfi_itf.rs1_rdata = dut.decoder_inst.Vj_out;
// assign rvfi_itf.rs2_rdata = dut.decoder_inst.Vk_out;
// assign rvfi_itf.load_regfile = dut.rob_inst.load_val;
// assign rvfi_itf.rd_addr = dut.rob_inst.val_rd;
// assign rvfi_itf.rd_wdata = dut.rob_inst.val;
// assign rvfi_itf.pc_rdata = 
// assign rvfi_itf.pc_wdata = 
// assign rvfi_itf.mem_addr = 
// assign rvfi_itf.mem_rmask = 
// assign rvfi_itf.mem_wmask = dut.mem_byte_enable_d;
// assign rvfi_itf.mem_rdata = dut.mem_rdata_d;
// assign rvfi_itf.mem_wdata = dut.mem_wdata_d;

/**************************** End RVFIMON signals ****************************/

/********************* Assign Shadow Memory Signals Here *********************/
// This section not required until CP2
/*
The following signals need to be set:
icache signals:
    itf.inst_read
    itf.inst_addr
    itf.inst_resp
    itf.inst_rdata

dcache signals:
    itf.data_read
    itf.data_write
    itf.data_mbe
    itf.data_addr
    itf.data_wdata
    itf.data_resp
    itf.data_rdata

Please refer to tb_itf.sv for more information.
*/

/*********************** End Shadow Memory Assignments ***********************/

// Set this to the proper value
assign itf.registers = '{default: '0};

/*********************** Instantiate your design here ************************/
/*
The following signals need to be connected to your top level:
Clock and reset signals:
    itf.clk
    itf.rst

Burst Memory Ports:
    itf.mem_read
    itf.mem_write
    itf.mem_wdata
    itf.mem_rdata
    itf.mem_addr
    itf.mem_resp

Please refer to tb_itf.sv for more information.
*/

cpu dut(
    .clk(itf.clk),
    .rst(itf.rst),
    /* instruction cache */
    .mem_resp_i(itf.inst_resp),
    .mem_rdata_i(itf.inst_rdata),
    .mem_read_i(itf.inst_read),
    .mem_address_i(itf.inst_addr),
    /* data cache */
    .mem_resp_d(itf.data_resp),
    .mem_rdata_d(itf.data_rdata),
    .mem_read_d(itf.data_read),
    .mem_write_d(itf.data_write),
    .mem_byte_enable_d(itf.data_mbe),
    .mem_address_d(itf.data_addr),
    .mem_wdata_d(itf.data_wdata)
);
/***************************** End Instantiation *****************************/

endmodule
