/* This is the Load/Store Buffer */
import ooo_types::*;
import rv32i_types::*;

module lsb_rs (
    input logic         clk,
    input logic         rst,
    input logic         flush,
    /* port from decoder */
    lsb_rs_itf.lsb_rs   lsb_itf,
    /* port from ROB */
    input logic         new_store,
    input rob_out_t     rob_data,
    /* port to CDB */
    output mem_cdb_t    mem_res,  /* maybe change to lsb_res someday? */
    // d cache
    output logic mem_read_d,
    // output logic mem_write_d,
    // output logic [3:0] mem_byte_enable_d,
    output rv32i_word mem_address_d,
    // output rv32i_word mem_wdata_d,
    input logic mem_resp_d,
    input rv32i_word mem_rdata_d
);
        rv32i_word mem_address_d_inside;
    assign mem_address_d = {mem_address_d_inside[31:2], 2'b00};
    
    /* RS entry fields */
    /* NUM_LDST_RS is 7 */
    logic       busy    [NUM_LDST_RS];
    rv32i_word  Vj      [NUM_LDST_RS];
    rv32i_word  Vk      [NUM_LDST_RS];
    rv32i_word  A       [NUM_LDST_RS];
    tag_t       Qj      [NUM_LDST_RS];
    tag_t       Qk      [NUM_LDST_RS];
    logic [2:0] lsb_op  [NUM_LDST_RS]; // 1 for store, 0 for load
    logic [2:0] funct   [NUM_LDST_RS];
    tag_t       dest    [NUM_LDST_RS];
    logic [MAX_STORE_INDEX-1:0] store_before [NUM_LDST_RS];

    /* intermediate variables */
    genvar i;
    logic [NUM_LDST_RS_LOG2-1:0] empty_index;
    logic [MAX_STORE_INDEX-1:0] store_number;

    /* Your logic here */
    /* find the first empty entry */
    always_comb
    begin
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
        end else if(busy[5] == 0)begin
            empty_index = 5;
        end else if(busy[6] == 0)begin
            empty_index = 6;
        end else begin
            empty_index = 7; /* if empty_index is 7, there is no empty space in the RS */
        end
        lsb_itf.ready = empty_index < NUM_LDST_RS ? 1'b1 : 1'b0;
    end

    task push_entry(logic [NUM_LDST_RS_LOG2-1:0] index);
        Vj[index]   <= lsb_itf.Vj;
        Vk[index]   <= lsb_itf.Vk;
        A[index]    <= lsb_itf.A;
        Qj[index]   <= lsb_itf.Qj;
        Qk[index]   <= lsb_itf.Qk;
        lsb_op[index]   <= lsb_itf.lsb_op;
        funct[index] <= lsb_itf.funct;
        dest[index] <= lsb_itf.dest;
        store_before[index] <= store_number;
    endtask

    always_ff @(posedge clk)
    begin
        if (rst | flush)
        begin
            store_number <= 0;
        end
        // else if (new_valid && lsb_itf.lsb_op && new_store)
        else if (lsb_itf.valid && lsb_itf.lsb_op && new_store)
        begin
            store_number <= store_number;
        end
        // else if (new_valid && lsb_itf.lsb_op)
        else if (lsb_itf.valid && lsb_itf.lsb_op)
        begin
            store_number <= store_number + 1'b1;
        end
        else if (new_store)
        begin
            store_number <= store_number - 1'b1;
        end
        else
        begin
            store_number <= store_number;
        end
    end

    /* input and update logic */
    always_ff @( posedge clk )
    begin
        if(rst | flush)begin
            for (int i = 0; i < NUM_LDST_RS; ++i) begin
                Vj[i]   <= 'b0;
                Vk[i]   <= 'b0;
                A[i]    <= 'b0;
                Qj[i]   <= 'b0;
                Qk[i]   <= 'b0;
                lsb_op[i] <= 'b0;
                funct[i] <= 'b0;
                dest[i] <= 'b0;
                store_before[i] <= 'b0;
            end
        end else begin
            for (int i = 0; i < NUM_LDST_RS; ++i) begin
                if(lsb_itf.valid && empty_index == i)begin
                    /* bring in new entry */
                    push_entry(i);
                    if (new_store && 0 == lsb_itf.lsb_op)
                    begin
                        store_before[i] <= store_number - 1'b1;
                    end
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
                    if (new_store && busy[i] == 1 && lsb_op[i] == 0 && store_before[i] != 0)begin
                        store_before[i] <= store_before[i] - 1'b1;
                    end
                end
            end
        end
    end

    logic [NUM_LDST_RS_LOG2-1:0] current_load;
    logic [NUM_LDST_RS_LOG2-1:0] current_load_ff;
    always_comb
    begin
        if(busy[0] == 1 && lsb_op[0] == 0 && Qj[0] == 0 && store_before[0] == 0)begin
            current_load = 0;
        end else if(busy[1] == 1 && lsb_op[1] == 0 && Qj[1] == 0 && store_before[1] == 0)begin
            current_load = 1;
        end else if(busy[2] == 1 && lsb_op[2] == 0 && Qj[2] == 0 && store_before[2] == 0)begin
            current_load = 2;
        end else if(busy[3] == 1 && lsb_op[3] == 0 && Qj[3] == 0 && store_before[3] == 0)begin
            current_load = 3;
        end else if(busy[4] == 1 && lsb_op[4] == 0 && Qj[4] == 0 && store_before[4] == 0)begin
            current_load = 4;
        end else if(busy[5] == 1 && lsb_op[5] == 0 && Qj[5] == 0 && store_before[5] == 0)begin
            current_load = 5;
        end else if(busy[6] == 1 && lsb_op[6] == 0 && Qj[6] == 0 && store_before[6] == 0)begin
            current_load = 6;
        end else begin
            current_load = 7; /* if current_load is 7, there is no valid load instruction */
        end
    end

    /* output logic */
    always_ff @( posedge clk )
    begin
        if(rst | flush)begin
            for (int i = 0; i < NUM_LDST_RS; ++i) begin
                mem_res.valid[i]  <= 1'b0;
                mem_res.val[i]   <= 'b0;
                mem_res.tag[i]   <= 'b0;
                mem_res.addr[i] <= 'b0;
            end
        end else begin
            for (int i = 0; i < NUM_LDST_RS; ++i) begin
                /* set default */
                mem_res.valid[i] <= 1'b0;
                /* output the calculated result */
                if (lsb_op[i] == 1)
                begin
                    if(busy[i] && Qj[i] == 0 && Qk[i] == 0)begin
                        mem_res.valid[i] <= 1'b1;
                        mem_res.val[i]  <= Vk[i];
                        mem_res.tag[i]  <= dest[i];
                        mem_res.addr[i] <= Vj[i] + A[i];
                    end
                end
                else
                begin
                    if(busy[i] && Qj[i] == 0 && Qk[i] == 0 && current_load_ff == i && mem_resp_d)begin
                        mem_res.valid[i] <= 1'b1;
                        mem_res.tag[i]  <= dest[i];
                        case (funct[i])
                        lw:        mem_res.val[i]  <= mem_rdata_d;
                        lb:
                        begin
                            case (mem_address_d_inside[1:0])
                                2'b00: mem_res.val[i] <= {{24{mem_rdata_d[7]}}, mem_rdata_d[7:0]};
                                2'b01: mem_res.val[i] <= {{24{mem_rdata_d[15]}}, mem_rdata_d[15:8]};
                                2'b10: mem_res.val[i] <= {{24{mem_rdata_d[23]}}, mem_rdata_d[23:16]};
                                2'b11: mem_res.val[i] <= {{24{mem_rdata_d[31]}}, mem_rdata_d[31:24]};
                            endcase
                        end
                        lbu:
                        begin
                            case (mem_address_d_inside[1:0])
                                2'b00: mem_res.val[i] <= {24'b0, mem_rdata_d[7:0]};
                                2'b01: mem_res.val[i] <= {24'b0, mem_rdata_d[15:8]};
                                2'b10: mem_res.val[i] <= {24'b0, mem_rdata_d[23:16]};
                                2'b11: mem_res.val[i] <= {24'b0, mem_rdata_d[31:24]};
                            endcase
                        end
                        lh:
                        begin
                            case (mem_address_d_inside[1])
                                1'b0: mem_res.val[i] <= {{16{mem_rdata_d[15]}}, mem_rdata_d[15:0]};
                                1'b1: mem_res.val[i] <= {{16{mem_rdata_d[31]}}, mem_rdata_d[31:16]};
                            endcase
                        end
                        lhu:
                        begin
                            case (mem_address_d_inside[1])
                                1'b0: mem_res.val[i] <= {16'b0, mem_rdata_d[15:0]};
                                1'b1: mem_res.val[i] <= {16'b0, mem_rdata_d[31:16]};
                            endcase
                        end            
                        endcase
                    end
                end
            end
        end
    end

    /* busy bit logic */
    always_ff @( posedge clk)
    begin
        if(rst | flush)begin
            for (int i = 0; i < NUM_LDST_RS; ++i) begin
                busy[i] <= 1'b0;
            end
        end else begin
            for (int i = 0; i < NUM_LDST_RS; ++i) begin
                if(lsb_op[i] == 1 && busy[i] && Qj[i] == 0 && Qk[i] == 0)begin
                    busy[i] <= 1'b0;
                end else if(lsb_op[i] == 0 && busy[i] && Qj[i] == 0 && Qk[i] == 0 && current_load_ff == i && mem_resp_d)begin
                    busy[i] <= 1'b0;                    
                end else if(~busy[i] && lsb_itf.valid && empty_index == i)begin
                    busy[i] <= 1'b1;
                end else begin
                    /* do nothing. But to make code more readable I wrote this */
                    busy[i] <= busy[i];
                end
            end
        end
    end

    enum logic
    {
        IDLE,
        BUSY
    } state;

    logic flush_store;

    always_ff @(posedge clk)
    begin
        if (rst)
        begin
            state <= IDLE;
            mem_address_d_inside <= 0;
            flush_store <= 0;
            current_load_ff <= 0;
        end
        else if ((flush | flush_store) && (IDLE == state))
        begin
            state <= IDLE;
            mem_address_d_inside <= 0;
            flush_store <= 0;
            current_load_ff <= 0;
        end
        else
        begin
            if (flush)
            begin
                flush_store <= 1;
            end
            else
            begin
                flush_store <= flush_store;
            end
            unique case (state)
            IDLE:
            begin
                if (NUM_LDST_RS != current_load)
                begin
                    state <= BUSY;
                    mem_address_d_inside <= Vj[current_load] + A[current_load];
                    current_load_ff <= current_load;
                end
                else
                begin
                    state <= state;
                    mem_address_d_inside <= 0;
                    current_load_ff <= current_load_ff;
                end
            end
            BUSY:
            begin
                mem_address_d_inside <= mem_address_d_inside;
                if (mem_resp_d)
                begin
                    state <= IDLE;
                end
                else
                begin
                    state <= state;
                end
                current_load_ff <= current_load_ff;
            end
            endcase
        end
    end

    always_comb
    begin
        mem_read_d = 0;
        if (BUSY == state)
        begin
            mem_read_d = 1;
        end
    end

endmodule
