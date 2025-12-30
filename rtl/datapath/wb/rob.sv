module rob
    import tartaruga_pkg::*;
(
    input  logic         clk_i,
    input  logic         rstn_i,
    `ifdef TB
    input logic flush_i,
    `endif

    // Data from decode
    input logic          valid_decode_i,
    input bus32_t        pc_i,
    input instruction_t  instr_i,
    input reg_addr_t     rd_addr_i,
    input logic          write_enable_i,
    input logic          store_to_mem_i,

    output rob_idx_t     rob_entry_alloc_o,

    // Data from wb
    input rob_idx_t      rob_entry_commit_i,
    input logic          valid_wb_i,
    input bus32_t        result_i,
    input bus32_t        new_pc_i,
    input logic          branch_taken_i,

    // Commit output
    output logic         commit_valid_o,
    output bus32_t       commit_pc_o,
    output instruction_t commit_instr_o,
    output reg_addr_t    commit_rd_addr_o,
    output bus32_t       commit_result_o,
    output logic         commit_write_enable_o,
    output logic         commit_store_to_mem_o,
    output bus32_t       commit_new_pc_o,
    output logic         commit_branch_taken_o,

    output logic         rob_full_o,

    input  reg_addr_t     rs1_addr_i,
    output logic          hazard_rs1_o,
    output rob_idx_t      rob_entry_rs1_o,
    output logic          completed_rs1_o,
    output bus32_t        result_rs1_o,

    input  reg_addr_t     rs2_addr_i,
    output logic          hazard_rs2_o,
    output rob_idx_t      rob_entry_rs2_o,
    output logic          completed_rs2_o,
    output bus32_t        result_rs2_o
);

    rob_entry_t rob_q [ROB_SIZE-1:0];
    rob_entry_t rob_d [ROB_SIZE-1:0];
    rob_idx_t   head_ptr_q, head_ptr_d;
    rob_idx_t   tail_ptr_q, tail_ptr_d;

    assign rob_entry_alloc_o = tail_ptr_q;
    assign rob_full_o = (((tail_ptr_q + 1) % ROB_SIZE) == head_ptr_q) && rob_q[head_ptr_q].valid; // Full when next tail equals head and head is valid

    logic found_hazard_rs1;
    logic found_hazard_rs2;

    always_comb begin
        for (int i = 0; i < ROB_SIZE; ++i) begin
            rob_d[i] = rob_q[i]; // Default: no change
        end

        // New data from decode
        if (valid_decode_i) begin
            rob_d[tail_ptr_q].valid         = 1'b1;
            rob_d[tail_ptr_q].pc            = pc_i;
            rob_d[tail_ptr_q].instr         = instr_i;
            rob_d[tail_ptr_q].addr_rd       = rd_addr_i;
            rob_d[tail_ptr_q].write_enable  = write_enable_i;
            rob_d[tail_ptr_q].store_to_mem  = store_to_mem_i;
            rob_d[tail_ptr_q].completed     = 1'b0; // Just in case a previous moment it was completed and flushed

            tail_ptr_d = (tail_ptr_q + 1) % ROB_SIZE;
        end else begin
            tail_ptr_d = tail_ptr_q;
        end

        // Update from wb
        if (valid_wb_i && rob_q[rob_entry_commit_i].valid) begin
            rob_d[rob_entry_commit_i].completed    = 1'b1;
            rob_d[rob_entry_commit_i].result       = result_i;
            rob_d[rob_entry_commit_i].new_pc       = new_pc_i;
            rob_d[rob_entry_commit_i].branch_taken = branch_taken_i;
        end

        // Commit logic
        if (rob_q[head_ptr_q].valid && rob_q[head_ptr_q].completed) begin
            commit_valid_o           = 1'b1;
            commit_pc_o              = rob_q[head_ptr_q].pc;
            commit_instr_o           = rob_q[head_ptr_q].instr;
            commit_rd_addr_o         = rob_q[head_ptr_q].addr_rd;
            commit_result_o          = rob_q[head_ptr_q].result;
            commit_write_enable_o    = rob_q[head_ptr_q].write_enable;
            commit_store_to_mem_o    = rob_q[head_ptr_q].store_to_mem;
            commit_new_pc_o          = rob_q[head_ptr_q].new_pc;
            commit_branch_taken_o    = rob_q[head_ptr_q].branch_taken;
            rob_d[head_ptr_q].valid    = 1'b0; // Mark entry as free

            head_ptr_d               = (head_ptr_q + 1) % ROB_SIZE;
        end else begin
            commit_valid_o = 1'b0;
            commit_pc_o = '0;
            commit_instr_o = '0;
            commit_rd_addr_o = '0;
            commit_result_o = '0;
            commit_write_enable_o = 1'b0;
            commit_store_to_mem_o = 1'b0;
            commit_new_pc_o = '0;
            commit_branch_taken_o = 1'b0;

            head_ptr_d = head_ptr_q;
        end

        // Branch taken -> flush ROB entries when the branch is commited
        `ifdef TB
        if ((rob_q[head_ptr_q].valid && rob_q[head_ptr_q].completed && rob_q[head_ptr_q].branch_taken) || flush_i) begin
        `else
        if (rob_q[head_ptr_q].valid && rob_q[head_ptr_q].completed && rob_q[head_ptr_q].branch_taken) begin
        `endif
            for (int i = 0; i < ROB_SIZE; ++i) begin
                rob_d[i].valid      = 1'b0;
            end
            head_ptr_d = '0;
            tail_ptr_d = '0;
        end

        // Hazard detection
        hazard_rs1_o     = 1'b0;
        rob_entry_rs1_o  = '0;
        completed_rs1_o  = 1'b0;
        result_rs1_o     = '0;
        hazard_rs2_o     = 1'b0;
        rob_entry_rs2_o  = '0;
        completed_rs2_o  = 1'b0;
        result_rs2_o     = '0;

        found_hazard_rs1 = 1'b0;
        found_hazard_rs2 = 1'b0;

        for (int i = (tail_ptr_q - 1)%ROB_SIZE; i != tail_ptr_q; i = (i - 1 + ROB_SIZE)%ROB_SIZE) begin
            // tail_ptr_q - 1 is the last allocated entry
            // We go backwards to find the most recent valid instruction that writes to the same register
            // As the currently writing instruction will go to the tail_ptr_q position we stop at tail_ptr_q + 1
            if (rob_q[i].valid) begin
                if (rob_q[i].addr_rd == rs1_addr_i && rob_q[i].write_enable && rob_q[i].addr_rd != 0 && ~found_hazard_rs1) begin
                    hazard_rs1_o    = 1'b1;
                    rob_entry_rs1_o = i;
                    completed_rs1_o = rob_q[i].completed;
                    result_rs1_o    = rob_q[i].result;
                    found_hazard_rs1 = 1'b1;
                    //break;
                end
            end
        end

        for (int i = (tail_ptr_q - 1)%ROB_SIZE; i != tail_ptr_q; i = (i - 1 + ROB_SIZE)%ROB_SIZE) begin
            if (rob_q[i].valid) begin
                if (rob_q[i].addr_rd == rs2_addr_i && rob_q[i].write_enable && rob_q[i].addr_rd != 0 && ~found_hazard_rs2) begin
                    hazard_rs2_o    = 1'b1;
                    rob_entry_rs2_o = i;
                    completed_rs2_o = rob_q[i].completed;
                    result_rs2_o    = rob_q[i].result;
                    found_hazard_rs2 = 1'b1;
                    //break;
                end
            end
        end
    end

    always_ff @(negedge rstn_i, posedge clk_i) begin
        if (~rstn_i) begin
            head_ptr_q <= '0;
            tail_ptr_q <= '0;
            for (int i = 0; i < ROB_SIZE; i++) begin
                rob_q[i].valid      <= 1'b0;
                rob_q[i].completed  <= 1'b0;
                rob_q[i].pc         <= '0;
                rob_q[i].instr      <= '0;
                rob_q[i].addr_rd    <= '0;
                rob_q[i].write_enable <= 1'b0;
                rob_q[i].store_to_mem <= 1'b0;
                rob_q[i].result     <= '0;
                rob_q[i].new_pc     <= '0;
                rob_q[i].branch_taken <= 1'b0;
            end
        end else begin
            head_ptr_q <= head_ptr_d;
            tail_ptr_q <= tail_ptr_d;
            for (int i = 0; i < ROB_SIZE; i++) begin
                rob_q[i] <= rob_d[i];
            end
        end
    end
endmodule
