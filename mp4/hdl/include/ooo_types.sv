/* add customized types here if necessary */

`ifndef OOO_TYPES_SV
`define OOO_TYPES_SV

package ooo_types;

    import rv32i_types::*;

    parameter int INST_QUEUE_DEPTH = 6;
    parameter int ROB_DEPTH   = 6;
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
        tag_t       tag_ready;            // the valid ROB entry number to put, 0 for no empty space
        bit         ready [ROB_DEPTH+1];  // set high if the entry is ready to commit
        rv32i_word  vals [ROB_DEPTH+1];   // values for each destination
    } rob_out_t;

    typedef struct packed {
        bit         valid;       /* indicating there is valid data on the bus */
        bit         br_pred_res; /* signal from CMP to ROB. 1 means prediction was true. */
        tag_t       tag;
        rv32i_word  val;
    } cmp_cdb_t;

    // the cdb out of alu, each entry of reservation station has its alu
    typedef struct {
        bit         valid [NUM_ALU_RS]; // indicating there is valid data on the bus 
        tag_t       tags [NUM_ALU_RS];   // the index of ROB entry to be updated
        rv32i_word  vals [NUM_ALU_RS];   // the register value 
    } alu_cdb_t;

    // the cdb out of memory unit
    typedef struct packed {
        bit         valid; // indicating there is valid data on the bus
        bit         sw;    // 1 for store, 0 for load
        tag_t       tag;   // the index of ROB entry to be updated
        logic [2:0] funct; // granularity of this memory operation
        rv32i_word  addr;  // the address to store, not used for load
        rv32i_word  val;   // the value to store or the loaded data
    } mem_cdb_t;

endpackage


`endif