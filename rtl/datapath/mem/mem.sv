module mem
    import tartaruga_pkg::*;
(
    input logic clk_i,
    input logic rstn_i,
    input exe_to_mem_t exe_to_mem_i,
    output mem_to_wb_t mem_to_wb_o,
    output stall_o
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

    logic sb_full;

    store_buffer store_buffer_inst (
        .clk_i(clk_i),
        .rstn_i(rstn_i),
        .exe_to_mem_i(exe_to_mem_i),
        .data_i(exe_to_mem_i.data_rs2),
        .addr_i(exe_to_mem_i.result),
        .valid_i(exe_to_mem_i.valid && exe_to_mem_i.instr.store_to_mem),
        .req_valid_o(),
        .req_ready_i(),
        .addr_o(dmem_addr),
        .data_wr_o(dmem_data_wr),
        .rsp_valid_i(),
        .rsp_ready_o(),
        .store_buffer_commit_i(1'b0), // Not used in this design
        .store_buffer_idx_commit_i('0), // Not used in this design
        .store_buffer_discard_i(1'b0), // Not used in this design
        .store_buffer_idx_discard_i('0), // Not used in this design
        .full_o(sb_full)
    );

    dcache dcache_inst (
        .clk_i(clk_i),
        .rstn_i(rstn_i),
        .addr_i(),
        .data_wr_i(),
        .we_i(),
        .valid_i(),
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
    assign mem_to_wb_o.valid = exe_to_mem_i.valid &&
                              (((exe_to_mem_i.instr.wb_origin != MEM) && !exe_to_mem_i.instr.store_to_mem) || dcache_ready);
    assign mem_to_wb_o.branch_taken = exe_to_mem_i.branch_taken;
    assign mem_to_wb_o.branched_pc = (exe_to_mem_i.branch_taken == 1'b1) ?
                                    exe_to_mem_i.result : '0;

    assign stall_o = sb_full;

    always_comb begin
        case (exe_to_mem_i.instr.wb_origin)
            ALU: begin
                mem_to_wb_o.result = exe_to_mem_i.result;
            end
            MEM: begin
                mem_to_wb_o.result = dcache_data_rd;
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
