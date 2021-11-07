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
    logic        load_tag;
    tag_t        tag_out;
    rv32i_reg    rd_out;
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
    rob_out_t    rob_data;
    /* port to RSs */
    alu_rs_itf  alu_itf();
    cmp_rs_itf  cmp_itf();
    lsb_rs_itf  lsb_itf();
    
    logic [31:0] regs [32];
    logic [4:0]  tags [32];

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
        /* check if shift signal is sent to instruction queue */
        assert (shift == 1'b1)
        else $error("Shift is not asserted.\n");
        valid_in    <= 1'b0;
        @(tb_clk);
    endtask

    /* V and Q are acutal results. */
    task check_VQ(input rv32i_reg reg_index, input rv32i_word V, input tag_t Q);
        if(tags[reg_index] == 0)begin
            assert (V == regs[reg_index]) 
            else $error("reg %0d, Expected 0x%0h, got 0x%0h\n", reg_index, regs[reg_index], V);
        end else if(rob_data.ready[tags[reg_index]])begin
            assert (V == rob_data.vals[tags[reg_index]]) 
            else $error("reg %0d, Expected 0x%0h, got 0x%0h\n", reg_index, rob_data.vals[tags[reg_index]], V);
        end else begin
            assert (Q == tags[reg_index]) 
            else $error("reg %0d, Expected 0x%0h, got 0x%0h\n", reg_index, tags[reg_index], Q);
        end
    endtask

    task check_imm(input logic [11:0] imm_expect, input logic [11:0] imm_got);
        assert (imm_expect == imm_got) 
        else $error("Expected 0x%0h, got 0x%0h\n", imm_expect, imm_got);
    endtask

    task check_tagupdate(input rv32i_reg rd);
        assert (tag_out == rob_data.tag_ready && rd_out == rd && load_tag == 1'b1)
        else $error("Tag update is not right.\ntag_out:%0d, rd_out:%0d, load_tag:%0d\n", tag_out, rd_out, load_tag);
    endtask

    initial begin
        /* initialize regfile */
        for (int i = 0; i < 32; ++i) begin
            regs[i] = $urandom();
            tags[i] = $urandom_range(5); /* range [0, 5] */
            // $display("regs[%0d]: %0h, tags[%0d]: %0h", i, regs[i], i, tags[i]);
        end
        /* initialize ROB */
        for (int i = 0; i < 6; ++i) begin
            rob_data.vals[i] = $urandom();
            rob_data.ready[i] = $urandom_range(1);
        end
        rob_data.tag_ready = 3;
    end

    always_comb begin : regfile
        reg_Qj = tags[rs1];
        reg_Qk = tags[rs2];
        reg_Vj = regs[rs1];
        reg_Vk = regs[rs2];
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
        check_VQ(1, alu_itf.Vj, alu_itf.Qj);
        check_VQ(2, alu_itf.Vk, alu_itf.Qk);
        check_tagupdate(3);

        send_inst(32'h004120b3); /* slt x1,x2,x4 */
        check_VQ(2, cmp_itf.Vj, cmp_itf.Qj);
        check_VQ(4, cmp_itf.Vk, cmp_itf.Qk);
        check_tagupdate(1);

        send_inst(32'h00508093); /* addi x1,x1,5 */
        check_VQ(1, alu_itf.Vj, alu_itf.Qj);
        check_imm(5, alu_itf.Vk);
        check_tagupdate(1);

        send_inst(32'h00612093); /* slti x1,x2,6 */
        check_VQ(2, cmp_itf.Vj, cmp_itf.Qj);
        check_imm(6, cmp_itf.Vk);
        check_tagupdate(1);

        send_inst(32'h0050a103); /* lw x2,5(x1) */
        check_VQ(1, lsb_itf.Vj, lsb_itf.Qj);
        check_imm(5, lsb_itf.A);
        check_tagupdate(2);

        send_inst(32'h00411323); /* sh x4,6(x2) */
        check_VQ(2, lsb_itf.Vj, lsb_itf.Qj);
        check_VQ(4, lsb_itf.Vk, lsb_itf.Qk);
        check_imm(6, lsb_itf.A);
        assert (load_tag == 1'b0); /* don't need to load tag */

        /* TODO: test branch and jal(r) */

        finish();
    end
    
endmodule