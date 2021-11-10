/* This is the instruction queue.                                   */
/* NOTE: we assume decoder will NOT shift inst_queue if it is empty */

import rv32i_types::*;
import ooo_types::*;

module instruction_queue #(
    parameter SIZE = 97 /* 32+32+1+32 */
)(
    input logic clk,
    input logic rst,
    /* control signal */
    input logic flush,
    /* port to branch predictor */
    output ready,   /* Asserted when there is empty space in the queue. */
    /* port from branch predictor */
    input logic valid_in,
    input rv32i_word inst_in,
    input rv32i_word pc_in,
    input rv32i_word pc_next_in,
    input logic br_pred_in,
    /* port from decoder */
    input logic shift,  /* read pace controlled by decoder */
    /* port to decoder */
    output logic valid_out,
    output rv32i_word pc_out,
    output rv32i_word pc_next_out,
    output rv32i_word inst_out,
    output logic br_pred_out
);
    
    logic [SIZE-1:0] regs [INST_QUEUE_DEPTH];  /* storage variable */

    /* intermediate variables */
    logic [2:0] head;   /* pointer to the queue head */
    logic [SIZE-1:0] data_in;

    /* wire */
    assign inst_out     = (head == 0) ? 'b0 : regs[head-1][0+:32];
    assign br_pred_out  = (head == 0) ? 1'b0 : regs[head-1][32+:1];
    assign pc_out       = (head == 0) ? 'b0 : regs[head-1][33+:32];
    assign pc_next_out  = (head == 0) ? 'b0 : regs[head-1][65+:32];
    assign data_in      = {pc_next_in, pc_in, br_pred_in, inst_in};

    /* combinational logic for control signals */
    assign ready = head < INST_QUEUE_DEPTH ? 1'b1 : 1'b0;
    // assign valid_out = (head != 0 && shift) ? 1'b1 : 1'b0;
    
    /* manage data */
    always_ff @( posedge clk ) begin
        if(rst | flush)begin
            /* reset everything */
            for (int i = 0; i < INST_QUEUE_DEPTH; ++i) begin
                regs[i] <= 'b0;
            end
            head <= 'b0;
            valid_out <= 1'b0;
        end else begin
            // valid_out <= 1'b0;
            if(shift & !valid_in)begin
                /* update head pointer */
                head <= head > 0 ? head - 1'b1 : 1'b0;  
                if(head > 1) valid_out <= 1'b1;
                else         valid_out <= 1'b0;

            end else if(shift & valid_in)begin
                /* shift all the entries forward */
                for (int i = 1; i < INST_QUEUE_DEPTH; ++i) begin
                    regs[i] <= regs[i-1];
                end
                /* bring new data in. Don't need to change head. */
                regs[0] <= data_in;
                valid_out <= 1'b1;

            end else if(!shift & !valid_in)begin
                /* do nothing */
                
            end else if(!shift & valid_in)begin
                /* check number of elements in the queue when popping */
                if(head < INST_QUEUE_DEPTH)begin
                    /* shift all the entries forward */
                    for (int i = 1; i < INST_QUEUE_DEPTH; ++i) begin
                        regs[i] <= regs[i-1];
                    end
                    /* bring new data in */
                    regs[0] <= data_in;
                    /* update head pointer */
                    head <= head + 1'b1;
                    valid_out <= 1'b1;
                end else begin
                    /* do nothing */
                end
                
            end
        end
    end

endmodule : instruction_queue