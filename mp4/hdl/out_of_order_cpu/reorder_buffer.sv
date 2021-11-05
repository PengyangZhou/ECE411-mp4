module reorder_buffer 
(
    input logic clk,
    input logic rst,
    // port from decoder
    input logic valid_in,
    input logic [1:0] op_type,
    input logic [31:0] dest,
    // port from CDB
    cdb_itf alu_res,
    cdb_itf cmp_res,
    cdb_itf mem_res,
    // port to decoder
    output rob_out_t rob_out,
    // port to regfile
    output logic load_tag,
    output logic load_val,
    output rv32i_reg rd,
    output tag_t tag,
    output rv32i_word val,
    
    output logic flush
);

    // entry of reorder buffer
    // the entry of index 0 will be remained empty by intention
    bit rob_busy [ROB_DEPTH];          // high if the entry's value is not available
    logic [1:0] rob_type [ROB_DEPTH];  // instruction type. register operation, store, or branch
    rv32i_word rob_dest [ROB_DEPTH];   // for register operation, contains the index(only use bits [4:0]) 
                                       // for store or branch, contains the address
    rv32i_word rob_vals [ROB_DEPTH];   // contains the value of register or the value to store
    bit rob_ready [ROB_DEPTH];         // high if the entry is ready to commit

    tag_t input_head;   // pointing to the empty entry waiting for input
    tag_t next_input_head; 
    tag_t commit_head;  // pointing to the entry needs committing

    logic commit_ready; 
    assign commit_ready = rob_ready[commit_head];

    // increment the head pointer
    task inc_head(tag_t head);
        if (head == ROB_DEPTH - 1) begin
            head <= 4'd1;
        end else begin
            head <= head + 1'b1;
        end
    endtask

    always_ff @( posedge clk ) begin
        if (rst | flush) begin
            // empty the whole reorder buffer
            for (int i = 0; i < ROB_DEPTH; i++) begin
                rob_busy[i] <= '0;
                rob_type[i] <= '0;
                rob_dest[i] <= '0;
                rob_vals[i] <= '0;
                rob_ready[i] <= '0;
                input_head <= 4'd1;
                next_input_head <= 4'd2;
                commit_head <= 4'd1;
            end
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
                inc_head(commit_head);
            end
            if (alu_res.valid) begin
                // if the result out of alu is valid
                rob_vals[alu_res.tag] <= alu_res.val;
                rob_ready[alu_res.tag] <= 1'b1;
            end
        end
    end

    // the output to the decoder
    always_comb begin
        // given the current busy status and values of every ROB entry
        rob_out.busy = rob_busy;
        rob_out.vals = rob_vals;
        // immediately return the next next available ROB entry number
        if (rob_busy[next_input_head]) begin
            // if the next entry is not available, output 0
            rob_out.tag = '0;
        end else if (valid_in) begin
            // if detects valid_in and next entry is available
            rob_out.tag = next_input_head;
        end else begin
            // remains the tag to be the current one.
            rob_out.tag = rob_out.tag;
        end
    end

    // the output to the regfile
    always_comb begin
        load_val = 1'b0;
        load_tag = 1'b0;
        rd = '0;
        tag = '0;
        val = '0;
        if (commit_ready && (rob_type[commit_head] == REG)) begin
            // when committing, update the corresponding register
            load_val = 1'b1;
            val = rob_vals[commit_head];
            rd = rob_dest[commit_head][4:0];
            if (valid_in && (dest[4:0] == rob_dest[commit_head][4:0])) begin
                // if the new entry destination is the same as the committed one,
                // set the tag to be the new entry number
                tag = input_head;
            end else begin
                tag = commit_head;
            end
        end
        if (valid_in && (op_type == REG)) begin
            // when decoder adds a new entry in ROB
            load_tag = 1'b1;
            tag = input_head;
            rd = dest[4:0];
        end
    end

endmodule : reorder_buffer
