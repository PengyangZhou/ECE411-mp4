/* This is the top-level module of our out-of-order processor. */

import rv32i_types::*;

module cpu (
    input clk,
    input rst,
    /* port between instruction cache */
    input mem_resp_i,
    input rv32i_word mem_rdata_i,
    output logic mem_read_i,
    output logic mem_write_i,
    output logic [3:0] mem_byte_enable_i,
    output rv32i_word mem_address_i,
    output rv32i_word mem_wdata_i,
    /* port between data cache */
    input mem_resp_d,
    input rv32i_word mem_rdata_d,
    output logic mem_read_d,
    output logic mem_write_d,
    output logic [3:0] mem_byte_enable_d,
    output rv32i_word mem_address_d,
    output rv32i_word mem_wdata_d
);
    logic mem_read_resp;
    logic mem_write_resp;
    logic mem_address_d_read;
    logic mem_address_d_write;

    assign mem_read_resp = (1 == mem_resp_d && mem_read_d) ? 1'b1 : 1'b0;
    assign mem_write_resp = (1 == mem_resp_d && mem_write_d) ? 1'b1 : 1'b0;
    assign mem_address_d = (1 == mem_write_d) ? mem_address_d_write : mem_address_d_read;

    logic flush;

    rv32i_word pc_predictor;
    rv32i_word inst_predictor;
    rv32i_word pc_next_predictor;
    logic br_pred_predictor;
    
    logic br_mispredict;
    logic jalr_mispredict;
    rv32i_word pc_correct;
    rv32i_word br_pc_mispredict;
    rv32i_word jalr_pc_mispredict;

    logic iq_valid;
    logic iq_ready;
    logic iq_shift;
    
    branch_predictor branch_predictor_inst(
        .clk(clk),
        .rst(rst),
        // port with instruction queue
        .iq_ready(iq_ready),
        .pc(pc_predictor),
        .inst(inst_predictor),
        .pc_next(pc_next_predictor),
        .br_pred(br_pred_predictor),
        .iq_valid(iq_valid),
        // update and flush logic
        .flush(flush),
        .br_mispredict(br_mispredict),
        .jalr_mispredict(jalr_mispredict),
        .pc_correct(pc_correct),
        .br_pc_mispredict(br_pc_mispredict),
        .jalr_pc_mispredict(jalr_pc_mispredict),
        // port with instruction cache
        .mem_resp_i(mem_resp_i),
        .mem_rdata_i(mem_rdata_i),
        .mem_read_i(mem_read_i),
        .mem_write_i(mem_write_i),
        .mem_byte_enable_i(mem_byte_enable_i),
        .mem_address_i(mem_address_i),
        .mem_wdata_i(mem_wdata_i)
    );

    logic valid_decoder;
    rv32i_word pc_decoder;
    rv32i_word pc_next_decoder;
    rv32i_word inst_decoder;
    logic br_pred_decoder;

    instruction_queue instruction_queue_inst(
        .clk(clk),
        .rst(rst),
        .flush(flush),
        /* port to branch predictor */
        .ready(iq_ready),
        /* port from branch predictor */
        .valid_in(iq_valid),
        .inst_in(pc_predictor),
        .pc_in(inst_predictor),
        .pc_next_in(pc_next_predictor),
        .br_pred_in(br_pred_predictor),
        /* port from decoder */
        .shift(iq_shift),
        /* port to decoder */
        .valid_out(valid_decoder),
        .pc_out(pc_decoder),
        .pc_next_out(pc_next_decoder),
        .inst_out(inst_decoder),
        .br_pred_out(br_pred_decoder)
    );

    rv32i_reg    rs1;
    rv32i_reg    rs2;
    logic        load_tag;
    tag_t        tag_out;
    rv32i_reg    rd_out;
    tag_t         reg_Qj;
    tag_t         reg_Qk;
    rv32i_word    reg_Vj;
    rv32i_word    reg_Vk;
    logic        rob_valid;
    op_type_t    rob_op;
    rv32i_word   rob_dest;
    rob_out_t     rob_data;
    alu_rs_itf  alu_itf();
    cmp_rs_itf  cmp_itf();
    lsb_rs_itf  lsb_itf();
    jalr_itf jalr_itf();

    decoder decoder_inst(
        .clk(clk),
        .rst(rst),
        .valid_in(valid_decoder),
        .pc_in(pc_decoder),
        .pc_next_in(pc_next_decoder),
        .inst_in(inst_decoder),
        .br_pred_in(br_pred_decoder),
        /* port to instruction queue */
        .shift(iq_shift),
        /* port to regfile */
        .rs1(rs1),
        .rs2(rs2),
        .load_tag(load_tag),
        .tag_out(tag_out),
        .rd_out(rd_out),
        /* port from regfile */
        .reg_Qj(reg_Qj),
        .reg_Qk(reg_Qk),
        .reg_Vj(reg_Vj),
        .reg_Vk(reg_Vk),
        /* port to ROB */
        .rob_valid(rob_valid),
        .rob_op(rob_op),
        .rob_dest(rob_dest),
        .rob_data(rob_data),
        .alu_itf(alu_itf.decoder),
        .cmp_itf(cmp_itf.decoder),
        .lsb_itf(lsb_itf.decoder),
        .jalr_itf(jalr_itf.decoder)
    );

    alu_cdb_t alu_res;
    cmp_cdb_t cmp_res;
    mem_cdb_t mem_res;
    jalr_cdb_t jalr_res;

    logic load_val_rob_reg;
    rv32i_reg val_rd_rob_reg;
    tag_t tag_rob_reg;
    rv32i_word val_rob_reg;

    logic new_store;

    reorder_buffer rob_inst(
        .clk(clk),
        .rst(rst),
        // port from decoder
        .valid_in(rob_valid),
        .op_type(rob_op),
        .dest(rob_dest),
        // port from CDB
        .alu_res(alu_res),
        .cmp_res(cmp_res),
        .mem_res(mem_res),
        .jalr_res(jalr_res),
        // port from data cache
        .mem_resp(mem_write_resp),
        // port to decoder
        .rob_out(rob_data),
        // port to regfile
        .load_val(load_val_rob_reg),
        .val_rd(val_rd_rob_reg),
        .tag(tag_rob_reg),
        .val(val_rob_reg),
        // port to data cache
        .mem_write(mem_write_d),
        .mem_wdata(mem_wdata_d),
        .mem_address(mem_address_d_write),
        .mem_byte_enable(mem_byte_enable_d),
        .new_store(new_store),
        // flush signal
        .br_mispredict(br_mispredict),
        .jalr_mispredict(jalr_mispredict),
        .pc_correct(pc_correct),
        .br_pc_mispredict(br_pc_mispredict),
        .jalr_pc_mispredict(jalr_pc_mispredict),
        .flush(flush)
    );

    regfile regfile_inst(
        .clk(clk),
        .rst(rst),
        .flush(flush),
        /* port from ROB */
        .load_val(load_val_rob_reg),
        .val_rd(val_rd_rob_reg),
        .val(val_rob_reg),
        .tag_from_rob(tag_rob_reg),
        /* port from decoder */
        .rs1(rs1),
        .rs2(rs2),
        .load_tag(load_tag),
        .tag_from_decoder(tag_out),
        .tag_rd(rd_out),
        /* port to decoder */
        .t1_out(reg_Qj),
        .t2_out(reg_Qk),
        .rs1_out(reg_Vj),
        .rs2_out(reg_Vk)
    );

    alu_rs alu_rs_inst(
        .clk(clk),
        .rst(rst),
        .flush(flush),
        /* port from decoder */
        .alu_itf(alu_itf.alu_rs),
        /* port from ROB */
        .rob_data(rob_data),
        /* port to CDB */
        .alu_res(alu_res)
    );

    cmp_rs cmp_rs_inst(
        .clk(clk),
        .rst(rst),
        .flush(flush),
        /* port from decoder */
        .cmp_itf(cmp_itf.cmp_rs),
        /* port from ROB */
        .rob_data(rob_data),
        /* port to CDB */
        .cmp_res(cmp_res)
    );

    lsb_rs lsb_rs_inst(
        .clk(clk),
        .rst(rst),
        .flush(flush),
        /* port from decoder */
        .lsb_itf(lsb_itf.lsb_rs),
        /* port from ROB */
        .new_store(new_store),
        .rob_data(rob_data),
        /* port to CDB */
        .mem_res(mem_res),
        /* port to data cache */
        .mem_read_d(mem_read_d),
        .mem_address_d(mem_address_d_read),
        /* port from data cache */
        .mem_resp_d(mem_read_resp),
        .mem_rdata_d(mem_rdata_d)
    );

    jalr lalr_inst(
        .clk(clk),
        .rst(rst),
        .flush(flush),
        /* port from decoder */
        .jalr_itf(jalr_itf.jalr),
        /* port from ROB */
        .rob_data(rob_data),
        /* port to CDB */
        .jalr_res(jalr_res)
    );

endmodule