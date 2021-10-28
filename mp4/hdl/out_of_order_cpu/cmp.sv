/* This is our comparator. Borrowed from mp2.*/
import rv32i_types::*;

module cmp
(
    input rv32i_word rs1_in,
    input rv32i_word mux_in,
    input branch_funct3_t cmpop,
    output logic br_en
);

always_comb
begin
    unique case (cmpop)
        beq:  br_en = (rs1_in == mux_in) ? 1'b1 : 1'b0;
        bne:  br_en = (rs1_in != mux_in) ? 1'b1 : 1'b0;
        blt:  br_en = (signed'(rs1_in) < signed'(mux_in)) ? 1'b1 : 1'b0;
        bge:  br_en = (signed'(rs1_in) >= signed'(mux_in)) ? 1'b1 : 1'b0;
        bltu: br_en = (unsigned'(rs1_in) < unsigned'(mux_in)) ? 1'b1 : 1'b0;
        bgeu: br_en = (unsigned'(rs1_in) >= unsigned'(mux_in)) ? 1'b1 : 1'b0;
        default: br_en = 1'b0;
    endcase
end

endmodule : cmp
