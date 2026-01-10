module fetch
    import tartaruga_pkg::*;
(
    input logic clk_i,
    input logic rstn_i,
    input logic taken_branch_i,
    input bus32_t new_pc_i,
    input logic stall_i,
    output bus32_t pc_o,
    output instruction_t instr_o,
    output logic valid_o,
    output int kanata_id_o
);
    int kanata_id_counter;

    // PC logic
    bus32_t pc_d, pc_q;

    always_ff @(posedge clk_i, negedge rstn_i) begin
        if (~rstn_i) begin
            pc_q <= 32'h80000000; // this makes easier to check AUIPC
            kanata_id_counter <= 0;
        end
        else if (~stall_i || taken_branch_i) begin
            pc_q <= pc_d;

            if (~stall_i && ~taken_branch_i) begin
                kanata_id_counter <= kanata_id_counter + 1;
            end
        end
    end

    assign kanata_id_o = kanata_id_counter;

    assign pc_d = (taken_branch_i == 1'b1) ? new_pc_i : pc_q + 4;

    assign pc_o = pc_q;

    bus32_t        mem_pc;
    logic [127:0]  mem_instr_line;

    logic       req_valid;
    logic       req_ready;
    logic       rsp_valid;
    logic       rsp_ready;

    bus32_t     rsp_mem_addr;

    icache icache (
        .clk_i(clk_i),
        .rstn_i(rstn_i),
        .pc_i(pc_q),

        .mem_pc_o(mem_pc),
        .req_valid_o(req_valid),
        .req_ready_i(req_ready),
        .mem_instr_line_i(mem_instr_line),
        .rsp_valid_i(rsp_valid),
        .rsp_ready_o(rsp_ready),
        .rsp_mem_addr_i(rsp_mem_addr),

        .instr_o(instr_o),
        .valid_o(valid_o)
    );

    imem_wrapper imem_wrapper (
        .clk_i(clk_i),
        .rstn_i(rstn_i),
        .req_valid_i(req_valid),
        .req_ready_o(req_ready),
        .pc_i(mem_pc),
        .rsp_valid_o(rsp_valid),
        .rsp_ready_i(rsp_ready),
        .rsp_mem_addr_o(rsp_mem_addr),
        .instr_line_o(mem_instr_line)
    );

endmodule
