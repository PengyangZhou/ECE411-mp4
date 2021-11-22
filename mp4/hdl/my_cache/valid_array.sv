import cache_types::*;  

/* This module stores the valid bit of each cacheline */
module valid_array (
    input logic clk,
    input logic rst,
    input logic write,  /* don't need read because always reading */
    input logic wayid,  /* only for writing */
    input index_t index,
    output logic [1:0] valid_out
);

/* intermediate variables */
logic [1:0] array_write;

array #(.s_index(cache_types::s_index), .width(1)) valid_array_way0(
    .clk,
    .rst,
    .read(1'b1),
    .load(array_write[0]),
    .rindex(index),
    .windex(index),
    .datain(1'b1),
    .dataout(valid_out[0])
);

array #(.s_index(cache_types::s_index), .width(1)) valid_array_way1(
    .clk,
    .rst,
    .read(1'b1),
    .load(array_write[1]),
    .rindex(index),
    .windex(index),
    .datain(1'b1),
    .dataout(valid_out[1])
);

always_comb begin
    /* decide which sub-array to write to */
    case (wayid)
        1'b0: begin
            array_write[0] = write;
            array_write[1] = 1'b0;
        end
        1'b1: begin
            array_write[0] = 1'b0;
            array_write[1] = write;
        end
        default: ;
    endcase
end
    
endmodule