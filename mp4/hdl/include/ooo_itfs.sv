/*  Ports between RS and decoder, functional units and CDB are encapsulated.
    This is for convenient refraction of CDB signals.
 */

import rv32i_types::*;
import ooo_types::*;

interface cdb_itf;
    bit             busy;
    logic [4:0]     tag;
    logic [31:0]    val;

endinterface : cdb_itf

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
    rv32i_word  Vj;
    rv32i_word  Vk;
    tag_t       Qj;
    tag_t       Qk;
    cmp_ops     cmp_op; /* cmp opcode */
    tag_t       dest;   /* destination of computation result */
    bit         br_pred,
    bit         valid, ready;  /* ready means the reservation station has empty space */
    rv32i_word  pc, pc_next;

    modport decoder (
        input ready,
        output Vj, Vk, Qj, Qk, cmp_op, dest, valid, pc, pc_next, br_pred
    );

    modport cmp_rs (
        input Vj, Vk, Qj, Qk, cmp_op, dest, valid, pc, pc_next, br_pred,
        output ready
    );
endinterface //cmp_rs

interface lsb_rs_itf;
    rv32i_word  Vj;
    rv32i_word  Vk;
    tag_t       Qj;
    tag_t       Qk;
    bit         lsb_op; /* lsb opcode */
    tag_t       dest;   /* destination of computation result */
    bit         valid, ready;  /* ready means the RS has empty space */

    modport decoder (
        input ready,
        output Vj, Vk, Qj, Qk, lsb_op, dest, valid
    );

    modport lsb_rs (
        input Vj, Vk, Qj, Qk, lsb_op, dest, valid,
        output ready
    );
endinterface //lsb_rs
