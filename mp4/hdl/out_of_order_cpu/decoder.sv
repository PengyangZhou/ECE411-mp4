/* This is the decoder, which is responsible for issuing instructions. */
// `include "cdb_itf.sv"

import rv32i_types::*;
import ooo_types::*;

module decoder (
    input logic clk,
    input logic rst,
    /* port from instruction queue */
    input logic      valid_in,
    input rv32i_word pc_in,
    input rv32i_word pc_next_in,
    input rv32i_word inst_in,
    input logic      br_pred_in,
    /* port to instruction queue */
    output logic     shift,
    /* port to regfile */
    output rv32i_reg    rs1,
    output rv32i_reg    rs2,
    /* port from regfile */
    input tag_t         reg_Qj,
    input tag_t         reg_Qk,
    input rv32i_word    reg_Vj,
    input rv32i_word    reg_Vk,
    /* port to ROB */
    output logic        rob_valid,  /* indicate there is a new inst coming */
    output op_type_t    rob_op,     /* there are 3 types of operation in ROB */
    output rv32i_word   rob_dest,   /* destination can be ROB entry or memory address */
    output tag_t        rob_Qj,     /* these 2 ports are for ROB read */
    output tag_t        rob_Qk,
    /* port from ROB */
    input logic         rob_ready,
    input rv32i_word    rob_Vj,
    input rv32i_word    rob_Vk,
    /* port to ALU RS */
    alu_rs_itf.decoder  alu_itf,
    /* port to CMP RS */
    cmp_rs_itf.decoder  cmp_itf,
    /* port to Load/Store buffer */
    lsb_rs_itf.decoder  lsb_itf
);
    /* implemented as to take 1 cycle to decode */
    /* May need accommodation due to long critical path */
    
    /* intermediate variables */
    logic [2:0] funct3;
    logic [6:0] funct7;
    rv32i_opcode opcode;
    logic [31:0] i_imm;
    logic [31:0] s_imm;
    logic [31:0] b_imm;
    logic [31:0] u_imm;
    logic [31:0] j_imm;
    logic [4:0] rs1;
    logic [4:0] rs2;
    logic [4:0] rd;
    
    /* instruction deconstruction */
    assign funct3 = inst_in[14:12];
    assign funct7 = inst_in[31:25];
    assign opcode = rv32i_opcode'(inst_in[6:0]);
    assign i_imm = {{21{inst_in[31]}}, inst_in[30:20]};
    assign s_imm = {{21{inst_in[31]}}, inst_in[30:25], inst_in[11:7]};
    assign b_imm = {{20{inst_in[31]}}, inst_in[7], inst_in[30:25], inst_in[11:8], 1'b0};
    assign u_imm = {inst_in[31:12], 12'h000};
    assign j_imm = {{12{inst_in[31]}}, inst_in[19:12], inst_in[20], inst_in[30:21], 1'b0};
    assign rs1 = inst_in[19:15];
    assign rs2 = inst_in[24:20];
    assign rd = inst_in[11:7];
    
    /* main logic */
    always_ff @( posedge clk ) begin
        case (opcode)
            nop: ;

            op_lui: ;

            op_auipc: ;

            op_br:;

            op_jal: ;

            op_load, op_store: ;

            op_imm: ;
            
            op_reg: ;
            
            default: 
        endcase
    end

endmodule
