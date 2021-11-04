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
    output rob_out_t rob_out,
    // port to regfile
    output logic load_tag,
    output logic load_val,
    output logic tag,
    output logic val,
    
    output logic flush
);

endmodule : reorder_buffer
