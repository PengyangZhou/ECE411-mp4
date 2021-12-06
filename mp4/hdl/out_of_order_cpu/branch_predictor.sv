import rv32i_types::*;

module branch_predictor
(
    input logic clk,
    input logic rst, 
    // inst queue
    input logic iq_ready,
    output rv32i_word pc,
    output rv32i_word inst,
    output rv32i_word pc_next,
    output logic br_pred,
    output logic iq_valid,
    // flush
    input logic flush,
    input rv32i_word pc_correct,
    input logic br_predict,
    input logic br_correct,
    input rv32i_word br_pc_predict,
    input logic jalr_predict,
    input logic jalr_correct,
    // input logic jalr_mispredict, // Note: useless
    // input rv32i_word jalr_pc_mispredict, // Note: useless
    // i cache
    input logic mem_resp_i,
    input rv32i_word mem_rdata_i,
    output logic mem_read_i,
    output rv32i_word mem_address_i
);

logic flush_store;
rv32i_word pc_correct_store;

assign pc = mem_address_i;
assign inst = mem_rdata_i;

enum logic
{
    QUICK,
    SLOW
} state, next_state;

rv32i_opcode opcode;
rv32i_word j_imm;
rv32i_word b_imm;
assign opcode = rv32i_opcode'(mem_rdata_i[6:0]);
assign j_imm = {{12{mem_rdata_i[31]}}, mem_rdata_i[19:12], mem_rdata_i[20], mem_rdata_i[30:21], 1'b0};
assign b_imm = {{20{mem_rdata_i[31]}}, mem_rdata_i[7], mem_rdata_i[30:25], mem_rdata_i[11:8], 1'b0};

logic is_prediction;
assign is_prediction = (op_br == opcode) ? 1'b1 : 1'b0;

predictor_b predictor_b_inst (
    .clk(clk),
    .rst(rst),
    .is_prediction(is_prediction),
    .pc_fetch(pc),
    .br_pred(br_pred),
    .is_correction(br_predict),
    .pc_correct(br_pc_predict),
    .is_correct(br_correct)
);

rv32i_word jalr_pc_next;

predictor_j predictor_j_inst (
    .clk(clk),
    .rst(rst),
    .new_inst(iq_valid),
    .pc(pc),
    .inst(inst),
    .pc_next(jalr_pc_next)
);

always_ff @(posedge clk)
begin
    if (rst)
    begin
        state   <= QUICK;
        mem_address_i <= 32'h00000060;
        flush_store <= 0;
        pc_correct_store <= 32'h00000060;
    end
    else if (flush && (QUICK == state))
    begin
        state   <= QUICK;
        mem_address_i <= pc_correct;
        flush_store <= 0;
        pc_correct_store <= pc_correct;
    end
    else if (flush_store && (QUICK == state))
    begin
        state   <= QUICK;
        mem_address_i <= pc_correct_store;
        flush_store <= 0;
        pc_correct_store <= pc_correct_store;
    end
    else
    begin
        state <= next_state;
        if (mem_resp_i)
        begin
            mem_address_i <= pc_next;
        end
        else
        begin
            mem_address_i <= mem_address_i;
        end
        if (flush)
        begin
            flush_store <= 1;
            pc_correct_store <= pc_correct;
        end
        else
        begin
            flush_store <= flush_store;
            pc_correct_store <= pc_correct_store;
        end
    end
end

always_comb
begin
    if (op_jal == opcode)
    begin
        pc_next = pc + j_imm;
    end
    else if (op_br == opcode)
    begin
        if (br_pred)
        begin
            pc_next = pc + b_imm;
        end
        else
        begin
            pc_next = pc + 4;
        end
    end
    else if (op_jalr == opcode)
    begin
        pc_next = jalr_pc_next;
    end
    else
    begin
        pc_next = pc + 4;
    end
end

always_comb
begin
    next_state = state;
    mem_read_i = 0;
    iq_valid = 0;
    unique case (state)
    QUICK:
    begin
        if ((!flush) && (!flush_store) && iq_ready)
        begin
            mem_read_i = 1;
            if (mem_resp_i)
            begin
                next_state = QUICK;
                iq_valid = 1;
            end
            else
            begin
                next_state = SLOW;
            end
        end
    end
    SLOW:
    begin
        mem_read_i = 1;
        if (mem_resp_i)
        begin
            next_state = QUICK;
            if (flush || flush_store)
            begin
                iq_valid = 0;
            end
            else
            begin
                iq_valid = 1;
            end
        end
    end
    
    default: ;
    endcase
end

endmodule
