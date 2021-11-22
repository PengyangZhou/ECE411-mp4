import cache_types::*;  

/* this module stores the tag info */
module tag_array (
    input logic clk,
    input logic rst,
    input logic write,
    input logic wayid,
    input index_t index,
    input ctag_t tag_in,
    output ctag_t tag_out [2],
    output ctag_t tag_evict  /* the tag of the cacheline that we want to evict */
);

/* intermediate variables */
logic [1:0] array_write;

array #(.s_index(cache_types::s_index), .width(cache_types::s_tag)) tag_array_way0(
    .clk,
    .rst,
    .read(1'b1),
    .load(array_write[0]),
    .rindex(index),
    .windex(index),
    .datain(tag_in),
    .dataout(tag_out[0])
);

array #(.s_index(cache_types::s_index), .width(cache_types::s_tag)) tag_array_way1(
    .clk,
    .rst,
    .read(1'b1),
    .load(array_write[1]),
    .rindex(index),
    .windex(index),
    .datain(tag_in),
    .dataout(tag_out[1])
);

always_comb begin
    /* decide which sub-array to write to */
    case (wayid)
        1'b0: begin
            array_write[0] = write;
            array_write[1] = 1'b0;
            tag_evict = tag_out[0];
        end
        1'b1: begin
            array_write[0] = 1'b0;
            array_write[1] = write;
            tag_evict = tag_out[1];
        end
        default: ;
    endcase
end
    
endmodule