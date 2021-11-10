/* This is the ALU reservation station. */
import ooo_types::*;
import rv32i_types::*;

module alu_rs (
    input logic         clk,
    input logic         rst,
    input logic         flush,  /* basically the same as rst */ 
    /* port from decoder */
    alu_rs_itf.alu_rs   alu_itf,
    // /* port from CDB */
    // input cmp_cdb       cmp_res_in,
    // input lsb_cdb       lsb_res_in,
    /* port from ROB */
    input rob_out_t     rob_data,
    /* port to cdb */
    output alu_cdb_t    alu_res
);

    /* RS entry fields */
    logic       busy    [NUM_ALU_RS];
    alu_ops     op_type [NUM_ALU_RS];
    rv32i_word  Vj      [NUM_ALU_RS];
    rv32i_word  Vk      [NUM_ALU_RS];
    tag_t       Qj      [NUM_ALU_RS];
    tag_t       Qk      [NUM_ALU_RS];
    tag_t       dest    [NUM_ALU_RS];

    /* intermediate variable */
    genvar i;
    rv32i_word  res [NUM_ALU_RS];
    logic [2:0] empty_index;

    /* instantiation of ALUs */
    generate 
        for (i = 0; i < NUM_ALU_RS; ++i) begin : alu_inst
            alu alu_inst(
                .aluop(op_type[i]),
                .a(Vj[i]),
                .b(Vk[i]),
                .f(res[i])
            );
        end
    endgenerate

    /* find the first empty entry */
    always_comb begin : find_empty
        if(busy[0] == 0)begin
            empty_index = 0;
        end else if(busy[1] == 0)begin
            empty_index = 1;
        end else if(busy[2] == 0)begin
            empty_index = 2;
        end else if(busy[3] == 0)begin
            empty_index = 3;
        end else if(busy[4] == 0)begin
            empty_index = 4;
        end else begin
            empty_index = 5; /* if empty_index is 5, there is no empty space in the RS */
        end
        /* output of ready signal */
        alu_itf.ready = empty_index < NUM_ALU_RS ? 1'b1 : 1'b0;
    end

    /* task definition */
    task push_entry(logic [2:0] index);
        // busy[index] <= 1'b1;
        op_type[index] <= alu_itf.alu_op;
        Vj[index]   <= alu_itf.Vj;
        Vk[index]   <= alu_itf.Vk;
        Qj[index]   <= alu_itf.Qj;
        Qk[index]   <= alu_itf.Qk;
        dest[index] <= alu_itf.dest;
    endtask

    /* input and update logic */
    always_ff @( posedge clk ) begin : input_update_logic
        if(rst | flush)begin
            for (int i = 0; i < NUM_ALU_RS; ++i) begin
                op_type[i] <= alu_add;
                Vj[i]   <= 'b0;
                Vk[i]   <= 'b0;
                Qj[i]   <= 'b0;
                Qk[i]   <= 'b0;
                dest[i] <= 'b0;
            end
        end else begin
            for (int i = 0; i < NUM_ALU_RS; ++i) begin
                if(alu_itf.valid && empty_index == i)begin
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
    end : input_update_logic

    /* output logic */
    always_ff @( posedge clk ) begin : output_result
        if(rst | flush)begin
            for (int i = 0; i < NUM_ALU_RS; ++i) begin
                alu_res.valid[i]  <= 1'b0;
                alu_res.vals[i]   <= 'b0;
                alu_res.tags[i]   <= 'b0;
            end
        end else begin
            for (int i = 0; i < NUM_ALU_RS; ++i) begin
                /* set default */
                alu_res.valid[i] <= 1'b0;
                /* output the calculated result */
                if(busy[i] && Qj[i] == 0 && Qk[i] == 0)begin
                    alu_res.valid[i] <= 1'b1;
                    alu_res.vals[i]  <= res[i];
                    alu_res.tags[i]  <= dest[i];
                end
            end
        end
    end

    /* busy bit logic */
    always_ff @( posedge clk ) begin : busy_update
        if(rst | flush)begin
            for (int i = 0; i < NUM_ALU_RS; ++i) begin
                busy[i] <= 1'b0;
            end
        end else begin
            for (int i = 0; i < NUM_ALU_RS; ++i) begin
                if(busy[i] && Qj[i] == 0 && Qk[i] == 0)begin
                    busy[i] <= 1'b0;
                end else if(~busy[i] && alu_itf.valid && empty_index == i)begin
                    busy[i] <= 1'b1;
                end else begin
                    /* do nothing. But to make code more readable I wrote this */
                    busy[i] <= busy[i];
                end
            end
        end
    end
    
endmodule
