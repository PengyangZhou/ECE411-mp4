import ooo_types::*;
import rv32i_types::*;

module regfile(
    input logic clk,
    input logic rst,
    input logic flush,
    // port from ROB
    input logic load_val,
    input rv32i_reg val_rd,             
    input rv32i_word val,
    input tag_t tag_from_rob,
    // port from decoder
    input rv32i_reg rs1,            
    input rv32i_reg rs2,
    input logic load_tag,
    input tag_t tag_from_decoder,
    input rv32i_reg tag_rd,
    // port to decoder
    output rv32i_word rs1_out,      
    output rv32i_word rs2_out,
    output tag_t t1_out,
    output tag_t t2_out
);

    rv32i_word reg_vals [32]; 
    tag_t reg_tags [32];

    always_ff @( posedge clk ) begin
        if (rst) begin
            for (int i = 0; i < 32; i++) begin
                reg_vals[i] <= '0;
                reg_tags[i] <= '0;
            end
        end else if (flush) begin
            for (int i = 0; i < 32; i++) begin
                reg_tags[i] <= '0;
            end
            if (load_val && (val_rd != 0)) begin
                // for jalr, if flush, still needs to store the rd
                reg_vals[val_rd] <= val; 
            end
        end else begin
            if (load_tag) begin
                // the situation happens when decoder adds a new entry in ROB
                // tag is the ROB new entry number, rd is the register to be calculated 
                reg_tags[tag_rd] <= tag_from_decoder;
            end
            if (load_val && (val_rd != 0)) begin
                // the situation happens when committing
                // each cycle updates a single register's value
                reg_vals[val_rd] <= val; 
                if ((reg_tags[val_rd] == tag_from_rob) && (!load_tag)) begin
                    // if the register tag is the same as the committed ROB entry number,
                    // clear the tag
                    reg_tags[val_rd] <= '0;
                end
                
            end
        end
    end

    always_comb begin
        // decoder tries to find value of rs1 and rs2
        rs1_out = (rs1 == 0) ? '0 : reg_vals[rs1];
        rs2_out = (rs2 == 0) ? '0 : reg_vals[rs2];
        t1_out = reg_tags[rs1];
        t2_out = reg_tags[rs2];
    end

endmodule : regfile
