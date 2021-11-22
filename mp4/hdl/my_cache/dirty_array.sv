import cache_types::*;  

/* This module stores the dirty bit of each cacheline */
module dirty_array (
    input logic clk,
    input logic rst,
    input logic write,  /* don't need read because always reading */
    input logic wayid,
    input index_t index,
    input logic dirty_in,
    output logic dirty_out
);

/* intermediate variables */
logic [1:0] array_write;
logic [1:0] dirty_out_;

array #(.s_index(cache_types::s_index), .width(1)) dirty_array_way0(
    .clk,
    .rst,
    .read(1'b1),
    .load(array_write[0]),
    .rindex(index),
    .windex(index),
    .datain(dirty_in),
    .dataout(dirty_out_[0])
);

array #(.s_index(cache_types::s_index), .width(1)) dirty_array_way1(
    .clk,
    .rst,
    .read(1'b1),
    .load(array_write[1]),
    .rindex(index),
    .windex(index),
    .datain(dirty_in),
    .dataout(dirty_out_[1])
);

always_comb begin
    /* decide which sub-array to write to */
    case (wayid)
        1'b0: begin
            array_write[0] = write;
            array_write[1] = 1'b0;
            dirty_out = dirty_out_[0];
        end
        1'b1: begin
            array_write[0] = 1'b0;
            array_write[1] = write;
            dirty_out = dirty_out_[1];
        end
        default: ;
    endcase
end
    
endmodule