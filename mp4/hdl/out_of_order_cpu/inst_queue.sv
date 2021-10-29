/* This is the instruction queue. */

import rv32i_types::*;

module instruction_queue (
    /* control signal */
    input logic shift,
    input logic flush,
    /* port to branch predictor */
    output ready,   /* Asserted when there is empty space in the queue. */
    /* port from branch predictor */
    input rv32i_word inst_in,
    input rv32i_word pc_in,
    input rv32i_word pc_next_in,
    input logic br_pred_in,
    /* port to decoder */
    output rv32i_word pc_out,
    output rv32i_word pc_next_out,
    output rv32i_word inst_out,
    output logic br_pred_out
);

endmodule