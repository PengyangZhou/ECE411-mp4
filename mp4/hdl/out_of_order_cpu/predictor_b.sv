import rv32i_types::*;

module predictor_b
(
    input logic clk,
    input logic rst,
    // prediction
    input logic is_prediction,
    input rv32i_word pc_fetch,
    output logic br_pred,
    // correction
    input logic is_correction,
    input rv32i_word pc_correct,
    input logic is_correct
);
    parameter PRE_B_LEN = 8;
    parameter PRE_B_LEN_LOG2 = 3;

    logic used[PRE_B_LEN];
    logic [29:0] tag[PRE_B_LEN];
    enum logic [1:0]
    {
        ST,
        WT,
        WN,
        SN
    } br[PRE_B_LEN];

    logic [PRE_B_LEN_LOG2-1:0] next_new; // pointer to next line to store

    logic pc_fetch_exist;
    logic [PRE_B_LEN_LOG2-1:0] pc_fetch_match;
    logic pc_correct_exist;
    logic [PRE_B_LEN_LOG2-1:0] pc_correct_match;
    always_comb
    begin
        pc_fetch_exist = 0;
        pc_fetch_match = 3'd0;
        for (int i = 0; i < PRE_B_LEN; i++)
        begin
            if (used[i] && (pc_fetch[31:2] == tag[i]))
            begin
                pc_fetch_exist = 1;
                pc_fetch_match = i[PRE_B_LEN_LOG2-1:0];
            end
        end
        // if (used[0] && (pc_fetch[31:2] == tag[0]))
        // begin
        //     pc_fetch_exist = 1;
        //     pc_fetch_match = 3'd0;
        // end
        // else if (used[1] && (pc_fetch[31:2] == tag[1]))
        // begin
        //     pc_fetch_exist = 1;
        //     pc_fetch_match = 3'd1;
        // end
        // else if (used[2] && (pc_fetch[31:2] == tag[2]))
        // begin
        //     pc_fetch_exist = 1;
        //     pc_fetch_match = 3'd2;
        // end
        // else if (used[3] && (pc_fetch[31:2] == tag[3]))
        // begin
        //     pc_fetch_exist = 1;
        //     pc_fetch_match = 3'd3;
        // end
        // else if (used[4] && (pc_fetch[31:2] == tag[4]))
        // begin
        //     pc_fetch_exist = 1;
        //     pc_fetch_match = 3'd4;
        // end
        // else if (used[5] && (pc_fetch[31:2] == tag[5]))
        // begin
        //     pc_fetch_exist = 1;
        //     pc_fetch_match = 3'd5;
        // end
        // else if (used[6] && (pc_fetch[31:2] == tag[6]))
        // begin
        //     pc_fetch_exist = 1;
        //     pc_fetch_match = 3'd6;
        // end
        // else if (used[7] && (pc_fetch[31:2] == tag[7]))
        // begin
        //     pc_fetch_exist = 1;
        //     pc_fetch_match = 3'd7;
        // else
        // begin
        //     pc_fetch_exist = 0;
        //     pc_fetch_match = 3'd0;
        // end
    end
    always_comb
    begin
        pc_correct_exist = 0;
        pc_correct_match = 3'd0;
        for (int i = 0; i < PRE_B_LEN; i++)
        begin
            if (used[i] && (pc_correct[31:2] == tag[i]))
            begin
                pc_correct_exist = 1;
                pc_correct_match = i[PRE_B_LEN_LOG2-1:0];
            end
        end
        // if (used[0] && (pc_correct[31:2] == tag[0]))
        // begin
        //     pc_correct_exist = 1;
        //     pc_correct_match = 3'd0;
        // end
        // else if (used[1] && (pc_correct[31:2] == tag[1]))
        // begin
        //     pc_correct_exist = 1;
        //     pc_correct_match = 3'd1;
        // end
        // else if (used[2] && (pc_correct[31:2] == tag[2]))
        // begin
        //     pc_correct_exist = 1;
        //     pc_correct_match = 3'd2;
        // end
        // else if (used[3] && (pc_correct[31:2] == tag[3]))
        // begin
        //     pc_correct_exist = 1;
        //     pc_correct_match = 3'd3;
        // end
        // else if (used[4] && (pc_correct[31:2] == tag[4]))
        // begin
        //     pc_correct_exist = 1;
        //     pc_correct_match = 3'd4;
        // end
        // else if (used[5] && (pc_correct[31:2] == tag[5]))
        // begin
        //     pc_correct_exist = 1;
        //     pc_correct_match = 3'd5;
        // end
        // else if (used[6] && (pc_correct[31:2] == tag[6]))
        // begin
        //     pc_correct_exist = 1;
        //     pc_correct_match = 3'd6;
        // end
        // else if (used[7] && (pc_correct[31:2] == tag[7]))
        // begin
        //     pc_correct_exist = 1;
        //     pc_correct_match = 3'd7;
        // else
        // begin
        //     pc_correct_exist = 0;
        //     pc_correct_match = 3'd0;
        // end
    end

    always_ff @(posedge clk)
    begin
        if (rst)
        begin
            for (int i = 0; i < PRE_B_LEN; i++)
            begin
                used[i] <= 1'b0;
                tag[i] <= 30'b0;
                br[i] <= WN;
            end
            next_new <= 3'd0;
        end
        else
        begin
            if (is_correction && pc_correct_exist && (!(is_prediction && (!pc_fetch_exist) && (pc_correct_match == next_new))))
            begin
                unique case (br[pc_correct_match])
                ST:
                begin
                    if (is_correct)
                    begin
                        br[pc_correct_match] <= ST;
                    end
                    else
                    begin
                        br[pc_correct_match] <= WT;
                    end
                end
                WT:
                begin
                    if (is_correct)
                    begin
                        br[pc_correct_match] <= ST;
                    end
                    else
                    begin
                        br[pc_correct_match] <= WN;
                    end
                end
                WN:
                begin
                    if (is_correct)
                    begin
                        br[pc_correct_match] <= SN;
                    end
                    else
                    begin
                        br[pc_correct_match] <= WT;
                    end
                end
                SN:
                begin
                    if (is_correct)
                    begin
                        br[pc_correct_match] <= SN;
                    end
                    else
                    begin
                        br[pc_correct_match] <= WN;
                    end
                end
                endcase
            end
            else if (is_prediction && (!pc_fetch_exist))
            begin
                used[next_new] <= 1'b1;
                tag[next_new] <= pc_fetch[31:2];
                br[next_new] <= WN;
                next_new <= next_new + 1'b1;
            end
        end
    end

    always_comb
    begin
        if (pc_fetch_exist)
        begin
            case (br[pc_fetch_match])
            ST:
            begin
                br_pred = 1;
            end
            WT:
            begin
                br_pred = 1;
            end
            WN:
            begin
                br_pred = 0;
            end
            SN:
            begin
                br_pred = 0;
            end
            endcase
        end
        else
        begin
            br_pred = 0;
        end
    end
endmodule
