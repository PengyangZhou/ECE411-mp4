/* add customized types here if necessary */

`ifndef OOO_TYPES_SV
`define OOO_TYPES_SV

package ooo_types;

    import rv32i_types::*;

    parameter int INST_QUEUE_DEPTH = 6;
    parameter int ROB_DEPTH   = 14;
    parameter int NUM_ALU_RS  = 5;
    parameter int NUM_CMP_RS  = 3;
    parameter int NUM_LDST_RS = 7;
    parameter int NUM_LDST_RS_LOG2 = 3;
    parameter MAX_STORE_INDEX = 4; // Based on ROB_DEPTH

    typedef logic [3:0] tag_t;
    
    typedef enum logic [1:0] { 
        REG = 2'b00, 
        ST  = 2'b01, 
        BR  = 2'b10,
        JALR = 2'b11
    } op_type_t;

    typedef struct {
        tag_t       tag_ready;            // the valid ROB entry number to put, 0 for no empty space
        bit         ready [ROB_DEPTH+1];  // set high if the entry is ready to commit
        rv32i_word  vals [ROB_DEPTH+1];   // values for each destination
    } rob_out_t;

    typedef struct {
        bit         valid [NUM_CMP_RS];       /* indicating there is valid data on the bus */
        bit         br_pred_res [NUM_CMP_RS]; /* signal from CMP to ROB. 1 means prediction was true. */
        tag_t       tag [NUM_CMP_RS];
        rv32i_word  val [NUM_CMP_RS]; // the pc of the instruction, or value stored in the register
        rv32i_word  pc_next [NUM_CMP_RS]; // correct pc_next
    } cmp_cdb_t;

    // the cdb out of alu, each entry of reservation station has its alu
    typedef struct {
        bit         valid [NUM_ALU_RS]; // indicating there is valid data on the bus 
        tag_t       tags [NUM_ALU_RS];   // the index of ROB entry to be updated
        rv32i_word  vals [NUM_ALU_RS];   // the register value 
    } alu_cdb_t;

    // the cdb out of memory unit
    typedef struct {
        bit         valid [NUM_LDST_RS]; // indicating there is valid data on the bus
        // bit         sw [NUM_LDST_RS];    // 1 for write, 0 for load
        tag_t       tag [NUM_LDST_RS];   // the index of ROB entry to be updated
        // logic [2:0] funct [NUM_LDST_RS]; // granularity of this memory operation
        rv32i_word  addr [NUM_LDST_RS];  // the address to store, not used for load
        rv32i_word  val [NUM_LDST_RS];   // the value to store or the loaded data
    } mem_cdb_t;

    typedef struct packed {
        bit         valid;
        tag_t       tag;
        rv32i_word  val; // pc + 4
        bit         correct_predict; // 1 for correct
        rv32i_word  pc_next; // correct pc_next
    } jalr_cdb_t;

endpackage


`endif