module mem
    import tartaruga_pkg::*;
(
    input logic clk_i,
    input logic rstn_i,
    input exe_to_mem_t exe_to_mem_i,
    output mem_to_wb_t mem_to_wb_o,
    output stall_o,

    input logic commited_store_buffer_i,
    input store_buffer_idx_t commited_store_buffer_idx_i,
    input logic [STORE_BUFFER_SIZE-1:0] discard_store_buffer_i
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

    logic is_load;
    assign is_load = (exe_to_mem_i.instr.wb_origin == MEM) && exe_to_mem_i.valid;

    logic is_store;
    assign is_store = exe_to_mem_i.instr.store_to_mem && exe_to_mem_i.valid;

    bus32_t dcache_addr;
    //assign dcache_addr = exe_to_mem_i.result;

    bus32_t dcache_wr_data;
    //assign dcache_wr_data = exe_to_mem_i.data_rs2;

    logic sb_ready;
    logic sb_rsp_valid;

    logic request_to_dcache;
    assign request_to_dcache = is_load || sb_rsp_valid;

    logic mem_we;
    assign mem_we = sb_rsp_valid;

    logic bypass_from_sb;
    bus32_t data_from_sb;

    logic is_collision;
    assign is_collision = is_load && sb_rsp_valid && !bypass_from_sb; // There is a load and the store buffer is storing at the same time

    bus32_t sb_out_addr;

    assign dcache_addr = sb_rsp_valid ? sb_out_addr : exe_to_mem_i.result;

    store_buffer store_buffer_inst (
        .clk_i(clk_i),
        .rstn_i(rstn_i),
        .data_i(exe_to_mem_i.data_rs2),
        .addr_i(exe_to_mem_i.result),
        .load_i(is_load),
        .bypass_o(bypass_from_sb),
        .data_rd_o(data_from_sb),
        .req_valid_i(is_store),
        .req_ready_o(sb_ready),
        .rsp_valid_o(sb_rsp_valid),
        .rsp_ready_i(dcache_ready),
        .addr_o(sb_out_addr),
        .data_wr_o(dcache_wr_data),
        .store_buffer_idx_o(mem_to_wb_o.store_buffer_idx),
        .store_buffer_commit_i(commited_store_buffer_i),
        .store_buffer_idx_commit_i(commited_store_buffer_idx_i),
        .store_buffer_discard_i(discard_store_buffer_i)
    );

    dcache dcache_inst (
        .clk_i(clk_i),
        .rstn_i(rstn_i),
        .addr_i(dcache_addr),
        .data_wr_i(dcache_wr_data),
        .we_i(mem_we),
        .valid_i(request_to_dcache),
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
        if (sb_rsp_valid && sb_out_addr == 32'h40000000) begin
            if (dcache_wr_data == 32'h1) begin
                $display("Execution succeeded");
                $finish();
            end
            else if (dcache_wr_data == 32'h2) begin
                $display("Execution failed");
                $finish();
            end
            else begin
                $display("Error");
                $finish();
            end
        end
        end

    assign mem_to_wb_o.instr = exe_to_mem_i.instr;

    logic valid_no_mem;
    logic valid_store;
    logic valid_load;

    assign valid_no_mem = exe_to_mem_i.valid && (exe_to_mem_i.instr.wb_origin != MEM) && exe_to_mem_i.instr.store_to_mem == 1'b0;
    assign valid_store  = exe_to_mem_i.valid && (exe_to_mem_i.instr.store_to_mem == 1'b1) && dcache_ready;

    //assign valid_load   = exe_to_mem_i.valid && (exe_to_mem_i.instr.wb_origin == MEM) && dcache_ready;

    logic valid_load_bypass;
    assign valid_load_bypass = exe_to_mem_i.valid && (exe_to_mem_i.instr.wb_origin == MEM) && bypass_from_sb;

    logic valid_load_dcache;
    assign valid_load_dcache = exe_to_mem_i.valid && (exe_to_mem_i.instr.wb_origin == MEM) && dcache_ready && !bypass_from_sb && !is_collision;

    assign valid_load = valid_load_bypass || valid_load_dcache;

    assign mem_to_wb_o.valid = valid_no_mem || valid_load || valid_store;
    assign mem_to_wb_o.branch_taken = exe_to_mem_i.branch_taken;
    assign mem_to_wb_o.branched_pc = (exe_to_mem_i.branch_taken == 1'b1) ?
                                    exe_to_mem_i.result : '0;

    assign stall_o = (is_load && !dcache_ready) || is_collision || (is_store && !sb_ready);

    always_comb begin
        case (exe_to_mem_i.instr.wb_origin)
            ALU: begin
                mem_to_wb_o.result = exe_to_mem_i.result;
            end
            MEM: begin
                if (valid_load_bypass) begin
                    mem_to_wb_o.result = data_from_sb;
                end
                else begin
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
