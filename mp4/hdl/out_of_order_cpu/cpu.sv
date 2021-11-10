/* This is the top-level module of our out-of-order processor. */

import rv32i_types::*;

module cpu (
    input clk,
    input rst,
    input mem_resp,
    input rv32i_word mem_rdata,
    output logic mem_read,
    output logic mem_write,
    output logic [3:0] mem_byte_enable,
    output rv32i_word mem_address,
    output rv32i_word mem_wdata
);

    branch_predictor branch_predictor_inst(
        .clk(clk),
        .rst(rst),
        // port with instruction queue
        .iq_ready(),
        .pc(),
        .inst(),
        .pc_next(),
        .br_pred(),
        .iq_valid(),
        // update and flush logic
        .flush(),
        .br_mispredict(),
        .jalr_mispredict(),
        .pc_correct(),
        .br_pc_mispredict(),
        .jalr_pc_mispredict(),
        // port with instruction cache
        .mem_resp_i(),
        .mem_rdata_i(),
        .mem_read_i(),
        .mem_write_i(),
        .mem_byte_enable_i(),
        .mem_address_i(),
        .mem_wdata_i()
    );

    inst_queue inst_queue_inst(
        .clk(clk),
        .rst(rst),
        .flush(),
        /* port to branch predictor */
        .ready(),
        /* port from branch predictor */
        .valid_in(),
        .inst_in(),
        .pc_in(),
        .pc_next_in(),
        .br_pred_in(),
        /* port from decoder */
        .shift(),
        /* port to decoder */
        .valid_out(),
        .pc_out(),
        .pc_next_out(),
        .inst_out(),
        .br_pred_out()
    );

    decoder decoder_inst(
        .clk(clk),
        .rst(rst),
        .valid_in(),
        .pc_in(),
        .pc_next_in(),
        .inst_in(),
        .br_pred_in(),
        /* port to instruction queue */
        .shift(),
        /* port to regfile */
        .rs1(),
        .rs2(),
        .load_tag(),
        .tag_out(),
        .rd_out(),
        /* port from regfile */
        .reg_Qj(),
        .reg_Qk(),
        .reg_Vj(),
        .reg_Vk(),
        /* port to ROB */
        .rob_valid(),
        .rob_op(),
        .rob_dest(),
        .rob_data(),
        .alu_itf(),
        .cmp_itf(),
        .lsb_itf()
    );

    reorder_buffer rob_inst(
        .clk(clk),
        .rst(rst),
        // port from decoder
        .valid_in(),
        .op_type(),
        .dest(),
        // port from CDB
        .alu_res(),
        .cmp_res(),
        .mem_res(),
        // port to decoder
        .rob_out(),
        // port to regfile
        .load_val(),
        .val_rd(),
        .tag(),
        .val(),
        // port to data cache
        .mem_write(),
        .mem_wdata(),
        .mem_address(),
        // flush signal
        .flush()
    );

    regfile regfile_inst(
        .clk(clk),
        .rst(rst),
        .flush(),
        /* port from ROB */
        .load_val(),
        .val_rd(),
        .val(),
        .tag_from_rob(),
        /* port from decoder */
        .rs1(),
        .rs2(),
        .load_tag(),
        .tag_from_decoder(),
        .tag_rd(),
        /* port to decoder */
        
    );

    alu_rs alu_rs_inst(
        .clk(clk),
        .rst(rst),
        .flush(),
        /* port from decoder */
        .alu_itf(),
        /* port from ROB */
        .rob_data(),
        /* port to CDB */
        .alu_res()
    );

    cmp_rs cmp_rs_inst(
        .clk(clk),
        .rst(rst),
        .flush(),
        /* port from decoder */
        .cmp_itf(),
        /* port from ROB */
        .rob_data(),
        /* port to CDB */
        .cmp_res()
    );

    lsb_rs lsb_rs_inst(
        .clk(clk),
        .rst(rst),
        .flush(),
        /* port from decoder */
        .lsb_itf(),
        /* port from ROB */
        .rob_data(),
        /* port to CDB */
        .mem_res(),
        /* port to data cache */
        .mem_read_d(),
        .mem_address_d(),
        /* port from data cache */
        .mem_resp_d(),
        .mem_rdata_d()
    );
    
    
endmodule