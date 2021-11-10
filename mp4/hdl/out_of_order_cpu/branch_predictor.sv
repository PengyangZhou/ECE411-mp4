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
    input logic br_mispredict,
    input logic jalr_mispredict,
    input rv32i_word pc_correct,
    input rv32i_word br_pc_mispredict,
    input rv32i_word jalr_pc_mispredict,
    // i cache
    input logic mem_resp_i,
    input rv32i_word mem_rdata_i,
    output logic mem_read_i,
    output logic mem_write_i,
    output logic [3:0] mem_byte_enable_i,
    output rv32i_word mem_address_i,
    output rv32i_word mem_wdata_i
);

assign mem_write_i = 0;
assign mem_byte_enable_i = 0;
assign mem_wdata_i = 0;

assign mem_address_i = pc;

enum logic [1:0]
{
    IDLE,
    BUSY,
    OUT
} state, next_state;

rv32i_opcode opcode;
rv32i_word j_imm;
assign opcode = rv32i_opcode'(mem_rdata_i[6:0]);
assign j_imm = {{12{mem_rdata_i[31]}}, mem_rdata_i[19:12], mem_rdata_i[20], mem_rdata_i[30:21], 1'b0};

always_ff @(posedge clk)
begin
    if (rst)
    begin
        state <= IDLE;
        pc <= 32'h00000060;
        inst <= 0;
        pc_next <= 0;
        br_pred <= 0;
    end
    else if (flush)
    begin
        pc <= pc_correct;
        inst <= 0;
        pc_next <= 0;
        br_pred <= 0;
    end
    else
    begin
        state <= next_state;
        unique case (state)
        IDLE:
        begin
            pc <= pc;
            inst <= inst;
            pc_next <= pc_next;
            br_pred <= br_pred;
        end
        BUSY:
        begin
            if (mem_resp_i)
            begin
                pc <= pc;
                inst <= mem_rdata_i;
                if (op_jal == opcode)
                begin
                    pc_next <= pc + j_imm;
                    br_pred <= 0;
                end
                else if (op_br == opcode) // TODO: Predictor
                begin
                    pc_next <= pc + 4;
                    br_pred <= 0;
                end
                else if (op_jalr == opcode) // TODO: Predictor
                begin
                    pc_next <= pc + 4;
                    br_pred <= 0;
                end
                else
                begin
                    pc_next <= pc + 4;
                    br_pred <= 0;
                end
            end
            else
            begin
                pc <= pc;
                inst <= inst;
                pc_next <= pc_next;
                br_pred <= br_pred;
            end
        end
        OUT:
        begin
            pc <= pc_next;
            inst <= inst;
            pc_next <= pc_next;
            br_pred <= br_pred;
        end
        endcase
    end
end

always_comb
begin
    next_state = state;
    mem_read_i = 0;
    iq_valid = 0;
    unique case (state)
    IDLE:
    begin
        if (iq_ready)
        begin
            next_state = BUSY;
        end
    end
    BUSY:
    begin
        mem_read_i = 1;
        if (mem_resp_i)
        begin
            next_state = OUT;
        end
    end
    OUT:
    begin
        next_state = IDLE;
        iq_valid = 1;
    end
    endcase
end

endmodule
