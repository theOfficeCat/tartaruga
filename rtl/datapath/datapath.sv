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
    instruction_t instruction_d, instruction_q;
    bus32_t pc_fetch, pc_decode;
    logic valid_decode;
    
    // Fetch
    fetch fetch_inst (
        .clk_i(clk_i),
        .rstn_i(rstn_i),
        .taken_branch_i(mem_to_wb_q.branch_taken),
        .new_pc_i(mem_to_wb_q.branched_pc),
        .stall_i(stall),
        .pc_o(pc_fetch),
        .instr_o(instruction_d)
    );
/*
    always_ff @(negedge rstn_i, posedge clk_i) begin
        if (~rstn_i) begin
            instruction_q <= '0;
            pc_decode <= '0;
        end else begin
            instruction_q <= instruction_d;
            pc_decode <= pc_fetch;
        end
    end
*/
    always_ff @(negedge rstn_i, posedge clk_i) begin
        if (~rstn_i) begin
            instruction_q <= '0;
            pc_decode <= '0;
        end else if (exe_to_mem_d.branch_taken == 1'b1 ||
                     mem_to_wb_d.branch_taken == 1'b1 ||
                     mem_to_wb_q.branch_taken == 1'b1) begin
            instruction_q <= NOP_INSTR_HEX;
            pc_decode <= '0;
            valid_decode <= 1'b0;
        end else begin
            if (!stall) begin
                instruction_q <= instruction_d; // captura nueva instrucción
                pc_decode <= pc_fetch;
                valid_decode <= 1'b1;
            end else begin
                instruction_q <= instruction_q; // hold
                pc_decode <= pc_decode;         // hold
                valid_decode <= 1'b1;
            end
        end
    end

    // Decode
    decode_to_exe_t decode_to_exe_d, decode_to_exe_q;

    decoder decoder_inst (
        .pc_i(pc_decode),
        .instr_i(instruction_q),
        .instr_decoded_o(decode_to_exe_d.instr)
    );

    immediate immediate_inst (
        .instr_i(decode_to_exe_d.instr),
        .imm_o(decode_to_exe_d.immediate)
    );

    regfile regfile_inst (
        .clk_i(clk_i),
        .rstn_i(rstn_i),
        .addr_rs1_i(decode_to_exe_d.instr.addr_rs1),
        .addr_rs2_i(decode_to_exe_d.instr.addr_rs2),
        .addr_rd_i(mem_to_wb_q.instr.addr_rd),
        .data_rd_i(mem_to_wb_q.result),
        .write_enable_i(mem_to_wb_q.instr.write_enable),
        .data_rs1_o(decode_to_exe_d.data_rs1),
        .data_rs2_o(decode_to_exe_d.data_rs2)
    );

    logic stall;

    reg_addr_t rs1_d, rs2_d;
    assign rs1_d = decode_to_exe_d.instr.addr_rs1;
    assign rs2_d = decode_to_exe_d.instr.addr_rs2;

    logic hazard_rs1, hazard_rs2, hazard_from_pipe;
    logic stall_from_exe;

    always_comb begin
        hazard_rs1 = 1'b0;
        hazard_rs2 = 1'b0;

        // EXE stage (instruction currently in EXE pipeline register)
        hazard_rs1 |= reg_hazard(rs1_d, decode_to_exe_q.instr.addr_rd, decode_to_exe_q.instr.write_enable);
        hazard_rs2 |= reg_hazard(rs2_d, decode_to_exe_q.instr.addr_rd, decode_to_exe_q.instr.write_enable);

        // EXE->MEM stage
        hazard_rs1 |= reg_hazard(rs1_d, exe_to_mem_q.instr.addr_rd, exe_to_mem_q.instr.write_enable);
        hazard_rs2 |= reg_hazard(rs2_d, exe_to_mem_q.instr.addr_rd, exe_to_mem_q.instr.write_enable);

        // MEM->WB stage
        hazard_rs1 |= reg_hazard(rs1_d, mem_to_wb_q.instr.addr_rd, mem_to_wb_q.instr.write_enable);
        hazard_rs2 |= reg_hazard(rs2_d, mem_to_wb_q.instr.addr_rd, mem_to_wb_q.instr.write_enable);

        stall = hazard_rs1 | hazard_rs2 | stall_from_exe | hazard_from_pipe;
    end

    assign decode_to_exe_d.valid = ~stall & valid_decode;

    always_ff @(negedge rstn_i, posedge clk_i) begin
        if (~rstn_i) begin
            decode_to_exe_q <= '0;
        end else begin
            if (!stall) begin
                if (exe_to_mem_d.branch_taken == 1'b1) begin
                    decode_to_exe_q <= NOP_INSTR;
                end else begin
                    decode_to_exe_q <= decode_to_exe_d;
                end
            end else begin
                if (!stall_from_exe) begin
                    decode_to_exe_q <= NOP_INSTR;
                end
            end
        end
    end

    // Exe
    exe_to_mem_t exe_to_mem_d, exe_to_mem_q;
    
    exe exe_inst (
        .clk_i(clk_i),
        .rstn_i(rstn_i),
        .decode_to_exe_i(decode_to_exe_q),
        .rs1_decoded(decode_to_exe_d.instr.addr_rs1),
        .rs2_decoded(decode_to_exe_d.instr.addr_rs2),
        .exe_to_mem_o(exe_to_mem_d),
        .stall_o(stall_from_exe),
        .hazard_on_pipe_o(hazard_from_pipe)
    );

    always_ff @(negedge rstn_i, posedge clk_i) begin
        if (~rstn_i) begin
            exe_to_mem_q <= '0;
        end else begin
            exe_to_mem_q <= exe_to_mem_d;
        end
    end

 
    // Mem
    mem_to_wb_t mem_to_wb_d, mem_to_wb_q;

    mem mem_inst (
        .clk_i(clk_i),
        .rstn_i(rstn_i),
        .exe_to_mem_i(exe_to_mem_q),
        .mem_to_wb_o(mem_to_wb_d)
    );

    always_ff @(negedge rstn_i, posedge clk_i) begin
        if (~rstn_i) begin
            mem_to_wb_q <= '0;
        end else begin
            mem_to_wb_q <= mem_to_wb_d;
        end
    end

 
    // Writeback

    always_ff @(posedge clk_i) begin
        if (mem_to_wb_q.valid) begin
            print_commit(
                mem_to_wb_q.instr.pc,
                mem_to_wb_q.instr.instr.instruction,
                mem_to_wb_q.result
            );
        end
    end

endmodule
