/* This is the Reorder Buffer for precise exception. */
module reorder_buffer #(
    NUM_ENTRY = 6
)
(
    input logic clk,
    input logic rst,
    // port from decoder
    input logic valid_in,
    input logic [1:0] op_type,
    input logic [31:0] dest,
    // port from CDB
    cdb_itf alu_res,
    cdb_itf cmp_res,
    cdb_itf mem_res,
    // port to decoder
    output logic ready,
    output logic Vj,
    output logic Vk,
    // port to regfile
    output logic tag,
    
    output logic flush
);

endmodule : reorder_buffer
