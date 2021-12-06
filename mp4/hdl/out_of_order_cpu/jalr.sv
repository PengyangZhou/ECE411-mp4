import ooo_types::*;
import rv32i_types::*;

module jalr
(
    input logic clk,
    input logic rst,
    input logic flush,
    /* port from decoder */
    jalr_itf.jalr jalr_itf,
    /* port from ROB */
    input rob_out_t rob_data,
    /* port to cdb */
    output jalr_cdb_t jalr_res
);

    rv32i_word  Vj;
    rv32i_word  A;
    tag_t       Qj;
    tag_t       dest;
    rv32i_word  pc, pc_next;

    logic busy;

    logic misprediction_reported;

    assign jalr_itf.ready = (busy == 0) ? 1'b1 : 1'b0;

    /* input and update logic */
    always_ff @( posedge clk ) begin : input_update_logic
        if(rst | flush)begin
            Vj   <= 'b0;
            A   <= 'b0;
            Qj   <= 'b0;
            dest <= 'b0;
            pc <= 'b0;
            pc_next <= 'b0;
        end else begin
            if(jalr_itf.ready && jalr_itf.valid)begin
                /* bring in new entry */
                Vj <= jalr_itf.Vj;
                A <= jalr_itf.A;
                Qj <= jalr_itf.Qj;
                dest <= jalr_itf.dest;
                pc <= jalr_itf.pc;
                pc_next <= jalr_itf.pc_next;
            end else begin
                /* grab data from CDB */
                if(Qj != 0 && rob_data.ready[Qj])begin
                    Qj <= 'b0;
                    Vj <= rob_data.vals[Qj];
                end
            end
        end
    end

    rv32i_word correct_pc;
    assign correct_pc = Vj + A;

    /* output logic */
    always_ff @( posedge clk )
    begin
        if(rst | flush) begin
            jalr_res.valid  <= 1'b0;
            jalr_res.val   <= 'b0;
            jalr_res.tag   <= 'b0;
            jalr_res.correct_predict <= 'b0;
            jalr_res.pc_next <= 'b0;
            end
        else begin
            jalr_res.valid  <= 1'b0;
            if (busy && Qj == 0 && pc_next == correct_pc)
            begin
                jalr_res.valid  <= 1'b1;
                jalr_res.val   <= pc + 4;
                jalr_res.tag   <= dest;
                jalr_res.correct_predict <= 'b1;
                jalr_res.pc_next <= correct_pc;
            end
            else if (busy && Qj == 0 && pc_next != correct_pc && misprediction_reported == 0)
            begin
                jalr_res.valid  <= 1'b1;
                jalr_res.val   <= pc + 4;
                jalr_res.tag   <= dest;
                jalr_res.correct_predict <= 'b0;
                jalr_res.pc_next <= correct_pc;
            end
        end
    end

    /* busy bit logic */
    always_ff @(posedge clk)
    begin
        if(rst | flush)
        begin
            busy <= 1'b0;
        end
        else if(jalr_itf.ready && jalr_itf.valid)
        begin
            busy <= 1'b1;
        end
        else if(busy && Qj == 0 && pc_next == correct_pc)
        begin
            busy <= 1'b0;
        end
    end

    always_ff @(posedge clk)
    begin
        if(rst | flush)
        begin
            misprediction_reported <= 1'b0;
        end
        else if (busy && Qj == 0 && pc_next != correct_pc)
        begin
            misprediction_reported <= 1'b1;
        end
    end

endmodule
