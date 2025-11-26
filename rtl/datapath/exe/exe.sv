module exe
    import tartaruga_pkg::*;
(
    input logic clk_i,
    input logic rstn_i,
    input decode_to_exe_t decode_to_exe_i,
    output exe_to_mem_t exe_to_mem_o
);

    bus32_t alu_data_rs1;
    bus32_t alu_data_rs2;

    assign alu_data_rs1 = (decode_to_exe_i.instr.rs1_or_pc == RS1) ? decode_to_exe_i.data_rs1 : decode_to_exe_i.instr.pc;
    assign alu_data_rs2 = (decode_to_exe_i.instr.rs2_or_imm == RS2) ? decode_to_exe_i.data_rs2 : decode_to_exe_i.immediate;

    bus32_t res_alu, res_mul;

    alu alu_inst(
        .data_rs1_i(alu_data_rs1),
        .data_rs2_i(alu_data_rs2),
        .alu_op_i(decode_to_exe_i.instr.alu_op),
        .data_rd_o(res_alu)
    );

    mul mul_inst(
        .clk_i(clk_i),
        .rstn_i(rstn_i),
        .data_rs1_i(data_rs1_i),
        .data_rs2_i(data_rs2_i),
        .data_rd_o(res_mul)
    );

    

    logic taken_branch;

    branch branch_inst (
        .data_rs1_i(decode_to_exe_i.data_rs1),
        .data_rs2_i(decode_to_exe_i.data_rs2),
        .jump_kind_i(decode_to_exe_i.instr.jump_kind),
        .taken_o(taken_branch)
    );

    assign exe_to_mem_o.branch_taken = taken_branch & decode_to_exe_i.valid;
    assign exe_to_mem_o.instr = decode_to_exe_i.instr;
    assign exe_to_mem_o.valid = decode_to_exe_i.valid;
    assign exe_to_mem_o.data_rs2 = decode_to_exe_i.data_rs2;
endmodule
