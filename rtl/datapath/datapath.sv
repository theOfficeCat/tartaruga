module datapath
    import tartaruga_pkg::*;
(
    input logic clk_i,
    input logic rstn_i
);
    instruction_t instruction;
    bus32_t pc;
    
    // Fetch
    fetch fetch_inst (
        .clk_i(clk_i),
        .rstn_i(rstn_i),
        .pc_o(pc),
        .instr_o(instruction)
    );

    decode_to_exe_t decode_to_exe;

    // Decode
    decoder decoder_inst (
        .pc_i(pc),
        .instr_i(instruction),
        .instr_decoded_o(decode_to_exe.instr)
    );

    regfile regfile_inst (
        .clk_i(clk_i),
        .rstn_i(rstn_i),
        .addr_rs1_i(decode_to_exe.instr.addr_rs1),
        .addr_rs2_i(decode_to_exe.instr.addr_rs2),
        .addr_rd_i('0),
        .data_rd_i('0),
        .write_enable_i('1),
        .data_rs1_o(decode_to_exe.data_rs1),
        .data_rs2_o(decode_to_exe.data_rs2)
    );

endmodule
