/*  Ports between RS and decoder, functional units and CDB are encapsulated.
    This is for convenient refraction of CDB signals.
 */

import rv32i_types::*;
import ooo_types::*;

interface alu_rs_itf;
    rv32i_word  Vj;
    rv32i_word  Vk;
    tag_t       Qj;
    tag_t       Qk;
    alu_ops     alu_op; /* alu opcode */
    tag_t       dest;   /* destination of computation result */
    bit         valid, ready;  /* ready means the RS has empty space */

    modport decoder (
        input ready,
        output Vj, Vk, Qj, Qk, alu_op, dest, valid
    );

    modport alu_rs (
        input Vj, Vk, Qj, Qk, alu_op, dest, valid,
        output ready
    );
endinterface //alu_rs

interface cmp_rs_itf;
    logic       is_br;
    rv32i_word  Vj;
    rv32i_word  Vk;
    tag_t       Qj;
    tag_t       Qk;
    branch_funct3_t cmp_op; /* cmp opcode */
    tag_t       dest;       /* destination of computation result */
    bit         br_pred;
    bit         valid, ready;   /* ready means the reservation station has empty space */
    rv32i_word  pc, b_imm;

    modport decoder (
        input ready,
        output is_br, Vj, Vk, Qj, Qk, cmp_op, dest, valid, pc, b_imm, br_pred
    );

    modport cmp_rs (
        input is_br, Vj, Vk, Qj, Qk, cmp_op, dest, valid, pc, b_imm, br_pred,
        output ready
    );
endinterface //cmp_rs

interface lsb_rs_itf;
    rv32i_word  Vj;
    rv32i_word  Vk;
    rv32i_word  A;  /* the immediate value involved to calculate address */
    tag_t       Qj;
    tag_t       Qk;
    bit         lsb_op; /* lsb opcode. 1 means write. 0 means load. */
    logic [2:0] funct;
    tag_t       dest;   /* destination of computation result */
    bit         valid, ready;  /* ready means the RS has empty space */

    modport decoder (
        input ready,
        output Vj, Vk, A, Qj, Qk, lsb_op, funct, dest, valid
    );

    modport lsb_rs (
        input Vj, Vk, A, Qj, Qk, lsb_op, funct, dest, valid,
        output ready
    );
endinterface //lsb_rs

interface jalr_itf
    rv32i_word  Vj;
    rv32i_word  A;  /* the immediate value involved to calculate address */
    tag_t       Qj;
    tag_t       dest;   /* destination of computation result */
    bit         valid, ready;
    rv32i_word  pc, pc_next;
    modport decoder (
        input ready,
        output Vj, A, Qj, dest, valid, pc, pc_next
    );

    modport jalr (
        input Vj, A, Qj, dest, valid, pc, pc_next,
        output ready
    );
endinterface //jalr_itf
