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
    output logic valid_o
);

    // PC logic
    bus32_t pc_d, pc_q;

    always_ff @(posedge clk_i, negedge rstn_i) begin
        if (~rstn_i) begin
            pc_q <= 32'h80000000; // this makes easier to check AUIPC
        end
        else if (~stall_i || taken_branch_i) begin
            pc_q <= pc_d;
        end
    end

    assign pc_d = (taken_branch_i == 1'b1) ? new_pc_i : pc_q + 4;

    assign pc_o = pc_q;

    // Instruction memory
    dummy_imem dummy_imem_inst (
        .clk_i(clk_i),
        .rstn_i(rstn_i),
        .pc_i(pc_q),
        .instr_o(instr_o)
    );

    assign valid_o = 1'b1;

endmodule
