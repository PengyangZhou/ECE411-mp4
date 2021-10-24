/* This is the top-level module of our out-of-order processor. */

import rv32i_types::*;

module cpu (
    input clk,
    input rst,
    input mem_resp,
    input rv32i_word mem_rdata,
    output logic mem_read,
    output logic mem_write,
    output logic [3:0] mem_byte_enable,
    output rv32i_word mem_address,
    output rv32i_word mem_wdata
);
    
    
endmodule