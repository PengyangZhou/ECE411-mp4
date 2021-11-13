/* This is the decoder, which is responsible for issuing instructions. */
// `include "cdb_itf.sv"

// import rv32i_types::*; // may cause "package already imported" error
// import ooo_types::*;
import ooo_types::*;
import rv32i_types::*;

module decoder (
    input logic clk,
    input logic rst,
    /* port from instruction queue */
    input logic      valid_in,
    input rv32i_word pc_in,
    input rv32i_word pc_next_in,
    input rv32i_word inst_in,
    input logic      br_pred_in,
    /* port to instruction queue */
    output logic     shift,
    /* port to regfile */
    output rv32i_reg    rs1,
    output rv32i_reg    rs2,
    output logic        load_tag,
    output tag_t        tag_out,
    output rv32i_reg    rd_out,
    /* port from regfile */
    input tag_t         reg_Qj,
    input tag_t         reg_Qk,
    input rv32i_word    reg_Vj,
    input rv32i_word    reg_Vk,
    /* port to ROB */
    output logic        rob_valid,  /* indicate there is a new inst coming */
    output op_type_t    rob_op,     /* there are 3 types of operation in ROB */
    output rv32i_word   rob_dest,   /* destination can be ROB entry or memory address */
    output store_funct3_t rob_st_type,
    /* port from ROB */
    input rob_out_t     rob_data,
    /* port to ALU RS */
    alu_rs_itf.decoder  alu_itf,
    /* port to CMP RS */
    cmp_rs_itf.decoder  cmp_itf,
    /* port to Load/Store buffer */
    lsb_rs_itf.decoder  lsb_itf,
    /* port to jalr */
    jalr_itf.decoder jalr_itf
);
    /* implemented as to take 1 cycle to decode */
    /* May need accommodation due to long critical path */
    
    /* intermediate variables */
    logic [2:0] funct3;
    logic [6:0] funct7;
    rv32i_opcode opcode;
    logic [31:0] i_imm;
    logic [31:0] s_imm;
    logic [31:0] b_imm;
    logic [31:0] u_imm;
    // logic [31:0] j_imm;
    rv32i_reg    rd;
    branch_funct3_t branch_funct3;
    store_funct3_t  store_funct3;
    load_funct3_t   load_funct3;
    arith_funct3_t  arith_funct3;
    rv32i_word  Vj_out, Vk_out;
    tag_t       Qj_out, Qk_out;
    
    /* instruction deconstruction */
    assign funct3 = inst_in[14:12];
    assign funct7 = inst_in[31:25];
    assign opcode = rv32i_opcode'(inst_in[6:0]);
    assign i_imm = {{21{inst_in[31]}}, inst_in[30:20]};
    assign s_imm = {{21{inst_in[31]}}, inst_in[30:25], inst_in[11:7]};
    assign b_imm = {{20{inst_in[31]}}, inst_in[7], inst_in[30:25], inst_in[11:8], 1'b0};
    assign u_imm = {inst_in[31:12], 12'h000};
    // assign j_imm = {{12{inst_in[31]}}, inst_in[19:12], inst_in[20], inst_in[30:21], 1'b0};
    assign rs1 = inst_in[19:15];
    assign rs2 = inst_in[24:20];
    assign rd = inst_in[11:7];
    assign arith_funct3 = arith_funct3_t'(funct3);
    assign branch_funct3 = branch_funct3_t'(funct3);
    assign load_funct3 = load_funct3_t'(funct3);
    assign store_funct3 = store_funct3_t'(funct3);

    /* V and Q output */
    assign Vj_out = (reg_Qj != 0 && rob_data.ready[reg_Qj]) ? rob_data.vals[reg_Qj] : reg_Vj;
    assign Vk_out = (reg_Qk != 0 && rob_data.ready[reg_Qk]) ? rob_data.vals[reg_Qk] : reg_Vk;
    assign Qj_out = (reg_Qj != 0 && rob_data.ready[reg_Qj]) ? 4'b0 : reg_Qj;
    assign Qk_out = (reg_Qk != 0 && rob_data.ready[reg_Qk]) ? 4'b0 : reg_Qk;

    /* task definition */
    task send_to_ALU(input rv32i_word Vj, input rv32i_word Vk, input tag_t Qj, input tag_t Qk,
        input alu_ops alu_op, input tag_t dest);
        alu_itf.valid   <= 1'b1;
        alu_itf.Vj      <= Vj;
        alu_itf.Vk      <= Vk;
        alu_itf.Qj      <= Qj;
        alu_itf.Qk      <= Qk;
        alu_itf.alu_op  <= alu_op;
        alu_itf.dest    <= dest;
    endtask

    task send_to_CMP(input logic is_br, input rv32i_word Vj, input rv32i_word Vk, input tag_t Qj, input tag_t Qk,
        input branch_funct3_t cmp_op, input tag_t dest, input logic br_pred,
        input rv32i_word pc, input rv32i_word b_imm);
        cmp_itf.valid   <= 1'b1;
        cmp_itf.is_br   <= is_br;
        cmp_itf.Vj      <= Vj;
        cmp_itf.Vk      <= Vk;
        cmp_itf.Qj      <= Qj;
        cmp_itf.Qk      <= Qk;
        cmp_itf.cmp_op  <= cmp_op;
        cmp_itf.dest    <= dest;
        cmp_itf.pc      <= pc;
        cmp_itf.b_imm   <= b_imm;
        cmp_itf.br_pred <= br_pred;
    endtask

    task send_to_LSB(input rv32i_word Vj, input rv32i_word Vk, input rv32i_word A,
        input tag_t Qj, input tag_t Qk, input logic lsb_op, input logic [2:0] funct, input tag_t dest);
        lsb_itf.valid   <= 1'b1;
        lsb_itf.Vj      <= Vj;
        lsb_itf.Vk      <= Vk;
        lsb_itf.A       <= A;
        lsb_itf.Qj      <= Qj;
        lsb_itf.Qk      <= Qk;
        lsb_itf.lsb_op  <= lsb_op;
        lsb_itf.funct   <= funct;
        lsb_itf.dest    <= dest;
    endtask
    
    /* main logic */
    always_ff @( posedge clk ) begin : issue_logic
        if(rst)begin
            rob_valid   <= 1'b0;
            rob_op      <= REG;
            rob_dest    <= 0;
            alu_itf.valid   <= 1'b0;
            cmp_itf.valid   <= 1'b0;
            lsb_itf.valid   <= 1'b0;
            jalr_itf.valid  <= 1'b0;
        end else begin
            /* defaults. same as reset */
            rob_valid   <= 1'b0;
            rob_op      <= REG;
            rob_dest    <= 0;
            alu_itf.valid   <= 1'b0;
            cmp_itf.valid   <= 1'b0;
            lsb_itf.valid   <= 1'b0;
            jalr_itf.valid  <= 1'b0;
            /* decode each instruction */
            if(valid_in)begin
                case (opcode)
                    op_imm: begin
                        /* check availability */
                        if(rd != 0 && rob_data.tag_ready != 0)begin
                            /* prepare ROB entry data but do not set valid yet */
                            rob_op      <= REG;
                            rob_dest    <= rd;
                            /* send new entry to ALU RS or CMP RS */
                            case (arith_funct3)
                                slt: begin
                                    if(cmp_itf.ready)begin
                                        send_to_CMP(0, Vj_out, i_imm, Qj_out, 0, blt, rob_data.tag_ready, 0, 0, 0);
                                        rob_valid <= 1'b1;
                                    end
                                end

                                sltu: begin
                                    if(cmp_itf.ready)begin
                                        send_to_CMP(0, Vj_out, i_imm, Qj_out, 0, bltu, rob_data.tag_ready, 0, 0, 0);
                                        rob_valid <= 1'b1;
                                    end
                                end

                                sr: begin
                                    if(alu_itf.ready)begin
                                        if(funct7[5])begin
                                            send_to_ALU(Vj_out, i_imm, Qj_out, 0, alu_sra, rob_data.tag_ready);
                                        end else begin
                                            send_to_ALU(Vj_out, i_imm, Qj_out, 0, alu_srl, rob_data.tag_ready);
                                        end
                                        rob_valid <= 1'b1;
                                    end
                                end

                                add, sll, axor, aor, aand: begin
                                    if(alu_itf.ready)begin
                                        send_to_ALU(Vj_out, i_imm, Qj_out, 0, alu_ops'(funct3), rob_data.tag_ready);
                                        rob_valid <= 1'b1;
                                    end
                                end

                                default: ;
                            endcase
                        end
                        
                    end
                    
                    op_reg: begin
                        /* to ROB */
                        if(rd != 0 && rob_data.tag_ready != 0)begin
                            /* prepare ROB entry data but do not set valid yet */
                            rob_op      <= REG;
                            rob_dest    <= rd;
                            /* to ALU RS or CMP RS */
                            case (arith_funct3)
                                add: begin
                                    if(alu_itf.ready)begin
                                        if(funct7[5])begin
                                            send_to_ALU(Vj_out, Vk_out, Qj_out, Qk_out, alu_sub, rob_data.tag_ready);
                                        end else begin
                                            send_to_ALU(Vj_out, Vk_out, Qj_out, Qk_out, alu_add, rob_data.tag_ready);
                                        end
                                        rob_valid <= 1'b1;
                                    end
                                end

                                sr: begin
                                    if(alu_itf.ready)begin
                                        if(funct7[5])begin
                                            send_to_ALU(Vj_out, Vk_out, Qj_out, Qk_out, alu_sra, rob_data.tag_ready);
                                        end else begin
                                            send_to_ALU(Vj_out, Vk_out, Qj_out, Qk_out, alu_srl, rob_data.tag_ready);
                                        end
                                        rob_valid <= 1'b1;
                                    end
                                end

                                slt: begin
                                    if(cmp_itf.ready)begin
                                        send_to_CMP(0, Vj_out, Vk_out, Qj_out, Qk_out, blt, rob_data.tag_ready, 0, 0, 0); 
                                        rob_valid <= 1'b1;
                                    end
                                end

                                sltu: begin
                                    if(cmp_itf.ready)begin
                                        send_to_CMP(0, Vj_out, Vk_out, Qj_out, Qk_out, bltu, rob_data.tag_ready, 0, 0, 0);
                                        rob_valid <= 1'b1;
                                    end
                                end

                                axor, sll, aor, aand: begin
                                    if(alu_itf.ready)begin
                                        send_to_ALU(Vj_out, Vk_out, Qj_out, Qk_out, alu_ops'(funct3), rob_data.tag_ready);
                                        rob_valid <= 1'b1;
                                    end
                                end
                                default: ;
                            endcase
                        end
                    end

                    op_lui: begin
                        if(rd != 0 && rob_data.tag_ready != 0 && alu_itf.ready)begin
                            rob_op      <= REG;
                            rob_dest    <= rd;
                            rob_valid   <= 1'b1;
                            send_to_ALU(0, u_imm, 0, 0, alu_add, rob_data.tag_ready);
                        end
                    end

                    op_auipc: begin
                        if(rd != 0 && rob_data.tag_ready != 0 && alu_itf.ready)begin
                            rob_op      <= REG;
                            rob_dest    <= rd;
                            rob_valid   <= 1'b1;
                            send_to_ALU(pc_in, u_imm, 0, 0, alu_add, rob_data.tag_ready); /* perform PC+u_imm */
                        end
                    end

                    op_br: begin
                        if(rob_data.tag_ready != 0 && cmp_itf.ready)begin
                            rob_op      <= BR;
                            rob_dest    <= rd;
                            rob_valid   <= 1'b1;
                            send_to_CMP(1, Vj_out, Vk_out, Qj_out, Qk_out, branch_funct3, rob_data.tag_ready, br_pred_in, pc_in, b_imm);
                        end
                    end

                    op_jal: begin
                        if(rob_data.tag_ready != 0 && alu_itf.ready)begin
                            rob_op    <= REG; /* jal is regarded as REG. Because it will write value to a register. */
                            rob_dest  <= rd;
                            rob_valid <= 1'b1;
                            send_to_ALU(pc_in, 4, 0, 0, alu_add, rob_data.tag_ready); /* perfrom PC+4 */
                        end
                    end

                    op_jalr: begin
                    if(rob_data.tag_ready != 0 && jalr_itf.ready)begin
                        rob_op      <= JALR;
                        rob_dest    <= rd;
                        rob_valid   <= 1'b1;
                        jalr_itf.valid <= 1'b1;
                        jalr_itf.Vj <= Vj_out;
                        jalr_itf.A <= i_imm;
                        jalr_itf.Qj <= Qj_out;
                        jalr_itf.dest <= rob_data.tag_ready;
                        jalr_itf.pc <= pc_in;
                        jalr_itf.pc_next <= pc_next_in;
                        end
                    end

                    op_load: begin
                        if(rd != 0 && rob_data.tag_ready != 0 && lsb_itf.ready)begin
                            rob_op      <= REG;
                            rob_dest    <= rd;
                            rob_valid   <= 1'b1;
                            send_to_LSB(Vj_out, 0, i_imm, Qj_out, 0, 1'b0, load_funct3, rob_data.tag_ready);
                        end
                    end

                    op_store: begin
                        if(rob_data.tag_ready != 0 && lsb_itf.ready)begin
                            rob_op      <= ST;  /* don't need dest here */
                            rob_valid   <= 1'b1;
                            rob_st_type <= store_funct3;
                            send_to_LSB(Vj_out, Vk_out, s_imm, Qj_out, Qk_out, 1'b1, store_funct3, rob_data.tag_ready);
                        end
                    end

                    default: ;
                endcase
            end
        end
    end : issue_logic

    /* shift and load_tag logic */
    always_comb begin : shift_loadtag_logic
        if(rst)begin
            shift = 1'b0;
            load_tag = 1'b0;
            tag_out = 0;
            rd_out = 0;
        end else begin
            /* set defaults */
            shift = 1'b0;
            load_tag = 1'b0;
            tag_out = 0;
            rd_out = 0;

            case (opcode)
                op_imm: begin
                    if(rob_data.tag_ready != 0)begin
                        if(rd == 0)begin
                            shift = 1'b1; /* if rd = 0, we only shift the instruction queue */
                        end else begin 
                            case (arith_funct3)
                                slt, sltu: begin
                                    if(cmp_itf.ready)begin
                                        shift    = 1'b1;   
                                        load_tag = 1'b1;
                                        tag_out  = rob_data.tag_ready;
                                        rd_out   = rd;
                                    end
                                end

                                sr, add, sll, axor, aor, aand: begin
                                    if(alu_itf.ready)begin
                                        shift    = 1'b1;
                                        load_tag = 1'b1;
                                        tag_out  = rob_data.tag_ready;
                                        rd_out   = rd;
                                    end
                                end
                                default: ;
                            endcase
                        end
                    end
                end

                op_reg: begin
                    if(rob_data.tag_ready != 0)begin
                        if(rd == 0)begin 
                            shift = 1'b1;
                        end else begin 
                            case (arith_funct3)
                                add, sr, axor, sll, aor, aand: begin
                                    if(alu_itf.ready)begin
                                        shift    = 1'b1;
                                        load_tag = 1'b1;
                                        tag_out  = rob_data.tag_ready;
                                        rd_out   = rd;
                                    end
                                end

                                slt, sltu: begin
                                    if(cmp_itf.ready)begin
                                        shift    = 1'b1;
                                        load_tag = 1'b1;
                                        tag_out  = rob_data.tag_ready;
                                        rd_out   = rd;
                                    end
                                end
                                default: ;
                            endcase 
                        end 
                    end
                end

                op_lui, op_auipc, op_jal: begin
                    if(rd == 0)begin
                        shift    = 1'b1;
                    end else if(rob_data.tag_ready != 0 && alu_itf.ready)begin
                        shift    = 1'b1;
                        load_tag = 1'b1;
                        tag_out  = rob_data.tag_ready;
                        rd_out   = rd;
                    end
                end

                op_jalr: begin
                if(rob_data.tag_ready != 0 && jalr_itf.ready)begin
                        shift    = 1'b1;
                    end
                end

                op_br: begin
                    if(rob_data.tag_ready != 0 && cmp_itf.ready)begin
                        shift    = 1'b1;
                    end
                end

                op_load: begin
                    if(rd == 0)begin
                        shift    = 1'b1;
                    end else if(rob_data.tag_ready != 0 && lsb_itf.ready)begin
                        shift    = 1'b1;
                        load_tag = 1'b1;
                        tag_out  = rob_data.tag_ready;
                        rd_out   = rd;
                    end
                end

                op_store: begin
                    if(rob_data.tag_ready != 0 && lsb_itf.ready)begin
                        shift    = 1'b1;
                    end
                end

                default: ;
            endcase
        end
        
    end : shift_loadtag_logic

endmodule
