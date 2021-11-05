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
        tag_t       tag;  // the valid ROB entry number to put, 0 for no empty space
        bit         busy [ROB_DEPTH];  // high if the value is not available
        rv32i_word  vals [ROB_DEPTH];  // values for each destination
    } rob_out_t;

endpackage


`endif