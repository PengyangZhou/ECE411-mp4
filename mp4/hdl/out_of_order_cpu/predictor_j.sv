import rv32i_types::*;

// return address stack
module predictor_j
(
    input logic clk,
    input logic rst,
    input logic new_inst,
    input rv32i_word pc,
    input rv32i_word inst,
    output rv32i_word pc_next
);

rv32i_opcode opcode;
rv32i_reg rd;
rv32i_reg rs1;
assign opcode = rv32i_opcode'(inst[6:0]);
assign rs1 = inst[19:15];
assign rd = inst[11:7];

logic push;
logic pop;
logic link_rd;
logic link_rs1;

assign link_rd = ((rd == 5'd1) || (rd == 5'd5)) ? 1'b1 : 1'b0;
assign link_rs1 = ((rs1 == 5'd1) || (rs1 == 5'd5)) ? 1'b1 : 1'b0;

always_comb
begin
    push = 1'b0;
    pop = 1'b0;
    if ((op_jal == opcode) && link_rd)
    begin
        push = 1'b1;
    end
    else if (op_jalr == opcode)
    begin
        if ((!link_rd) && link_rs1)
        begin
            pop = 1'b1;
        end
        else if (link_rd && (!link_rs1))
        begin
            push = 1'b1;
        end
        else if (link_rd && link_rs1)
        begin
            if (rd == rs1)
            begin
                push = 1'b1;
            end
            else
            begin
                push = 1'b1;
                pop = 1'b1;
            end
        end
    end
end

parameter STACK_LEN = 15;
parameter STACK_LEN_LOG2 = 4;
rv32i_word stack[STACK_LEN];
logic [STACK_LEN_LOG2-1:0] stack_pointer; // pointer to the first place to push, 0 means empty, 15 means full

always_ff @(posedge clk)
begin
    if (rst)
    begin
        stack_pointer <= 'd0;
        for (int i = 0; i < STACK_LEN; i++)
        begin
            stack[i] <= 32'b0;
        end
    end
    else
    begin
        if (new_inst && push && pop)
        begin
            if (stack_pointer != 0)
            begin
                stack[stack_pointer - 1] <= pc + 4;
            end
        end
        else if (new_inst && push)
        begin
            if (stack_pointer != STACK_LEN)
            begin
                stack[stack_pointer - 1] <= pc + 4;
                stack_pointer <= stack_pointer + 'd1;
            end
        end
        else if (new_inst && pop)
        begin
            if (stack_pointer != 0)
            begin
                stack_pointer <= stack_pointer - 'd1;
            end
        end
    end
end

always_comb
begin
    if (new_inst && pop)
    begin
        if (stack_pointer != 0)
        begin
            pc_next = stack[stack_pointer - 1];
        end
        else
        begin
            pc_next = pc + 4;
        end
    end
    else
    begin
        pc_next = pc + 4;
    end
end

endmodule
