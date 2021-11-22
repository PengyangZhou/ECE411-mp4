import cache_types::*;  

/* This module stores the lru bit of each set */
module lru_array (
    input logic clk,
    input logic rst,
    input logic write,  /* don't need read because always reading */
    input index_t index,
    input logic lru_in,
    output logic lru_out
);

array #(.s_index(cache_types::s_index), .width(1)) lru_array(
    .clk,
    .rst,
    .read(1'b1),
    .load(write),
    .rindex(index),
    .windex(index),
    .datain(lru_in),  /* THIS IS NOT RIGHT -> since we only have 2 ways, just flip the bit */
    .dataout(lru_out)
);
    
endmodule