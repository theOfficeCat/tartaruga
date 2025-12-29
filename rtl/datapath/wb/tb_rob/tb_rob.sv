module tb_rob;
    import tartaruga_pkg::*;

    logic clk_i;
    logic rstn_i;
    logic flush_i;

    logic valid_decode_i;
    bus32_t pc_i;
    instruction_t instr_i;
    reg_addr_t rd_addr_i;
    logic write_enable_i;
    logic store_to_mem_i;

    rob_idx_t rob_entry_alloc_o;

    rob_idx_t rob_entry_commit_i;
    logic valid_wb_i;
    bus32_t result_i;
    bus32_t new_pc_i;
    logic branch_taken_i;

    logic commit_valid_o;
    bus32_t commit_pc_o;
    instruction_t commit_instr_o;
    reg_addr_t commit_rd_addr_o;
    bus32_t commit_result_o;
    logic commit_write_enable_o;
    logic commit_store_to_mem_o;
    bus32_t commit_new_pc_o;
    logic commit_branch_taken_o;

    logic rob_full_o;

    logic rs1_addr_i;
    logic rs2_addr_i;

    rob_idx_t rob_entry_hazard_rs1;
    logic hazard_rob_rs1;
    logic completed_hazard_rs1;
    bus32_t result_hazard_rs1;

    rob_idx_t rob_entry_hazard_rs2;
    logic hazard_rob_rs2;
    logic completed_hazard_rs2;
    bus32_t result_hazard_rs2;

    rob dut (
        .clk_i(clk_i),
        .rstn_i(rstn_i),
        .flush_i(flush_i),
        .valid_decode_i(valid_decode_i),
        .pc_i(pc_i),
        .instr_i(instr_i),
        .rd_addr_i(rd_addr_i),
        .write_enable_i(write_enable_i),
        .store_to_mem_i(store_to_mem_i),
        .rob_entry_alloc_o(rob_entry_alloc_o),
        .rob_entry_commit_i(rob_entry_commit_i),
        .valid_wb_i(valid_wb_i),
        .result_i(result_i),
        .new_pc_i(new_pc_i),
        .branch_taken_i(branch_taken_i),
        .commit_valid_o(commit_valid_o),
        .commit_pc_o(commit_pc_o),
        .commit_instr_o(commit_instr_o),
        .commit_rd_addr_o(commit_rd_addr_o),
        .commit_result_o(commit_result_o),
        .commit_write_enable_o(commit_write_enable_o),
        .commit_store_to_mem_o(commit_store_to_mem_o),
        .commit_new_pc_o(commit_new_pc_o),
        .commit_branch_taken_o(commit_branch_taken_o),
        .rob_full_o(rob_full_o),
        .rs1_addr_i(rs1_addr_i),
        .hazard_rs1_o(hazard_rob_rs1),
        .rob_entry_rs1_o(rob_entry_hazard_rs1),
        .completed_rs1_o(completed_hazard_rs1),
        .result_rs1_o(result_hazard_rs1),
        .rs2_addr_i(rs2_addr_i),
        .hazard_rs2_o(hazard_rob_rs2),
        .rob_entry_rs2_o(rob_entry_hazard_rs2),
        .completed_rs2_o(completed_hazard_rs2),
        .result_rs2_o(result_hazard_rs2)
    );

    initial clk_i = 0;
    always #5 clk_i = ~clk_i;

    initial begin
        $dumpfile("wave.fst");
        $dumpvars(0, tb_imem_wrapper);

        rstn_i = 0;

        flush_i = 0;
        valid_decode_i = 0;
        pc_i = '0;
        instr_i = '0;
        rd_addr_i = '0;
        write_enable_i = 0;
        store_to_mem_i = 0;
        rob_entry_commit_i = '0;
        valid_wb_i = 0;
        result_i = '0;
        new_pc_i = '0;
        branch_taken_i = 0;
        rs1_addr_i = 0;
        rs2_addr_i = 0;

        #20;
        rstn_i = 1;

        @(posedge clk_i);

        @(negedge clk_i);
        valid_decode_i = 1;
        pc_i = 32'h0000_0004;
        instr_i = 32'h0000_0013; // NOP
        rd_addr_i = 5'd1;
        write_enable_i = 1;
        store_to_mem_i = 0;

        @(negedge clk_i);
        valid_decode_i = 0;
        pc_i = '0;
        instr_i = '0;
        rd_addr_i = '0;
        write_enable_i = 0;
        store_to_mem_i = 0;

        @(posedge clk_i);

        @(negedge clk_i);
        rob_entry_commit_i = '0; // Entry received previously if all is correct
        valid_wb_i = 1;
        result_i = 32'hDEAD_BEEF;
        new_pc_i = 32'h0000_0008;
        branch_taken_i = 0;

        @(negedge clk_i);
        valid_decode_i = 1;
        pc_i = 32'h0000_0004;
        instr_i = 32'h0000_0013; // NOP
        rd_addr_i = 5'd1;
        write_enable_i = 1;
        store_to_mem_i = 0;

        @(negedge clk_i);
        @(negedge clk_i);
        valid_decode_i = 0;

        rob_entry_commit_i = 4'h2;
        valid_wb_i = 1;
        result_i = 32'hCAFE_BABE;
        new_pc_i = 32'h0000_000C;
        branch_taken_i = 0;
        @(negedge clk_i);
        @(negedge clk_i);
        @(negedge clk_i);
        rob_entry_commit_i = 4'h1;
        valid_wb_i = 1;
        result_i = 32'hFEED_FACE;
        new_pc_i = 32'h0000_0010;
        branch_taken_i = 0;
        @(negedge clk_i);
        @(negedge clk_i);
        @(negedge clk_i);
        @(negedge clk_i);
        @(negedge clk_i);
        @(negedge clk_i);
        @(negedge clk_i);
        @(negedge clk_i);
        @(negedge clk_i);
        flush_i = 1;
        @(negedge clk_i);
        @(negedge clk_i);


        repeat (20) @(posedge clk_i);

        $finish;
    end
endmodule
