/* This is the Comparator Reservation Station */

module cmp_rs (
    input logic         clk,
    input logic         rst,
    input logic         flush,
    /* port from decoder */
    cmp_rs_itf.cmp_rs   cmp_itf,
    /* port from ROB */
    input rob_out_t     rob_data,
    /* port to CDB */
    output cmp_cdb_t    cmp_res
);

    /* RS entry fields */

    /* intermediate variables */

    /* Your logic here */
    
endmodule