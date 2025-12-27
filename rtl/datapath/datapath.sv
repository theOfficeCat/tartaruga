import "DPI-C" function void print_commit(
    input int pc,
    input int instr,
    input int result
);

module datapath
    import tartaruga_pkg::*;
    import riscv_pkg::*;
(
    input logic clk_i,
    input logic rstn_i
);

    logic valid_fetch, valid_decode, valid_rr, valid_exe, valid_mem, valid_wb;
    logic stall_fetch, stall_decode, stall_rr, stall_exe, stall_mem, stall_wb;
    logic flush_fetch, flush_decode, flush_rr, flush_exe, flush_mem, flush_wb;
    bus32_t id_fetch, id_decode, id_rr, id_exe, id_mem, id_wb;
    bus32_t pc_fetch, pc_decode, pc_rr, pc_exe, pc_mem, pc_wb;

    logic stall;

    instruction_t instruction_d, instruction_q;

    fetch fetch_inst (
        .clk_i(clk_i),
        .rstn_i(rstn_i),
        .taken_branch_i(),
        .new_pc_i(),
        .stall_i(stall),
        .pc_o(pc_fetch),
        .instr_o(instruction_d),
        .valid_o(valid_fetch)
    );

    always_ff @(posedge clk_i, negedge rstn_i) begin : fetch_to_decode_reg
        if (~rstn_i) begin
            instruction_q <= '0;
            valid_decode = '0;
        end else if (flush_fetch) begin
            instruction_q <= NOP_INSTR_HEX;
            valid_decode = '0;
        end else if (stall_fetch) begin
            instruction_q <= instruction_q;
            valid_decode = valid_decode;
        end else begin
            instruction_q <= instruction_d;
            valid_decode <= valid_fetch;
        end
    end

    decode_to_rr_t decode_to_rr_d, decode_to_rr_q;

    decoder decoder_inst (
        .pc_i(pc_decode),
        .instr_i(instruction_q),
        .instr_decoded_o(decode_to_rr_d.instr)
    );

    immediate immediate_inst (
        .instr_i(decode_to_rr_d.instr),
        .imm_o(decode_to_rr_d.immediate)
    );

    always_ff @(posedge clk_i, negedge rstn_i) begin : decode_to_rr_reg
        if (~rstn_i) begin
            decode_to_rr_q <= '0;
            valid_rr = '0;
        end else if (flush_decode) begin
            decode_to_rr_q <= NOP_INSTR_TO_RR;
            valid_rr = '0;
        end else if (stall_decode) begin
            decode_to_rr_q <= decode_to_rr_q;
            valid_rr = valid_rr;
        end else begin
            decode_to_rr_q <= decode_to_rr_d;
            valid_rr <= valid_decode;
        end
    end

    rr_to_exe_t rr_to_exe_d, rr_to_exe_q;

    regfile regfile_inst (
        .clk_i(clk_i),
        .rstn_i(rstn_i),
        .addr_rs1_i(decode_to_rr_q.instr.addr_rs1),
        .addr_rs2_i(decode_to_rr_q.instr.addr_rs2),
        .addr_rd_i(),
        .write_enable_i(),
        .data_rd_i(),
        .data_rs1_o(rr_to_exe_d.data_rs1),
        .data_rs2_o(rr_to_exe_d.data_rs2)
    );

    assign rr_to_exe_d.instr = decode_to_rr_q.instr;
    assign rr_to_exe_d.immediate = decode_to_rr_q.immediate;

    always_ff @(posedge clk_i, negedge rstn_i) begin : rr_to_exe_reg
        if (~rstn_i) begin
            rr_to_exe_q <= '0;
            valid_exe = '0;
        end else if (flush_rr) begin
            rr_to_exe_q <= NOP_INSTR_TO_EXE;
            valid_exe = '0;
        end else if (stall_rr) begin
            rr_to_exe_q <= rr_to_exe_q;
            valid_exe = valid_exe;
        end else begin
            rr_to_exe_q <= rr_to_exe_d;
            valid_exe <= valid_rr;
        end
    end

    exe_to_mem_t exe_to_mem_d, exe_to_mem_q;

    exe exe_inst (
        .clk_i(clk_i),
        .rstn_i(rstn_i),
        .rr_to_exe_i(rr_to_exe_q),
        .rs1_decoded(rr_to_exe_d.instr.addr_rs1),
        .rs2_decoded(rr_to_exe_d.instr.addr_rs2),
        .exe_to_mem_o(exe_to_mem_d),
        .stall_o(stall_from_exe),
        .hazard_on_pipe_o(hazard_from_pipe)
    );

endmodule
