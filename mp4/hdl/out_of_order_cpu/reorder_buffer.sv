module reorder_buffer 
(
    input logic clk,
    input logic rst,
    // port from decoder
    input logic valid_in,
    input logic [1:0] op_type,
    input logic [31:0] dest,
    // port from CDB
    input alu_cdb_t alu_res,
    input cmp_cdb_t cmp_res,
    input mem_cdb_t mem_res,  // from load/store buffer
    input jalr_cdb_t jalr_res,
    // input from data cache
    input logic mem_resp,
    // port to decoder
    output rob_out_t rob_out,
    // port to regfile
    output logic load_val,
    output rv32i_reg val_rd,
    output tag_t tag,
    output rv32i_word val,
    // port to data cache
    output logic mem_write,
    output rv32i_word mem_wdata,
    output rv32i_word mem_address,
    output logic [3:0] mem_byte_enable // TODO
    // port to load/store buffer
    output logic new_store,
    // port to branch predictor
    // TODO
    output logic br_mispredict,
    output logic jalr_mispredict,
    output rv32i_word pc_correct,
    output rv32i_word br_pc_mispredict,
    output rv32i_word jalr_pc_mispredict,
    output logic flush
);

    // entry of reorder buffer
    // the entry of index 0 will be remained empty by intention
    bit rob_busy [ROB_DEPTH + 1];          // high if the entry's value is not available
    logic [1:0] rob_type [ROB_DEPTH + 1];  // instruction type. register operation, store, or branch
    rv32i_word rob_dest [ROB_DEPTH + 1];   // for register operation, contains the index(only use bits [4:0]) 
                                       // for store or branch, contains the address
    rv32i_word rob_vals [ROB_DEPTH + 1];   // contains the value of register or the value to store
    bit rob_ready [ROB_DEPTH + 1];         // high if the entry is ready to commit

    tag_t input_head;   // pointing to the empty entry waiting for input
    tag_t next_input_head; 
    tag_t commit_head;  // pointing to the entry needs committing

    logic commit_ready; 
    assign commit_ready = rob_ready[commit_head];

    // increment the head pointer
    task inc_head(tag_t head);
        if (head == ROB_DEPTH) begin
            head <= 4'd1;
        end else begin
            head <= head + 1'b1;
        end
    endtask

    always_ff @( posedge clk ) begin
        if (rst | flush) begin
            // empty the whole reorder buffer
            for (int i = 0; i < ROB_DEPTH + 1; i++) begin
                rob_busy[i] <= '0;
                rob_type[i] <= '0;
                rob_dest[i] <= '0;
                rob_vals[i] <= '0;
                rob_ready[i] <= '0;
            end
            // reset head pointer
            input_head <= 4'd1;
            next_input_head <= 4'd2;
            commit_head <= 4'd1;
        end else begin 
            if (valid_in) begin
                // new instruction from decoder
                rob_busy[input_head] <= 1'b1;
                rob_type[input_head] <= op_type;
                rob_dest[input_head] <= dest;
                inc_head(input_head);
                inc_head(next_input_head);
            end
            if (commit_ready) begin
                // clear the current ROB entry
                rob_busy[commit_head] <= '0;
                rob_type[commit_head] <= '0;
                rob_dest[commit_head] <= '0;
                rob_vals[commit_head] <= '0;
                rob_ready[commit_head] <= '0;
                if (rob_type[commit_head] == ST) begin
                    if (next_state == STORE_IDLE) begin
                        inc_head(commit_head);
                    end
                end else begin
                    // if the operation is not store, always go to the next entry.
                    inc_head(commit_head);
                end
            end
            for (int i = 0; i < NUM_ALU_RS; i++) begin
                if (alu_res.valid[i]) begin
                    // if the result out of alu is valid
                    rob_vals[alu_res.tags[i]] <= alu_res.vals[i];
                    rob_ready[alu_res.tags[i]] <= 1'b1;
                end
            end
            for (int i = 0; i < NUM_LDST_RS; i++) begin
                if (mem_res.valid[i]) begin
                    if (rob_type[mem_res.tag[i]] == REG) begin
                        // the load operation
                        rob_vals[mem_res.tag[i]] <= mem_res.val[i];
                        rob_ready[mem_res.tag[i]] <= 1'b1;
                    end else if (rob_type[mem_res.tag[i]] == ST) begin
                        // the store operation
                        rob_ready[mem_res.tag[i]] <= 1'b1;
                        rob_dest[mem_res.tag[i]] <= mem_res.addr[i];
                        rob_vals[mem_res.tag[i]] <= mem_res.val[i];
                    end
                end
            end
            for (int i = 0; i < NUM_CMP_RS; i++) begin
                // for checkpoint2 we assume all the predict result is true.
                if (cmp_res.valid[i]) begin
                    if (cmp_res.br_pred_res[i]) begin
                        // if the predict result is true
                        rob_ready[cmp_res.tag[i]] <= 1'b1;
                        if (rob_type[cmp_res.tag[i]] == BR) begin
                            // if the operation is branch
                            // for correct predict, nothing is needed
                        end else if (rob_type[cmp_res.tag[i]] == REG) begin
                            // if the operation is slt, store the compare result 1 or 0
                            rob_vals[cmp_res.val[i]] = cmp_res.val[i];
                        end
                    end
                end else begin
                    // TODO, for mispredict
                end
            end
        end
    end

    // the output to the decoder
    always_comb begin
        // given the current ready status and values of every ROB entry
        // output the value if alu cdb has the valid value 
        for (int i = 1; i < ROB_DEPTH + 1; i++) begin
            for (int j = 0; j < NUM_ALU_RS; j++) begin
                if (alu_res.valid[j] && (alu_res.tags[j] == i)) begin
                    rob_out.vals[i] = alu_res.vals[j];
                    rob_out.ready[i] = 1'b1;
                end else begin
                    rob_out.vals[i] = rob_vals[i];
                    rob_out.ready[i] = rob_ready[j];
                end
                
            end
        end

        // immediately return the next next available ROB entry number
        if (valid_in) begin
            // if detects valid_in, tell if the next entry is available
            rob_out.tag_ready = (~rob_busy[next_input_head]);
        end else begin
            // otherwise, tell if the current entry is avaiable
            rob_out.tag_ready = (~rob_busy[input_head]);
        end 

    end

    // output to the regfile
    always_comb begin
        load_val = '0;
        val_rd = '0;
        tag = '0;
        val = '0;
        if (commit_ready && (rob_type[commit_head] == REG)) begin
            // when committing, update the corresponding register
            load_val = 1'b1;
            val_rd = rob_dest[commit_head][4:0];
            val = rob_vals[commit_head];
            tag = commit_head;
        end
    end

    enum int unsigned {
        STORE_IDLE, STORE_PROCESSING
    } state, next_state;

    always_ff @( posedge clk ) begin
        if (rst | flush) begin
            state <= STORE_IDLE;
        end else begin
            state <= next_state;
        end
    end

    // output to the memory unit, for store operation
    always_comb begin
        next_state = state;
        case (state) 
            STORE_IDLE: begin
                mem_write = '0;
                mem_wdata = '0;
                mem_address = '0;
                new_store = '0;
                if (commit_ready && (rob_type[commit_head] == ST)) begin
                    mem_write = 1'b1;
                    mem_wdata = rob_vals[commit_head];
                    mem_address = rob_dest[commit_head];
                    new_store = 1'b1;
                    next_state = STORE_PROCESSING;
                end
            end
            STORE_PROCESSING: begin
                mem_write = 1'b1;
                mem_wdata = rob_vals[commit_head];
                mem_address = rob_dest[commit_head];
                new_store = '0;
                if (mem_resp) begin
                    mem_write = '0;
                    mem_wdata = '0;
                    mem_address = '0;
                    next_state = STORE_IDLE;
                end
            end
        endcase
    end

    // for checkpoint2, we assume all the prediction result is true.
    always_comb begin
        flush = 1'b0;
        // if (cmp_res.valid && (~cmp_res.br_pred_res)) begin
        //     // if the branch predict result is false
        //     flush = 1'b1;
        // end    
    end



endmodule : reorder_buffer
