`ifndef inst_queue_itf
`define inst_queue_itf

/* interface to use in testbench */
interface inst_queue_itf;

    import rv32i_types::*;
    
    bit clk, rst, valid_in, valid_out;
    bit flush, ready, br_pred_in, br_pred_out;
    rv32i_word inst_in, pc_in, pc_next_in;
    rv32i_word inst_out, pc_out, pc_next_out;

    task finish();
        repeat (100) @(posedge clk);
        $finish;
    endtask : finish

    always #5 clk = (clk === 1'b0);

endinterface //inst_queue_itf


`endif