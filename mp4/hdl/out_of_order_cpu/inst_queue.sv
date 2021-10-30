/* This is the instruction queue. */

import rv32i_types::*;

module instruction_queue #(
    parameter SIZE = 97; /* 32+32+1+32 */
    parameter NUM_ENTRY = 6;
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
    
    logic [SIZE-1:0] regs [NUM_ENTRY];  /* storage variable */

    /* intermediate variables */
    logic [2:0] head;   /* pointer to the queue head */
    logic [SIZE-1:0] data_in;

    /* wire */
    assign inst_out     = regs[head][0+:32];
    assign br_pred_out  = regs[head][32+:1];
    assign pc_out       = regs[head][33+:32];
    assign pc_next_out  = regs[head][65+:32];
    assign data_in      = {pc_next_in, pc_in, br_pred_in, inst_in};

    /* combinational logic for control signals */
    assign ready = head < NUM_ENTRY ? 1'b1 : 1'b0;
    assign valid_out = (head != 0 && shift) ? 1'b1 : 1'b0;
    
    /* manage data */
    always_ff @( posedge clk ) begin
        if(rst | flush)begin
            /* reset everything */
            for (int i = 0; i < NUM_ENTRY; ++i) begin
                regs[i] <= 'b0;
            end
            head <= 'b0;
        end else begin
            if(shift & !valid_in)begin
                /* update head pointer */
                head <= head > 0 ? head - 1 : 0;  

            end else if(shift & valid_in)begin
                /* shift all the entries forward */
                for (int i = 1; i < NUM_ENTRY; ++i) begin
                    regs[i] <= regs[i-1];
                end
                /* bring new data in */
                regs[0] <= data_in;

            end else if(!shift & !valid_in)begin
                /* do nothing */
                
            end else if(!shift & valid_in)begin
                /* check number of elements in the queue when popping */
                if(head < NUM_ENTRY)begin
                    /* shift all the entries forward */
                    for (int i = 1; i < NUM_ENTRY; ++i) begin
                        regs[i] <= regs[i-1];
                    end
                    /* bring new data in */
                    regs[0] <= data_in;
                    /* update head pointer */
                    head <= head + 1;
                end else begin
                    /* do nothing */
                end
                
            end
        end
    end

endmodule : instruction_queue