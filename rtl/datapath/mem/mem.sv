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

    bus32_t dcache_wr_data;

    logic sb_ready;
    logic sb_rsp_valid;

    logic request_to_dcache;
    assign request_to_dcache = is_load || sb_rsp_valid;

    logic mem_we;
    assign mem_we = sb_rsp_valid;

    logic bypass_from_sb;
    bus32_t data_from_sb;

    logic is_collision;
    assign is_collision = is_load && sb_rsp_valid && !bypass_from_sb;

    bus32_t sb_out_addr;

    bus32_t virt_addr;
    assign virt_addr = sb_rsp_valid ? sb_out_addr : exe_to_mem_i.result;

    logic [19:0] phys_addr;
    logic dtlb_ready;
    logic dtlb_tlb_hit;
    logic dtlb_tlb_miss;
    
    logic dtlb_update;
    logic [19:0] dtlb_update_vpn;
    logic [19:0] dtlb_update_ppn;
    
    logic [31:0] rm4;
    logic [31:0] rm5;

    dtlb dtlb_inst (
        .clk_i(clk_i),
        .rstn_i(rstn_i),
        .valid_i(request_to_dcache),
        .virt_addr_i(virt_addr),
        .rm4_bit0_i(rm4[0]),
        .update_i(dtlb_update),
        .update_vpn_i(dtlb_update_vpn),
        .update_ppn_i(dtlb_update_ppn),
        .ready_o(dtlb_ready),
        .phys_addr_o(phys_addr),
        .tlb_hit_o(dtlb_tlb_hit),
        .tlb_miss_o(dtlb_tlb_miss)
    );
    
    logic ptw_mem_req_valid;
    bus32_t ptw_mem_req_addr;
    logic ptw_mem_req_ready;
    logic ptw_mem_rsp_valid;
    logic [127:0] ptw_mem_rsp_data;
    logic ptw_busy;
    
    ptw ptw_inst (
        .clk_i(clk_i),
        .rstn_i(rstn_i),
        .tlb_miss_i(dtlb_tlb_miss && request_to_dcache && !rm4[0]),
        .virt_addr_i(virt_addr),
        .rm5_i(rm5),
        .mem_req_valid_o(ptw_mem_req_valid),
        .mem_req_addr_o(ptw_mem_req_addr),
        .mem_req_ready_i(ptw_mem_req_ready),
        .mem_rsp_valid_i(ptw_mem_rsp_valid),
        .mem_rsp_data_i(ptw_mem_rsp_data),
        .tlb_update_o(dtlb_update),
        .update_vpn_o(dtlb_update_vpn),
        .update_ppn_o(dtlb_update_ppn),
        .ptw_busy_o(ptw_busy)
    );

    assign dcache_addr = {12'b0, phys_addr};

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
    
    logic dcache_mem_req_valid;
    bus32_t dcache_mem_req_addr;
    logic dcache_mem_req_ready;
    logic dcache_mem_rsp_valid;
    
    dcache dcache_inst (
        .clk_i(clk_i),
        .rstn_i(rstn_i),
        .addr_i(dcache_addr),
        .data_wr_i(dcache_wr_data),
        .we_i(mem_we),
        .valid_i(request_to_dcache && (rm4[0] || !dtlb_tlb_miss)),
        .data_rd_o(dcache_data_rd),
        .ready_o(dcache_ready),
        .mem_addr_o(dcache_mem_req_addr),
        .mem_req_valid_o(dcache_mem_req_valid),
        .mem_req_ready_i(dcache_mem_req_ready),
        .mem_data_line_i(dmem_data_line),
        .mem_we_o(dmem_we),
        .mem_data_wr_o(dmem_data_wr),
        .mem_rsp_valid_i(dcache_mem_rsp_valid),
        .mem_rsp_ready_o(dmem_rsp_ready),
        .mem_rsp_addr_i(dmem_rsp_addr)
    );
    
    logic ptw_req_pending;
    
    always_ff @(posedge clk_i or negedge rstn_i) begin
        if (!rstn_i) begin
            ptw_req_pending <= 1'b0;
            rm4 <= 32'h1;
            rm5 <= 32'h0;
        end else begin
            if (ptw_mem_req_valid && dmem_req_ready) begin
                ptw_req_pending <= 1'b1;
            end else if (dmem_rsp_valid) begin
                ptw_req_pending <= 1'b0;
            end
            
            if (exe_to_mem_i.valid && exe_to_mem_i.instr.store_to_mem) begin
                if (exe_to_mem_i.result == 32'h40000004) begin
                    rm4 <= exe_to_mem_i.data_rs2;
                end else if (exe_to_mem_i.result == 32'h40000008) begin
                    rm5 <= exe_to_mem_i.data_rs2;
                end
            end
        end
    end
    
    assign dmem_req_valid = ptw_mem_req_valid | dcache_mem_req_valid;
    assign dmem_addr = ptw_mem_req_valid ? ptw_mem_req_addr : dcache_mem_req_addr;
    
    assign dcache_mem_req_ready = dmem_req_ready && !ptw_mem_req_valid;
    assign ptw_mem_req_ready = dmem_req_ready && ptw_mem_req_valid;
    
    assign dcache_mem_rsp_valid = dmem_rsp_valid && !ptw_req_pending;
    assign ptw_mem_rsp_valid = dmem_rsp_valid && ptw_req_pending;
    assign ptw_mem_rsp_data = dmem_data_line;

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
        if (exe_to_mem_i.valid && exe_to_mem_i.instr.store_to_mem && exe_to_mem_i.result == 32'h40000000) begin
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

    logic valid_no_mem;
    logic valid_store;
    logic valid_load;

    assign valid_no_mem = exe_to_mem_i.valid && (exe_to_mem_i.instr.wb_origin != MEM) && exe_to_mem_i.instr.store_to_mem == 1'b0;
    assign valid_store  = exe_to_mem_i.valid && (exe_to_mem_i.instr.store_to_mem == 1'b1) && dcache_ready;

    logic valid_load_bypass;
    assign valid_load_bypass = exe_to_mem_i.valid && (exe_to_mem_i.instr.wb_origin == MEM) && bypass_from_sb;

    logic valid_load_dcache;
    assign valid_load_dcache = exe_to_mem_i.valid && (exe_to_mem_i.instr.wb_origin == MEM) && dcache_ready && !bypass_from_sb && !is_collision && !dtlb_tlb_miss;

    assign valid_load = valid_load_bypass || valid_load_dcache;

    assign mem_to_wb_o.valid = valid_no_mem || valid_load || valid_store;
    assign mem_to_wb_o.branch_taken = exe_to_mem_i.branch_taken;
    assign mem_to_wb_o.branched_pc = (exe_to_mem_i.branch_taken == 1'b1) ?
                                    exe_to_mem_i.result : '0;

    assign stall_o = (is_load && !dcache_ready) || is_collision || (is_store && !sb_ready) || 
                    (request_to_dcache && dtlb_tlb_miss && !rm4[0]) || ptw_busy;

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
