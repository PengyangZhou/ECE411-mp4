/* add customized types here if necessary */

`ifndef OOO_TYPES_SV
`define OOO_TYPES_SV

package ooo_types
    parameter int NUM_ALU_RS  = 5;
    parameter int NUM_CMP_RS  = 3;
    parameter int NUM_LDST_RS = 3;

    typedef logic [3:0] tag_t;

    
endpackage


`endif