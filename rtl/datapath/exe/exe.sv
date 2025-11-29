module exe
    import tartaruga_pkg::*;
(
    input logic clk_i,
    input logic rstn_i,
    input decode_to_exe_t decode_to_exe_i,
    output exe_to_mem_t exe_to_mem_o,
    output logic stall_o,
    output logic hazard_on_pipe_o
);

    // Metadata pipe to also detect collisions
    decode_to_exe_t exe_pipe_q [MAX_EXE_STAGES - 1:0];
    decode_to_exe_t exe_pipe_d [MAX_EXE_STAGES - 1:0];

    always_ff @(posedge clk_i or negedge rstn_i) begin
        if (~rstn_i) begin
            for (int i = 0; i < MAX_EXE_STAGES; ++i) begin
                exe_pipe_q[i] <= NOP_INSTR;
            end
        end else begin
            for (int i = 0; i < MAX_EXE_STAGES; ++i) begin
                exe_pipe_q[i] <= exe_pipe_d[i];
            end
        end
    end

    always_comb begin
        for (int i = 1; i < MAX_EXE_STAGES; ++i) begin
            exe_pipe_d[i] = exe_pipe_q[i-1];
            stall_o = 1'b0; // By default there is no collision

        end
    
        exe_pipe_d[0] = NOP_INSTR;

        if (exe_pipe_q[MAX_EXE_STAGES - decode_to_exe_i.instr.exe_stages - 1].valid == 1'b1) begin
            stall_o = 1'b1;
        end
        else begin
            exe_pipe_d[MAX_EXE_STAGES - decode_to_exe_i.instr.exe_stages] = decode_to_exe_i;
        end
    end

    reg_addr_t rs1_d, rs2_d;

    logic hazard_on_pipe;

    always_comb begin
        rs1_d = decode_to_exe_i.instr.addr_rs1;
        rs2_d = decode_to_exe_i.instr.addr_rs2;
        hazard_on_pipe = 1'b0;

        for (int i = 0; i < MAX_EXE_STAGES; ++i) begin
            hazard_on_pipe |= reg_hazard(rs1_d, exe_pipe_q[i].instr.addr_rd, exe_pipe_q[i].valid);
            hazard_on_pipe |= reg_hazard(rs2_d, exe_pipe_q[i].instr.addr_rd, exe_pipe_q[i].valid);
        end
    end

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
        .data_rs1_i(alu_data_rs1),
        .data_rs2_i(alu_data_rs2),
        .data_rd_o(res_mul)
    );

    

    logic taken_branch;

    branch branch_inst (
        .data_rs1_i(decode_to_exe_i.data_rs1),
        .data_rs2_i(decode_to_exe_i.data_rs2),
        .jump_kind_i(decode_to_exe_i.instr.jump_kind),
        .taken_o(taken_branch)
    );

    assign exe_to_mem_o.branch_taken = taken_branch & exe_pipe_d[MAX_EXE_STAGES-1].valid;
    assign exe_to_mem_o.instr = exe_pipe_d[MAX_EXE_STAGES-1].instr;
    assign exe_to_mem_o.valid = exe_pipe_d[MAX_EXE_STAGES-1].valid;
    assign exe_to_mem_o.data_rs2 = exe_pipe_d[MAX_EXE_STAGES-1].data_rs2;
    assign exe_to_mem_o.result = (exe_pipe_d[MAX_EXE_STAGES-1].instr.is_mul == 1'b1) ? res_mul : res_alu;
    assign hazard_on_pipe_o = hazard_on_pipe;
endmodule
