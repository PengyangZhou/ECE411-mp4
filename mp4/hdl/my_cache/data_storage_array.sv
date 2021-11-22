import cache_types::*;  

/* This module contain the content of cachelines */
module data_storage_array (
    input logic clk,
    input logic rst,
    input logic write,
    input logic wayid,
    input index_t index,
    input byte_en_t byte_enable,  /* only used for write */
    input cacheline_t data_in,
    output cacheline_t data_out
);

/* intermediate variables */
byte_en_t byte_enable_ [2];
cacheline_t data_out_ [2];

data_array #(.s_offset(5), .s_index(cache_types::s_index)) data_array_way0(
    .clk,
    .rst,
    .read(1'b1),
    .write_en(byte_enable_[0]),
    .rindex(index),
    .windex(index),
    .datain(data_in),
    .dataout(data_out_[0])
);

data_array #(.s_offset(5), .s_index(cache_types::s_index)) data_array_way1(
    .clk,
    .rst,
    .read(1'b1),
    .write_en(byte_enable_[1]),
    .rindex(index),
    .windex(index),
    .datain(data_in),
    .dataout(data_out_[1])
);

always_comb begin
    /* once the write_enable is set, the data array will start writing */
    if (write) begin
        case (wayid)
            1'b0: begin
                byte_enable_[0] = byte_enable;
                byte_enable_[1] = 'b0;
            end

            1'b1: begin
                byte_enable_[0] = 'b0;
                byte_enable_[1] = byte_enable;
            end
            default: ;
        endcase
    end else begin
        byte_enable_[0] = 'b0;
        byte_enable_[1] = 'b0;
    end

    /* select the right output */
    case (wayid)
        1'b0: data_out = data_out_[0];
        1'b1: data_out = data_out_[1];
        default: ;
    endcase
    
end
    
endmodule