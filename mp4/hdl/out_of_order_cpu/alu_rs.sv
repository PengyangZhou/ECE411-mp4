/* This is the ALU reservation station. */

module alu_rs (
    input logic         clk,
    input logic         rst, 
    /* port from decoder */
    alu_rs_itf.alu_rs   alu_itf,
    /* port to cdb */
    alu_cdb             alu_res
);

    
    
endmodule
