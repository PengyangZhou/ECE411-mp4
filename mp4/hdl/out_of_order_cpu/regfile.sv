import ooo_itfs::*;

module regfile(
    input logic clk,
    input logic rst,
    input logic flush,
    // port from ROB
    input logic load,
    input rv32i_reg rd,
    input rv32i_word val,
    input tag_t tag,
    // port from decoder
    input rv32i_reg rs1,
    input rv32i_reg rs2,
    // port to decoder
    output rv32i_word rs1_out,
    output rv32i_word rs2_out,
    output tag_t t1_out,
    output tag_t t2_out
);



endmodule : regfile
