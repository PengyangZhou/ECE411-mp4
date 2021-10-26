/* This is the instruction queue. */

import rv32i_types::*;

module instruction_queue (
    input logic shift,
    input logic flush,
    input rv32i_word inst_in,
    
    output rv32i_word inst_out
);

endmodule