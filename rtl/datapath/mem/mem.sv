module mem
    import tartaruga_pkg::*;
(
    input logic clk_i,
    input logic rstn_i,
    input exe_to_mem_t exe_to_mem_i,
    output mem_to_wb_t mem_to_wb_o
);


    bus32_t result_mem;

    dummy_dmem dummy_dmem_inst (
        .clk_i(clk_i),
        .rstn_i(rstn_i),
        .addr_i(exe_to_mem_i.result),
        .data_wr_i(exe_to_mem_i.data_rs2),
        .we_mem_i(exe_to_mem_i.instr.store_to_mem),
        .data_rd_o(result_mem)
    );

    assign mem_to_wb_o.instr = exe_to_mem_i.instr;
    assign mem_to_wb_o.result = (exe_to_mem_i.instr.alu_or_mem == ALU) ? exe_to_mem_i.result : result_mem;
    assign mem_to_wb_o.branch_taken = exe_to_mem_i.branch_taken;

endmodule
