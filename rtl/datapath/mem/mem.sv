module mem
    import tartaruga_pkg::*;
(
    input logic clk_i,
    input logic rstn_i,
    input exe_to_mem_t exe_to_mem_i,
    output mem_to_wb_t mem_to_wb_o,
    output stall_o,

    input logic   store_buffer_commit_i,
    input store_buffer_idx_t store_buffer_idx_commit_i,
    input logic [STORE_BUFFER_SIZE-1:0] store_buffer_discard_i
);

    bus32_t dcache_data_rd;
    logic dcache_ready;
    bus32_t dmem_addr;
    logic dmem_req_valid;
    logic dmem_req_ready;
    logic [127:0] dmem_data_line;
    logic dmem_we;
    bus32_t dmem_data_wr;
    logic dmem_rsp_valid;
    logic dmem_rsp_ready;
    bus32_t dmem_rsp_addr;

    logic is_mem_access;
    assign is_mem_access = (exe_to_mem_i.instr.wb_origin == MEM || exe_to_mem_i.instr.store_to_mem) && exe_to_mem_i.valid;

    logic mem_we;
    assign mem_we = exe_to_mem_i.instr.store_to_mem;

    logic sb_ready;

    bus32_t sb_data;
    bus32_t sb_addr;

    logic sb_rsp_valid;

    bus32_t dcache_addr, dcache_data_wr;
    logic dcache_we, dcache_valid;

    logic collision_detected;

    // Logic of selecting between store buffer and load (from exe) to use the dcache
    always_comb begin
        if (sb_rsp_valid) begin
            // Prioritize store buffer responses
            dcache_addr    = sb_addr;
            dcache_data_wr = sb_data;
            dcache_we      = 1'b1;
            dcache_valid   = 1'b1;
        end else if (is_mem_access && !mem_we) begin
            // Load from exe stage
            dcache_addr    = exe_to_mem_i.result;
            dcache_data_wr = '0;
            dcache_we      = 1'b0;
            dcache_valid   = 1'b1;
        end else begin
            // No memory access
            dcache_addr    = '0;
            dcache_data_wr = '0;
            dcache_we      = 1'b0;
            dcache_valid   = 1'b0;
        end

        // Detect collision: sb is sending data while load is requested
        collision_detected = sb_rsp_valid && is_mem_access && !mem_we;
    end

    //assign sb_ready_o = sb_ready;

    logic bypass_from_sb;
    bus32_t bypass_data_from_sb;

    store_buffer store_buffer_inst (
        .clk_i(clk_i),
        .rstn_i(rstn_i),
        .data_i(exe_to_mem_i.data_rs2),
        .addr_i(exe_to_mem_i.result),

        .load_i(exe_to_mem_i.valid && (exe_to_mem_i.instr.wb_origin == MEM)),
        .bypass_o(bypass_from_sb),
        .data_rd_o(bypass_data_from_sb),

        .req_valid_i(exe_to_mem_i.valid && exe_to_mem_i.instr.store_to_mem == 1'b1),
        .req_ready_o(sb_ready),
        .addr_o(sb_addr),
        .data_wr_o(sb_data),
        .rsp_valid_o(sb_rsp_valid),
        .rsp_ready_i(dcache_ready),
        .store_buffer_idx_o(mem_to_wb_o.store_buffer_idx),
        .store_buffer_commit_i(store_buffer_commit_i),
        .store_buffer_idx_commit_i(store_buffer_idx_commit_i),
        .store_buffer_discard_i(store_buffer_discard_i)
    );

    dcache dcache_inst (
        .clk_i(clk_i),
        .rstn_i(rstn_i),
        .addr_i(dcache_addr),
        .data_wr_i(dcache_data_wr),
        .we_i(dcache_we),
        .valid_i(dcache_valid),
        .data_rd_o(dcache_data_rd),
        .ready_o(dcache_ready),
        .mem_addr_o(dmem_addr),
        .mem_req_valid_o(dmem_req_valid),
        .mem_req_ready_i(dmem_req_ready),
        .mem_data_line_i(dmem_data_line),
        .mem_we_o(dmem_we),
        .mem_data_wr_o(dmem_data_wr),
        .mem_rsp_valid_i(dmem_rsp_valid),
        .mem_rsp_ready_o(dmem_rsp_ready),
        .mem_rsp_addr_i(dmem_rsp_addr)
    );

    dmem_wrapper dmem_wrapper_inst (
        .clk_i(clk_i),
        .rstn_i(rstn_i),
        .req_valid_i(dmem_req_valid),
        .req_ready_o(dmem_req_ready),
        .addr_i(dmem_addr),
        .we_i(dmem_we),
        .data_wr_i(dmem_data_wr),
        .rsp_valid_o(dmem_rsp_valid),
        .rsp_ready_i(dmem_rsp_ready),
        .rsp_mem_addr_o(dmem_rsp_addr),
        .data_line_o(dmem_data_line)
    );

    always_ff @(posedge clk_i) begin
        if (exe_to_mem_i.valid && mem_we && exe_to_mem_i.result == 32'h40000000) begin
            if (exe_to_mem_i.data_rs2 == 32'h1) begin
                $display("Execution succeeded at PC 0x%h", exe_to_mem_i.instr.pc);
                $finish();
            end
            else if (exe_to_mem_i.data_rs2 == 32'h2) begin
                $display("Execution failed at PC 0x%h", exe_to_mem_i.instr.pc);
                $finish();
            end
            else begin
                $display("Error at PC 0x%h", exe_to_mem_i.instr.pc);
                $finish();
            end
        end
    end

    assign mem_to_wb_o.instr = exe_to_mem_i.instr;
    //assign mem_to_wb_o.valid = exe_to_mem_i.valid &&
    //                          (((exe_to_mem_i.instr.wb_origin != MEM) && !exe_to_mem_i.instr.store_to_mem) || (dcache_ready && !collision_detected) );

    assign mem_to_wb_o.valid = exe_to_mem_i.valid && // Instruction is valid
                               ((exe_to_mem_i.instr.wb_origin == MEM) && ((dcache_ready && !collision_detected) || // Load instruction and dcache ready without collision
                                                                         (bypass_from_sb)) || // Load bypassed from store buffer
                               ((exe_to_mem_i.instr.store_to_mem && sb_ready)) || // Store instruction and store buffer ready
                               ((exe_to_mem_i.instr.wb_origin != MEM) && !exe_to_mem_i.instr.store_to_mem)); // Non-memory instruction


    assign mem_to_wb_o.branch_taken = exe_to_mem_i.branch_taken;
    assign mem_to_wb_o.branched_pc = (exe_to_mem_i.branch_taken == 1'b1) ?
                                    exe_to_mem_i.result : '0;

    assign stall_o = collision_detected || (exe_to_mem_i.instr.wb_origin == MEM && !dcache_ready);

    always_comb begin
        case (exe_to_mem_i.instr.wb_origin)
            ALU: begin
                mem_to_wb_o.result = exe_to_mem_i.result;
            end
            MEM: begin
                if (bypass_from_sb) begin
                    mem_to_wb_o.result = bypass_data_from_sb;
                end else begin
                    mem_to_wb_o.result = dcache_data_rd;
                end
            end
            PC_4: begin
                mem_to_wb_o.result = exe_to_mem_i.instr.pc + 4;
            end
            default: begin
                mem_to_wb_o.result = '0;
            end
        endcase
    end

endmodule
