module alurs_tb ();

    /* intermediate variables */
    logic       clk;
    logic       rst;
    logic       flush;  /* basically the same as rst */ 
    alu_rs_itf  alu_itf();
    rob_out_t   rob_data;
    alu_cdb_t   alu_res;


    always #5 clk = (clk === 1'b0);
    default clocking tb_clk @(negedge clk); endclocking

    alu_rs dut(.*);

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

    task push_entry(input rv32i_word Vj, input rv32i_word Vk, input tag_t Qj, input tag_t Qk,
        input alu_ops op, input tag_t dest);
        alu_itf.valid   <= 1'b1;
        alu_itf.Vj      <= Vj;
        alu_itf.Vk      <= Vk;
        alu_itf.Qj      <= Qj;
        alu_itf.Qk      <= Qk;
        alu_itf.alu_op  <= op;
        alu_itf.dest    <= dest;
        @(tb_clk);
        alu_itf.valid   <= 1'b0;
        @(tb_clk);
    endtask

    task check_equity(input rv32i_word x, input rv32i_word y);
        assert (x == y) 
        else   $error("Expected 0x%0d, got 0x%0d\n", x, y);
    endtask

    task set_rob(input logic [2:0] index, input rv32i_word value);
        rob_data.ready[index]   <= 1'b1;
        rob_data.vals[index]    <= value;
        @(tb_clk);
    endtask

    task reset_rob(input logic [2:0] index);
        rob_data.ready[index]   <= 1'b0;
        @(tb_clk);
    endtask

    /* intermediate variables */
    rv32i_word v1, v2;

    initial begin
        /* dump the simulation results */
        $dumpfile("alurs_tb.vcd");
        $dumpvars(0, alurs_tb);

        $display("\nStarting ALU_RS Test");

        reset();
        for (int i = 0; i < ROB_DEPTH+1; ++i) begin
            reset_rob(i);
        end

        /* test 1: execute complete operation */
        $display("\nTest 1 starts\n");
        v1 = $urandom_range(500);
        v2 = $urandom_range(500);
        push_entry(v1, v2, 0, 0, alu_add, 1);
        check_equity(v1 + v2, alu_res.vals[0]); /* check operation result */
        check_equity(1, alu_res.tags[0]);   /* check  */
        check_equity(1, alu_res.valid[0]);
        check_equity(0, dut.busy[0]);

        push_entry(v1, 3, 0, 0, alu_sll, 2);
        check_equity(v1 << 3, alu_res.vals[0]); 
        check_equity(2, alu_res.tags[0]);
        check_equity(1, alu_res.valid[0]);
        check_equity(0, dut.busy[0]);

        /* test 2: push multiple entries */
        $display("\nTest 2 starts\n");
        for (int i = 0; i < NUM_ALU_RS; ++i) begin
            push_entry(v1, v2, i+1, 0, alu_add, i+1);
            check_equity(1, dut.busy[i]);
            check_equity(i+1, dut.dest[i]);
        end

        /* Test 3: pop out one entry, then push one */
        $display("\nTest 3 starts\n");
        v1 = $urandom_range(500);
        set_rob(3, v1);  /* the 3rd entry will be ready to compute */
        check_equity(0, dut.Qj[2]); /* test timing: Qj is already 0 at this moment */
        reset_rob(3);
        // @(tb_clk);
        check_equity(v1 + v2, alu_res.vals[2]); /* the operation would be v1+v2 */
        check_equity(3, alu_res.tags[2]);
        check_equity(1, alu_res.valid[2]);
        @(tb_clk);
        check_equity(0, dut.busy[2]);   /* entry should not be busy now */
        check_equity(0, alu_res.valid[2]);
        check_equity(2, dut.empty_index);
        push_entry(v1, v2, 3, 0, alu_add, 3);

        /* Test 4: pop entries in reverse order */
        $display("\nTest 4 starts\n");
        for (int i = NUM_ALU_RS-1; i >= 0; --i) begin
            v1 = $urandom_range(500);
            set_rob(i+1, v1);
            reset_rob(i+1);
            check_equity(1, alu_res.valid[i]);  /* check output valid */
            check_equity(v1+v2, alu_res.vals[i]); /* check computation result */
            check_equity(i+1, alu_res.tags[i]);   /* check destination */
            @(tb_clk);
            check_equity(0, dut.busy[i]);
            check_equity(i, dut.empty_index);
        end

        finish();

    end
    
endmodule