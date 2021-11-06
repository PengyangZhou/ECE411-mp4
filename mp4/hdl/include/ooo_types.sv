/* add customized types here if necessary */

`ifndef OOO_TYPES_SV
`define OOO_TYPES_SV

package ooo_types;

    import rv32i_types::*;

    parameter int INST_QUEUE_DEPTH = 6;
    parameter int ROB_DEPTH = 6;
    parameter int NUM_ALU_RS  = 5;
    parameter int NUM_CMP_RS  = 3;
    parameter int NUM_LDST_RS = 3;

    typedef logic [3:0] tag_t;
    
    typedef enum logic [1:0] { 
        REG = 2'b00, 
        ST  = 2'b01, 
        BR  = 2'b10
    } op_type_t;

    typedef struct {
        tag_t       tag_ready;          // the valid ROB entry number to put, 0 for no empty space
        bit         ready [ROB_DEPTH];  // set high if the entry is ready to commit
        rv32i_word  vals [ROB_DEPTH];   // values for each destination
    } rob_out_t;

    typedef struct packed {
        bit         valid;       /* indicating there is valid data on the bus */
        bit         br_pred_res; /* signal from CMP to ROB. 1 means prediction was true. */
        tag_t       tag;
        rv32i_word  val;
    } cmp_cdb;

    // the cdb out of alu
    typedef struct packed {
        bit         valid; // indicating there is valid data on the bus 
        tag_t       tag;   // the index of ROB entry to be updated
        rv32i_word  val;   // the register value 
    } alu_cdb;

    // the cdb out of memory unit
    typedef struct packed {
        bit         valid; // indicating there is valid data on the bus
        bit         sw;    // 1 for store, 0 for load
        tag_t       tag;   // the index of ROB entry to be updated
        rv32i_word  addr;  // the address to store, not used for load
        rv32i_word  val;   // the value to store or the loaded data
    } mem_cdb;

endpackage


`endif