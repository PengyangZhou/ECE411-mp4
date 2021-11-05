module decoder_tb ();

    logic clk;
    logic rst;
    /* port from instruction queue */
    logic      valid_in;
    rv32i_word pc_in;
    rv32i_word pc_next_in;
    rv32i_word inst_in;
    logic      br_pred_in;
    /* port to instruction queue */
    logic     shift;
    /* port to regfile */
    rv32i_reg    rs1;
    rv32i_reg    rs2;
    /* port from regfile */
    tag_t         reg_Qj;
    tag_t         reg_Qk;
    rv32i_word    reg_Vj;
    rv32i_word    reg_Vk;
    /* port to ROB */
    logic        rob_valid; 
    op_type_t    rob_op;    
    rv32i_word   rob_dest;  
    /* port from ROB */
    logic         rob_ready;  
    logic  [31:0] rob_values [ROB_DEPTH]; 
    alu_rs_itf  alu_itf();
    cmp_rs_itf  cmp_itf();
    lsb_rs_itf  lsb_itf();

    always #5 clk = (clk === 1'b0);
    default clocking tb_clk @(negedge clk); endclocking

    decoder dut(.*);

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

    task send_inst(input rv32i_word inst);
        valid_in    <= 1'b1;
        pc_in       <= 0;
        pc_next_in  <= 0;
        inst_in     <= inst;
        br_pred_in  <= 1'b0;
        @(tb_clk);
    endtask

    always_comb begin : regfile
        reg_Qj = rs1;
        reg_Qk = rs2;
        reg_Vj = rs1;
        reg_Vk = rs2;
    end 
    
    initial begin
        /* dump the simulation results */
        $dumpfile("decoder_tb.vcd");
        $dumpvars;

        $display("\nStarting Decoder Test\n");

        reset();

        /* initialize ready signal */
        alu_itf.ready <= 1'b1;
        cmp_itf.ready <= 1'b1;
        lsb_itf.ready <= 1'b1;
        @(tb_clk);
        
        send_inst(32'h002081b3); /* add x3,x1,x2 */

        finish();
    end
    
endmodule