import cache_types::*;  

/* This module takes in valid and tag info from 2 sets to 
    decide whether it's a hit
 */
module hit_check (
    input logic [1:0] valid_in,
    input ctag_t tag_in,
    input ctag_t tag_array_in [2],
    output logic hit,
    output logic hit_wayid
);

always_comb begin
    if (tag_in == tag_array_in[0] && valid_in[0]) begin
        hit = 1'b1;
        hit_wayid = 1'b0;
    end else if (tag_in == tag_array_in[1] && valid_in[1]) begin
        hit = 1'b1;
        hit_wayid = 1'b1;
    end else begin
        hit = 1'b0;
        hit_wayid = 1'b0;
    end
end
    
endmodule