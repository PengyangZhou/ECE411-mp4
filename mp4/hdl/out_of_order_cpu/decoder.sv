/* This is decoder. */
`include "include/cdb_itf.sv"

import rv32i_types::*;
import ooo_types::*;

module decoder (
    input logic clk,
    input logic rst,
    /* port from instruction queue */
    input rv32i_word pc_in,
    input rv32i_word pc_next_in,
    input rv32i_word inst_in,
    input logic br_pred_in,
    /* port to instruction queue */
    output logic shift,
    /* port to regfile */
    output rv32i_reg rs1,
    output rv32i_reg rs2,
    /* port from regfile */
    input tag_t Qi,
    input rv32i_word Vi,
    /* port to ALU RS */
    
    /* port to CMP RS */
    /* port to Load/Store buffer */
);
    
endmodule
