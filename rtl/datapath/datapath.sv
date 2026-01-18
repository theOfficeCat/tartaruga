import "DPI-C" function void print_commit(
    input int pc,
    input int instr,
    input int result
);

import "DPI-C" function void print_kanata(
    input logic valid_fetch,
    input logic valid_decode,
    input logic valid_exe,
    input logic valid_mem,
    input logic valid_wb,
    input logic valid_commit,

    input int id_fetch,
    input int id_decode,
    input int id_exe,
    input int id_mem,
    input int id_wb,
    input int id_commit,

    input int pc_decode,
    input int instr_decode,

    input logic flush
);

module datapath
    import tartaruga_pkg::*;
    import riscv_pkg::*;
(
    input logic clk_i,
    input logic rstn_i,
    output logic commit_valid_o
);
    logic commit_valid;
    bus32_t commit_pc;
    instruction_t commit_instr;
    reg_addr_t commit_rd_addr;
    bus32_t commit_result;
    logic commit_write_enable;
    logic commit_store_to_mem;
    bus32_t commit_new_pc;
    logic commit_branch_taken;
    int commit_kanata_id;
    logic commit_xcpt;
    xcpt_code_t commit_xcpt_code;

    logic rob_full;

    logic valid_fetch, valid_decode, valid_exe, valid_mem, valid_wb;
    bus32_t pc_fetch, pc_decode, pc_exe, pc_mem, pc_wb;

    instruction_t instruction_d, instruction_q;

    logic stall_fetch;

    assign stall_fetch = stall;

    int id_fetch, id_decode, id_exe, id_mem, id_wb;

    logic fetch_missaligned;

    // Fetch
    fetch fetch_inst (
        .clk_i(clk_i),
        .rstn_i(rstn_i),
        .taken_branch_i(commit_branch_taken),
        .new_pc_i(commit_new_pc),
        .stall_i(stall_fetch),
        .pc_o(pc_fetch),
        .instr_o(instruction_d),
        .valid_o(valid_fetch),
        .kanata_id_o(id_fetch),
        .xcpt_missaligned_o(fetch_missaligned)
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
    logic xcpt_fetch, xcpt_decode;
    xcpt_code_t xcpt_code_fetch, xcpt_code_decode;

    always_comb begin
        xcpt_fetch = fetch_missaligned;
        xcpt_code_fetch = XCPT_INSTR_ADDR_MISALIGNED;
    end

    always_ff @(negedge rstn_i, posedge clk_i) begin
        if (~rstn_i || commit_branch_taken) begin
            instruction_q <= '0;
            pc_decode <= '0;
            valid_decode <= 1'b0;
            id_decode <= '0;
            xcpt_decode <= 1'b0;
            xcpt_code_decode <= XCPT_ILLEGAL_INSTR;
        //end else if (exe_to_mem_d.branch_taken == 1'b1 ||
            //         mem_to_wb_d.branch_taken == 1'b1 ||
            //         mem_to_wb_q.branch_taken == 1'b1) begin
            //instruction_q <= NOP_INSTR_HEX;
            //pc_decode <= '0;
            //valid_decode <= 1'b0;
        end else begin
            if (!stall) begin
                instruction_q <= instruction_d; // captura nueva instrucción
                pc_decode <= pc_fetch;
                valid_decode <= valid_fetch;
                id_decode <= id_fetch;
                xcpt_decode <= xcpt_fetch;
                xcpt_code_decode <= xcpt_code_fetch;
            end else begin
                instruction_q <= instruction_q; // hold
                pc_decode <= pc_decode;         // hold
                valid_decode <= valid_decode;
                id_decode <= id_decode;
                xcpt_decode <= xcpt_decode;
                xcpt_code_decode <= xcpt_code_decode;
            end
        end
    end

    // Decode
    decode_to_exe_t decode_to_exe_d, decode_to_exe_q;

    rob_idx_t rob_entry_decode;

    bus32_t regfile_rs1_data, regfile_rs2_data;

    decoder decoder_inst (
        .pc_i(pc_decode),
        .instr_i(instruction_q),
        .rob_idx_i(rob_entry_decode),
        .id_decode_i(id_decode),
        .xcpt_i(xcpt_decode),
        .xcpt_code_i(xcpt_code_decode),
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
        .addr_rd_i(commit_rd_addr),
        .data_rd_i(commit_result),
        .write_enable_i(commit_write_enable),
        .data_rs1_o(regfile_rs1_data),
        .data_rs2_o(regfile_rs2_data)
    );

    csr csr_inst (
        .clk_i(clk_i),
        .rstn_i(rstn_i),

        .csr_read_i(),
        .csr_write_i(),
        .csr_addr_i(),
        .csr_write_data_i(),

        .xcpt_i(commit_xcpt),
        .xcpt_code_i(commit_xcpt_code),
        .xcpt_pc_i(commit_pc),
        .xcpt_value_i(),

        .csr_read_valid_o(),
        .csr_read_data_o()
    );

    logic stall;

    logic hazard_rob_rs1, hazard_rob_rs2;
    logic hazard_rob;

    assign hazard_rob = hazard_rob_rs1 | hazard_rob_rs2;

    rob_idx_t rob_entry_hazard_rs1, rob_entry_hazard_rs2;
    logic completed_hazard_rs1, completed_hazard_rs2;
    bus32_t result_hazard_rs1, result_hazard_rs2;

    logic stall_from_exe, stall_from_mem;

    logic solved_hazard_rs1, solved_hazard_rs2;
    logic solved_hazard;

    assign solved_hazard = solved_hazard_rs1 & solved_hazard_rs2;

    always_comb begin
        decode_to_exe_d.data_rs1 = regfile_rs1_data;
        decode_to_exe_d.data_rs2 = regfile_rs2_data;

        solved_hazard_rs1 = !hazard_rob_rs1;
        solved_hazard_rs2 = !hazard_rob_rs2;

        if (hazard_rob_rs1) begin
            if (completed_hazard_rs1) begin
                decode_to_exe_d.data_rs1 = result_hazard_rs1;
                solved_hazard_rs1 = 1'b1;
            end else begin
                if (rob_entry_hazard_rs1 == exe_to_mem_d.instr.rob_idx && exe_to_mem_d.valid) begin
                    decode_to_exe_d.data_rs1 = exe_to_mem_d.result;
                    solved_hazard_rs1 = 1'b1;
                end else if (rob_entry_hazard_rs1 == mem_to_wb_d.instr.rob_idx && mem_to_wb_d.valid) begin
                    decode_to_exe_d.data_rs1 = mem_to_wb_d.result;
                    solved_hazard_rs1 = 1'b1;
                end
            end
        end

        if (hazard_rob_rs2) begin
            if (completed_hazard_rs2) begin
                decode_to_exe_d.data_rs2 = result_hazard_rs2;
                solved_hazard_rs2 = 1'b1;
            end else begin
                if (rob_entry_hazard_rs2 == exe_to_mem_d.instr.rob_idx && exe_to_mem_d.valid) begin
                    decode_to_exe_d.data_rs2 = exe_to_mem_d.result;
                    solved_hazard_rs2 = 1'b1;
                end else if (rob_entry_hazard_rs2 == mem_to_wb_d.instr.rob_idx && mem_to_wb_d.valid) begin
                    decode_to_exe_d.data_rs2 = mem_to_wb_d.result;
                    solved_hazard_rs2 = 1'b1;
                end
            end
        end
    end

    assign stall = (hazard_rob & ~solved_hazard) | stall_from_exe | (~valid_fetch) | rob_full | stall_from_mem;

    assign decode_to_exe_d.valid = ~stall & valid_decode;

    always_ff @(negedge rstn_i, posedge clk_i) begin
        if (~rstn_i) begin
            decode_to_exe_q <= '0;
        end else begin
            if (!stall) begin
                //if (exe_to_mem_d.branch_taken == 1'b1) begin
                //    decode_to_exe_q <= NOP_INSTR;
                //end else begin
                    decode_to_exe_q <= decode_to_exe_d;
                    //end
            end else begin
                if (!stall_from_exe && !stall_from_mem) begin
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
        .stall_o(stall_from_exe)
    );

    always_ff @(negedge rstn_i, posedge clk_i) begin
        if (~rstn_i) begin
            exe_to_mem_q <= '0;
        end else begin
            if (!stall_from_mem) begin
                exe_to_mem_q <= exe_to_mem_d;
            end
        end
    end


    // Mem
    mem_to_wb_t mem_to_wb_d, mem_to_wb_q;

    mem mem_inst (
        .clk_i(clk_i),
        .rstn_i(rstn_i),
        .exe_to_mem_i(exe_to_mem_q),
        .mem_to_wb_o(mem_to_wb_d),
        .stall_o(stall_from_mem)
    );

    always_ff @(negedge rstn_i, posedge clk_i) begin
        if (~rstn_i) begin
            mem_to_wb_q <= '0;
        end else begin
            mem_to_wb_q <= mem_to_wb_d;
        end
    end

    rob rob_inst (
        .clk_i(clk_i),
        .rstn_i(rstn_i),
        //.flush_i(mem_to_wb_q.branch_taken),
        .valid_decode_i(decode_to_exe_d.valid),
        .pc_i(decode_to_exe_d.instr.pc),
        .instr_i(decode_to_exe_d.instr.instr),
        .rd_addr_i(decode_to_exe_d.instr.addr_rd),
        .write_enable_i(decode_to_exe_d.instr.write_enable),
        .store_to_mem_i(decode_to_exe_d.instr.store_to_mem),
        .kanata_id_i(decode_to_exe_d.instr.kanata_id),

        .rob_entry_alloc_o(rob_entry_decode),

        .rob_entry_commit_i(mem_to_wb_q.instr.rob_idx),
        .valid_wb_i(mem_to_wb_q.valid),
        .result_i(mem_to_wb_q.result),
        .new_pc_i(mem_to_wb_q.branched_pc),
        .branch_taken_i(mem_to_wb_q.branch_taken),
        .xcpt_i(mem_to_wb_q.instr.xcpt),
        .xcpt_code_i(mem_to_wb_q.instr.xcpt_code),

        .commit_valid_o(commit_valid),
        .commit_pc_o(commit_pc),
        .commit_instr_o(commit_instr),
        .commit_rd_addr_o(commit_rd_addr),
        .commit_result_o(commit_result),
        .commit_write_enable_o(commit_write_enable),
        .commit_store_to_mem_o(commit_store_to_mem),
        .commit_new_pc_o(commit_new_pc),
        .commit_branch_taken_o(commit_branch_taken),
        .commit_kanata_id_o(commit_kanata_id),
        .commit_xcpt_o(commit_xcpt),
        .commit_xcpt_code_o(commit_xcpt_code),

        .rob_full_o(rob_full),

        .rs1_addr_i(decode_to_exe_d.instr.addr_rs1),
        .hazard_rs1_o(hazard_rob_rs1),
        .rob_entry_rs1_o(rob_entry_hazard_rs1),
        .completed_rs1_o(completed_hazard_rs1),
        .result_rs1_o(result_hazard_rs1),

        .rs2_addr_i(decode_to_exe_d.instr.addr_rs2),
        .hazard_rs2_o(hazard_rob_rs2),
        .rob_entry_rs2_o(rob_entry_hazard_rs2),
        .completed_rs2_o(completed_hazard_rs2),
        .result_rs2_o(result_hazard_rs2)
    );

    // Writeback

    always_ff @(posedge clk_i) begin
        if (commit_valid) begin
            print_commit(
                commit_pc,
                commit_instr,
                commit_result
            );
        end
        print_kanata(
            valid_fetch,
            valid_decode,
            valid_exe,
            valid_mem,
            valid_wb,
            commit_valid,

            id_fetch,
            id_decode,
            id_exe,
            id_mem,
            id_wb,
            commit_kanata_id,

            pc_decode,
            decode_to_exe_d.instr.instr.instruction,

            commit_branch_taken
        );
    end

    always_comb begin
        valid_exe = decode_to_exe_q.valid;
        pc_exe    = decode_to_exe_q.instr.pc;
        id_exe    = decode_to_exe_q.instr.kanata_id;

        valid_mem = exe_to_mem_q.valid;
        pc_mem    = exe_to_mem_q.instr.pc;
        id_mem    = exe_to_mem_q.instr.kanata_id;

        valid_wb  = mem_to_wb_q.valid;
        pc_wb     = mem_to_wb_q.instr.pc;
        id_wb     = mem_to_wb_q.instr.kanata_id;


    end

    assign commit_valid_o = commit_valid;

endmodule
