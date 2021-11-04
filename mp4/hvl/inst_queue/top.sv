// `include "inst_queue_itf.sv"

module testbench ();
    
    inst_queue_itf itf();

    instruction_queue dut(
        .clk        (itf.clk),
        .rst        (itf.rst),
        .flush      (itf.flush),
        .ready      (itf.ready),
        .valid_in   (itf.valid_in),
        .inst_in    (itf.inst_in),
        .pc_in      (itf.pc_in),
        .pc_next_in (itf.pc_next_in),
        .br_pred_in (itf.br_pred_in),
        .shift      (itf.shift),
        .valid_out  (itf.valid_out),
        .pc_out     (itf.pc_out),
        .pc_next_out(itf.pc_next_out),
        .inst_out   (itf.inst_out),
        .br_pred_out(itf.br_pred_out)
    );

    default clocking tb_clk @(negedge itf.clk); endclocking

    logic [96:0] data_out;
    assign data_out = {itf.pc_next_out, itf.pc_out, itf.br_pred_out, itf.inst_out};

    task reset();
        itf.rst <= 1'b1;
        repeat (5) @(tb_clk);
        itf.rst <= 1'b0;
        repeat (5) @(tb_clk);
    endtask

    task push(input logic [96:0] data);
        itf.valid_in    <= 1'b1;
        itf.inst_in     <= data[0+:32];
        itf.br_pred_in  <= data[32+:1];
        itf.pc_in       <= data[33+:32];
        itf.pc_next_in  <= data[65+:32];
        @(tb_clk);
        itf.valid_in    <= 1'b0;
        @(tb_clk);
    endtask

    task pop(output logic [96:0] val_out);
        itf.shift   <= 1'b1;
        val_out     <= data_out;
        @(tb_clk);
        itf.shift   <= 1'b0;
        @(tb_clk);
    endtask

    logic [96:0] test_data [7];
    logic [96:0] val_out;

    initial begin
        /* dump the simulation results */
        $dumpfile("inst_queue_tb.vcd");
        $dumpvars;

        $display("\nStarting Instructin Queue Test\n");

        reset();

        /* generate 7 random values */
        for (int i = 0; i < 7; ++i) begin
            test_data[i] = {$urandom(),$urandom(),$urandom()};
        end

        /* test1: push 6 entries */
        for (int i = 0; i < 6; ++i) begin
            push(test_data[i]);
        end

        /* test2: push entry when the queue is full */
        push(test_data[6]);

        /* test3: pop 6 entries */
        for (int i = 0; i < 6; ++i) begin
            pop(val_out);
            assert (val_out == test_data[i]) 
            else   $error("%0t TB: popped 0x%0h, expected 0x%0h", $time, val_out, test_data[i]);
        end

        /* test4: pop when the queue is empty */
        pop(val_out);

        /* test5: continuous and excessive push */
        $display("\nTest 5 Starts\n");
        for (int i = 0; i < 7; ++i) begin
            itf.valid_in    <= 1'b1;
            itf.inst_in     <= test_data[i][0+:32];
            itf.br_pred_in  <= test_data[i][32+:1];
            itf.pc_in       <= test_data[i][33+:32];
            itf.pc_next_in  <= test_data[i][65+:32];
            @(tb_clk);
        end
        itf.valid_in <= 1'b0;
        @(tb_clk);

        /* test6: continuous pop */
        $display("\nTest 6 Starts\n");
        for (int i = 0; i < 7; ++i) begin
            itf.shift   <= 1'b1;
            val_out     <= data_out;
            @(tb_clk);
            if(i != 6)begin 
                assert (val_out == test_data[i]) 
                    else   $error("%0t TB: popped 0x%0h, expected 0x%0h", $time, val_out, test_data[i]);
            end else begin
                assert (val_out == 'b0) 
                    else   $error("%0t TB: popped 0x%0h, expected 0x0", $time, val_out);
            end
        end
        itf.shift <= 1'b0;
        @(tb_clk);

        /* test7: push while pop */
        $display("\nTest 7 Starts\n");
        push(test_data[0]);
        push(test_data[1]);
        for (int i = 2; i < 7; ++i) begin
            /* push */
            itf.valid_in    <= 1'b1;
            itf.inst_in     <= test_data[i][0+:32];
            itf.br_pred_in  <= test_data[i][32+:1];
            itf.pc_in       <= test_data[i][33+:32];
            itf.pc_next_in  <= test_data[i][65+:32];
            /* pop */
            itf.shift   <= 1'b1;
            val_out     <= data_out;
            @(tb_clk);
            assert (val_out == test_data[i-2]) 
            else   $error("%0t TB: popped 0x%0h, expected 0x%0h", $time, val_out, test_data[i-2]);
        end


        itf.finish();
    end

endmodule : testbench
