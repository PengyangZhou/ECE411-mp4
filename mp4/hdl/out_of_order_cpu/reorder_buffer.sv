import ooo_types::*;
import rv32i_types::*;

module reorder_buffer 
(
    input logic clk,
    input logic rst,
    // port from decoder
    input logic valid_in,
    input logic [1:0] op_type,
    input logic [31:0] dest,
    input logic [2:0] store_type,
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
    output logic [3:0] mem_byte_enable,
    // port to load/store buffer
    output logic new_store,
    // port to branch predictor
    output logic flush,
    output rv32i_word pc_correct,
    output logic br_predict,
    output logic br_correct,
    output rv32i_word br_pc_predict,
    output logic jalr_predict,
    output logic jalr_correct,
    // output logic jalr_mispredict,
    // output rv32i_word jalr_pc_mispredict,
    // output to indicate infinite loop
    output logic trap
);

    // entry of reorder buffer
    // the entry of index 0 will be remained empty by intention
    bit rob_busy [ROB_DEPTH + 1];          // high if the entry's value is not available
    logic [1:0] rob_type [ROB_DEPTH + 1];  // instruction type. register operation, store, or branch
    rv32i_word rob_dest [ROB_DEPTH + 1];   // for register operation, contains the index(only use bits [4:0]) 
                                           // for store or branch, contains the address
    rv32i_word rob_vals [ROB_DEPTH + 1];   // contains the value of register or the value to store
    bit rob_ready [ROB_DEPTH + 1];         // high if the entry is ready to commit
    bit rob_predict [ROB_DEPTH + 1];       // for storing branch and jalr predict result
    logic [2:0] rob_store_type [ROB_DEPTH + 1]; // for distinguish sb, sh and sw  TODO
    rv32i_word jalr_pc_next;               // used for storing the jalr

    tag_t input_head;   // pointing to the empty entry waiting for input
    tag_t next_input_head; 
    tag_t commit_head;  // pointing to the entry needs committing

    logic commit_ready; 
    assign commit_ready = rob_ready[commit_head];

    enum int unsigned {
        STORE_IDLE, STORE_PROCESSING
    } state, next_state;

    // increment the commit head pointer
    task inc_commit_head();
        if (commit_head == ROB_DEPTH) begin
            commit_head <= 4'd1;
        end else begin
            commit_head <= commit_head + 1'b1;
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
                rob_predict[i] <= 1'b1;
                rob_store_type[i] <= '0;
            end
            jalr_pc_next <= '0;
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
                if (op_type == ST) begin
                    // to distinguish sw, sh, sb
                    rob_store_type[input_head] <= store_type;
                end
                // increment the head pointer
                if (input_head == ROB_DEPTH) begin
                    input_head <= 4'd1;
                end else begin
                    input_head <= input_head + 1'b1;
                end
                if (next_input_head == ROB_DEPTH) begin
                    next_input_head <= 4'd1;
                end else begin
                    next_input_head <= next_input_head + 1'b1;
                end
            end
            if (commit_ready) begin
                if (rob_type[commit_head] == ST) begin
                    // if is the store operation, wait for completion.
                    if (next_state == STORE_IDLE) begin
                        rob_busy[commit_head] <= '0;
                        rob_type[commit_head] <= '0;
                        rob_dest[commit_head] <= '0;
                        rob_vals[commit_head] <= '0;
                        rob_ready[commit_head] <= '0;
                        rob_predict[commit_head] <= 1'b1;
                        rob_store_type[commit_head] <= '0;
                        inc_commit_head();
                    end
                end else begin
                    // if not the store operation, clear the entry
                    rob_busy[commit_head] <= '0;
                    rob_type[commit_head] <= '0;
                    rob_dest[commit_head] <= '0;
                    rob_vals[commit_head] <= '0;
                    rob_ready[commit_head] <= '0;
                    rob_predict[commit_head] <= 1'b1;
                    if (rob_type[commit_head] == JALR) begin
                        jalr_pc_next <= '0;
                    end
                    inc_commit_head();
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
                if (cmp_res.valid[i]) begin
                    rob_ready[cmp_res.tag[i]] <= 1'b1;
                    if (cmp_res.br_pred_res[i]) begin
                        // if the predict result is true
                        rob_predict[cmp_res.tag[i]] <= 1'b1;
                        if (rob_type[cmp_res.tag[i]] == BR) begin
                            // if the operation is branch
                            rob_vals[cmp_res.tag[i]] <= cmp_res.val[i];
                        end else if (rob_type[cmp_res.tag[i]] == REG) begin
                            // if the operation is slt, store the compare result 1 or 0
                            rob_vals[cmp_res.tag[i]] <= cmp_res.val[i];
                        end
                    end else begin
                        // if the predict result if false
                        rob_predict[cmp_res.tag[i]] <= 1'b0;
                        if (rob_type[cmp_res.tag[i]] == BR) begin
                            rob_vals[cmp_res.tag[i]] <= cmp_res.val[i]; // the pc of the instruction
                            rob_dest[cmp_res.tag[i]] <= cmp_res.pc_next[i]; // the correct next pc
                        end else if (rob_type[cmp_res.tag[i]] == REG) begin
                            // if the operation is slt, store the compare result 1 or 0
                            rob_vals[cmp_res.tag[i]] <= cmp_res.val[i];
                        end
                    end
                end
            end
            // jalr reservation station contains only 1 entry
            if (jalr_res.valid) begin
                rob_predict[jalr_res.tag] <= jalr_res.correct_predict;
                rob_ready[jalr_res.tag] <= 1'b1;
                rob_vals[jalr_res.tag] <= jalr_res.val;  // pc + 4
                jalr_pc_next <= jalr_res.pc_next; // correct next pc                
            end
        end
    end

    // the output to the decoder
    always_comb begin
        // given the current ready status and values of every ROB entry
        // output the value if alu cdb has the valid value 
        for (int i = 0; i < ROB_DEPTH + 1; i++) begin
            rob_out.vals[i] = rob_vals[i];
            rob_out.ready[i] = rob_ready[i];
            for (int j = 0; j < NUM_ALU_RS; j++) begin
                if (alu_res.valid[j] && (alu_res.tags[j] == i)) begin
                    rob_out.vals[i] = alu_res.vals[j];
                    rob_out.ready[i] = 1'b1;
                end  
            end
            for (int j = 0; j < NUM_CMP_RS; j++) begin
                if (cmp_res.valid[j] && (cmp_res.tag[j] == i) && (rob_type[i] == REG)) begin
                    rob_out.vals[i] = cmp_res.val[j];
                    rob_out.ready[i] = 1'b1;
                end
            end
            for (int j = 0; j < NUM_LDST_RS; j++) begin
                if (mem_res.valid[j] && (mem_res.tag[j] == i) && (rob_type[i] == REG)) begin
                    rob_out.vals[i] = mem_res.val[j];
                    rob_out.ready[i] = 1'b1;
                end
            end
        end

        // immediately return the next next available ROB entry number
        if (valid_in) begin
            // if detects valid_in, tell if the next entry is available
            rob_out.tag_ready = (rob_busy[next_input_head]) ? '0 : next_input_head;
        end else begin
            // otherwise, tell if the current entry is avaiable
            rob_out.tag_ready = (rob_busy[input_head]) ? '0 : input_head;
        end 

    end

    // output to the regfile
    always_comb begin
        load_val = '0;
        val_rd = '0;
        tag = '0;
        val = '0;
        if (commit_ready && ((rob_type[commit_head] == REG) | (rob_type[commit_head] == JALR))) begin
            // when committing, update the corresponding register
            load_val = 1'b1;
            val_rd = rob_dest[commit_head][4:0];
            val = rob_vals[commit_head];
            tag = commit_head;
        end
    end

    always_ff @( posedge clk ) begin
        if (rst | flush) begin
            state <= STORE_IDLE;
        end else begin
            state <= next_state;
        end
    end

    always_comb begin
        if (rob_type[commit_head] == ST) begin
            case (rob_store_type[commit_head])
                sw: mem_byte_enable = 4'b1111;
                sh: begin
                    case (rob_dest[commit_head][1])
                        1'b0: mem_byte_enable = 4'b0011;
                        1'b1: mem_byte_enable = 4'b1100;
                        default:;
                    endcase
                end
                sb: begin
                    case (rob_dest[commit_head][1:0])
                        2'b00: mem_byte_enable = 4'b0001;
                        2'b01: mem_byte_enable = 4'b0010;
                        2'b10: mem_byte_enable = 4'b0100;
                        2'b11: mem_byte_enable = 4'b1000;
                        default:;
                    endcase
                end    
                default: mem_byte_enable = 4'b1111;
            endcase
        end else begin
            mem_byte_enable = 4'b1111;
        end
    end

    rv32i_word store_data;
    always_comb begin
        case (rob_dest[commit_head][1:0])
            2'b00: store_data = rob_vals[commit_head];
            2'b01: store_data = {rob_vals[commit_head][23:0], rob_vals[commit_head][31:24]};
            2'b10: store_data = {rob_vals[commit_head][15:0], rob_vals[commit_head][31:16]};
            2'b11: store_data = {rob_vals[commit_head][7:0], rob_vals[commit_head][31:8]};
            default: store_data = rob_vals[commit_head];
        endcase
    end

    // output to the data cache, for store operation
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
                    mem_wdata = store_data;
                    mem_address = {rob_dest[commit_head][31:2], 2'b00};
                    // new_store = 1'b1;
                    next_state = STORE_PROCESSING;
                end
            end
            STORE_PROCESSING: begin
                mem_write = 1'b1;
                mem_wdata = store_data;
                mem_address = {rob_dest[commit_head][31:2], 2'b00};
                new_store = '0;
                if (mem_resp) begin
                    next_state = STORE_IDLE;
                    new_store = 1'b1;
                end
            end
        endcase
    end

    // output to the branch predictor
    always_comb begin
        flush = '0;
        trap = '0;
        // branch
        br_predict = '0;
        br_correct = '0;
        br_pc_predict = '0;
        // jalr
        jalr_predict = '0;
        jalr_correct = '0;
        // jalr_mispredict = '0;
        // jalr_pc_mispredict = '0;
        // the next correct pc, used when mispredict
        pc_correct = '0;

        if (commit_ready && (rob_predict[commit_head] == 0)) begin
            if (rob_type[commit_head] == BR) begin
                br_predict = 1'b1;
                br_correct = 1'b0;
                pc_correct = rob_dest[commit_head]; // the next correct pc
                br_pc_predict = rob_vals[commit_head]; // the pc of the branch instruction
                if (pc_correct == br_pc_predict) begin
                    // if is the infinite loop, stop the program
                    trap = 1'b1;
                end
                flush = 1'b1;
            end
            if (rob_type[commit_head] == JALR) begin
                jalr_predict = '1;
                jalr_correct = '0;
                // jalr_mispredict = '1;
                pc_correct = jalr_pc_next;
                // jalr_pc_mispredict = rob_vals[commit_head];
                flush = 1'b1;
            end
        end
        if (commit_ready && (rob_predict[commit_head] == 1)) begin
            if (rob_type[commit_head] == BR) begin
                br_predict = 1'b1;
                br_correct = 1'b1;
                br_pc_predict = rob_vals[commit_head]; // the pc of the branch instruction
            end
            if (rob_type[commit_head] == JALR) begin
                jalr_predict = '1;
                jalr_correct = '1;
            end
        end
        if (commit_ready && (rob_type[commit_head] == REG)) begin
            if (rob_dest[commit_head][31] == 1'b1) begin
                trap = 1'b1;
            end
        end
    end


endmodule : reorder_buffer
