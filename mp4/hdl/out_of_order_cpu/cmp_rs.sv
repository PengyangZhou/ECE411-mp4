/* This is the Comparator Reservation Station */

module cmp_rs (
    input logic         clk,
    input logic         rst,
    input logic         flush,
    /* port from decoder */
    cmp_rs_itf.cmp_rs   cmp_itf,
    /* port from ROB */
    input rob_out_t     rob_data,
    /* port to CDB */
    output cmp_cdb_t    cmp_res
);

    /* RS entry fields */
    /* NUM_CMP_RS is 3 */
    logic       busy    [NUM_CMP_RS];
    logic       is_br   [NUM_CMP_RS];
    branch_funct3_t op_type[NUM_CMP_RS];
    rv32i_word  Vj      [NUM_CMP_RS];
    rv32i_word  Vk      [NUM_CMP_RS];
    tag_t       Qj      [NUM_CMP_RS];
    tag_t       Qk      [NUM_CMP_RS];
    tag_t       dest    [NUM_CMP_RS];
    logic       br_pred [NUM_CMP_RS];
    rv32i_word  pc      [NUM_CMP_RS];
    rv32i_word  B_imm [NUM_CMP_RS];

    /* intermediate variables */
    genvar i;
    logic res [NUM_CMP_RS];
    logic [1:0] empty_index;

    /* Your logic here */
    generate 
        for (i = 0; i < NUM_CMP_RS; ++i) begin : cmp_inst
            cmp cmp_inst(
                .rs1_in(Vj[i]),
                .mux_in(Vk[i]),
                .cmpop(op_type[i]),
                .br_en(res[i])
            );
        end
    endgenerate

    always_comb
    begin
        if(busy[0] == 0)begin
            empty_index = 0;
        end else if(busy[1] == 0)begin
            empty_index = 1;
        end else if(busy[2] == 0)begin
            empty_index = 2;
        end else begin
            empty_index = 3; /* if empty_index is 3, there is no empty space in the RS */
        end
    end

    /* busy bit logic */
    always_ff @( posedge clk)
    begin
        if(rst | flush)begin
            for (int i = 0; i < NUM_CMP_RS; ++i) begin
                busy[i] <= 1'b0;
            end
        end else begin
            for (int i = 0; i < NUM_CMP_RS; ++i) begin
                if(busy[i] && Qj[i] == 0 && Qk[i] == 0)begin
                    busy[i] <= 1'b0;
                end else if(~busy[i] && cmp_itf.valid && empty_index == i)begin
                    busy[i] <= 1'b1;
                end else begin
                    /* do nothing. But to make code more readable I wrote this */
                    busy[i] <= busy[i];
                end
            end
        end
    end

    task push_entry(logic [1:0] index);
        is_br[index] <= cmp_itf.is_br;
        op_type[index] <= cmp_itf.cmp_op;
        Vj[index]   <= cmp_itf.Vj;
        Vk[index]   <= cmp_itf.Vk;
        Qj[index]   <= cmp_itf.Qj;
        Qk[index]   <= cmp_itf.Qk;
        dest[index] <= cmp_itf.dest;
        br_pred[index] <= cmp_itf.br_pred;
        pc[index] <= cmp_itf.pc;
        B_imm[index] <= cmp_itf.B_imm;
    endtask

    /* input and update logic */
    always_ff @( posedge clk )
    begin
        if(rst | flush)begin
            for (int i = 0; i < NUM_CMP_RS; ++i) begin
                op_type[i] <= beq;
                Vj[i]   <= 'b0;
                Vk[i]   <= 'b0;
                Qj[i]   <= 'b0;
                Qk[i]   <= 'b0;
                dest[i] <= 'b0;
                br_pred[i] <= 'b0;
                pc[i] <= 'b0;
                B_imm[i] <= 'b0;
            end
        end else begin
            for (int i = 0; i < NUM_CMP_RS; ++i) begin
                if(cmp_itf.valid && empty_index == i)begin
                    /* bring in new entry */
                    push_entry(i);
                end else begin
                    /* grab data from CDB */
                    if(Qj[i] != 0 && rob_data.ready[Qj[i]])begin
                        Qj[i] <= 'b0;
                        Vj[i] <= rob_data.vals[Qj[i]];
                    end
                    if(Qk[i] != 0 && rob_data.ready[Qk[i]])begin
                        Qk[i] <= 'b0;
                        Vk[i] <= rob_data.vals[Qk[i]];
                    end
                end
            end
        end
    end

    /* output logic */
    always_ff @( posedge clk)
    begin
        if(rst | flush)begin
            for (int i = 0; i < NUM_CMP_RS; ++i) begin
                cmp_res.valid[i]  <= 1'b0;
                cmp_res.val[i]   <= 'b0;
                cmp_res.tag[i]   <= 'b0;
                cmp_res.br_pred_res[i]  <= 1'b0;
                cmp_res.pc_next[i] <= 'b0;
            end
        end else begin
            for (int i = 0; i < NUM_CMP_RS; ++i) begin
                /* set default */
                cmp_res.valid[i] <= 1'b0;
                /* output the calculated result */
                if(busy[i] && Qj[i] == 0 && Qk[i] == 0)begin
                    cmp_res.valid[i] <= 1'b1;
                    if (!is_br[i])
                    begin
                        cmp_res.val[i] <= {32{res[i]}};
                    end
                    else
                        cmp_res.val[i] <= pc[i];
                    begin
                    end
                    cmp_res.tag[i] <= dest[i];
                    cmp_res.br_pred_res[i] <= (br_pred[i] == res[i] ? 0 : 1);
                    if (res[i])
                    begin
                        cmp_res.pc_next[i] <= pc[i] + B_imm[i];
                    end
                    else
                    begin
                        cmp_res.pc_next[i] <= pc[i] + 4;
                    end
                end
            end
        end
    end
    
endmodule