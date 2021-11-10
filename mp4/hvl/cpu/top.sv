/* This is the testbench for CPU */

module cpu_tb ();
    
    logic clk;
    logic rst;

    always #5 clk = (clk === 1'b0);
    default clocking tb_clk @(negedge clk); endclocking

    /* wires */
    logic mem_resp_i;
    rv32i_word mem_rdata_i;
    logic mem_read_i;
    logic mem_write_i;
    logic [3:0] mem_byte_enable_i;
    rv32i_word mem_address_i;
    rv32i_word mem_wdata_i;
    logic mem_resp_d;
    rv32i_word mem_rdata_d;
    logic mem_read_d;
    logic mem_write_d;
    logic [3:0] mem_byte_enable_d;
    rv32i_word mem_address_d;
    rv32i_word mem_wdata_d;

    /* instantiation */
    cpu dut(.*);

    /* task definitions */
    task reset();
        rst <= 1'b1;
        repeat (5) @(tb_clk);
        rst <= 1'b0;
        repeat(5) @(tb_clk);
    endtask 

    task finish();
        repeat (100) @(posedge clk);
        $finish;
    endtask : finish
    
endmodule