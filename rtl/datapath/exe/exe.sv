module exe
    import tartaruga_pkg::*;
(
    input decode_to_exe_t decode_to_exe_i,
    output exe_to_mem_t exe_to_mem_o
);

    bus32_t alu_data_rs1;
    bus32_t alu_data_rs2;

    assign alu_data_rs1 = (decode_to_exe_i.instr.rs1_or_pc == RS1) ? decode_to_exe_i.data_rs1 : decode_to_exe_i.instr.pc;
    assign alu_data_rs2 = (decode_to_exe_i.instr.rs2_or_imm == RS2) ? decode_to_exe_i.data_rs2 : decode_to_exe_i.immediate;

    alu alu_inst(
        .data_rs1_i(alu_data_rs1),
        .data_rs2_i(alu_data_rs2),
        .alu_op_i(decode_to_exe_i.instr.alu_op),
        .data_rd_o(exe_to_mem_o.result)
    );

    assign exe_to_mem_o.instr = decode_to_exe_i.instr;
    assign exe_to_mem_o.data_rs2 = decode_to_exe_i.data_rs2;
endmodule
