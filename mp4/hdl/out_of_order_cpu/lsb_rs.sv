/* This is the Load/Store Buffer */

module lsb_rs (
    input logic         clk,
    input logic         rst,
    input logic         flush,
    /* port from decoder */
    lsb_rs_itf.lsb_rs   lsb_itf,
    /* port from ROB */
    input rob_out_t     rob_data,
    /* port to CDB */
    output mem_cdb_t    mem_res  /* maybe change to lsb_res someday? */
);

    /* RS entry fields */

    /* intermediate variables */

    /* Your logic here */
    
endmodule