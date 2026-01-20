module decoder
    import tartaruga_pkg::*;
    import riscv_pkg::*;
(
    input bus32_t pc_i,
    input instruction_t instr_i,
    input rob_idx_t rob_idx_i,
    input int id_decode_i,
    output instr_data_t instr_decoded_o
);

    //assign instr_decoded_o = '0;

    always_comb begin
        instr_decoded_o.pc = pc_i;
        instr_decoded_o.instr = instr_i;
        //instr_decoded_o.addr_rs1 = (instr_decoded_o.rs1_or_pc == RS1) ? instr_i.rtype.rs1 : '0;
        //instr_decoded_o.addr_rs2 = (instr_decoded_o.rs2_or_imm == RS2) ? instr_i.rtype.rs2 : '0;
        instr_decoded_o.addr_rs1 = instr_i.rtype.rs1;
        instr_decoded_o.addr_rs2 = instr_i.rtype.rs2;
        instr_decoded_o.addr_rd = instr_i.rtype.rd;
        instr_decoded_o.exe_stages = 3'b1;
        instr_decoded_o.is_mul = 1'b0;
        instr_decoded_o.rob_idx = rob_idx_i;
        instr_decoded_o.kanata_id = id_decode_i;

        case (instr_i.rtype.opcode)
            OP_ALU_I: begin
                instr_decoded_o.write_enable = 1'b1;
                instr_decoded_o.rs1_or_pc = RS1;
                instr_decoded_o.rs2_or_imm = IMM;
                instr_decoded_o.wb_origin = ALU;
                instr_decoded_o.store_to_mem = 1'b0;
                instr_decoded_o.jump_kind = BNONE;

                case (instr_i.rtype.func3)
                    F3_ADD_SUB: begin //ADDI
                        instr_decoded_o.alu_op = ADD;
                    end
                    F3_SLT: begin //SLTI
                        instr_decoded_o.alu_op = SLT;
                    end
                    F3_SLTU: begin //SLTIU
                        instr_decoded_o.alu_op = SLTU;
                    end
                    F3_XOR: begin //XORI
                        instr_decoded_o.alu_op = XOR;
                    end
                    F3_OR: begin //ORI
                        instr_decoded_o.alu_op = OR;
                    end
                    F3_AND: begin //ANDI
                        instr_decoded_o.alu_op = AND;
                    end
                    F3_SLL: begin //SLLI
                        case (instr_i.rtype.func7)
                            F7_ALU_NORMAL: begin
                                instr_decoded_o.alu_op = SLL;
                            end
                            default: begin
                                // illegal instruction treated as NOP being a x0 + x0
                                // without write

                                instr_decoded_o.write_enable = 1'b0;
                                instr_decoded_o.rs1_or_pc = RS1;
                                instr_decoded_o.rs2_or_imm = RS2;
                                instr_decoded_o.addr_rs1 = '0;
                                instr_decoded_o.addr_rs2 = '0;
                                instr_decoded_o.addr_rd = '0;
                                instr_decoded_o.alu_op = ADD;
                                instr_decoded_o.wb_origin = ALU;
                                instr_decoded_o.store_to_mem = 1'b0;
                            end
                        endcase
                    end
                    F3_SRL_SRA: begin //SRLI and SRAI
                        case (instr_i.rtype.func7)
                            F7_ALU_NORMAL: begin
                                instr_decoded_o.alu_op = SRL;
                            end
                            F7_ALU_MODIFIED: begin
                                instr_decoded_o.alu_op = SRA;
                            end
                            default: begin
                                // illegal instruction treated as NOP being a x0 + x0
                                // without write

                                instr_decoded_o.write_enable = 1'b0;
                                instr_decoded_o.rs1_or_pc = RS1;
                                instr_decoded_o.rs2_or_imm = RS2;
                                instr_decoded_o.addr_rs1 = '0;
                                instr_decoded_o.addr_rs2 = '0;
                                instr_decoded_o.addr_rd = '0;
                                instr_decoded_o.alu_op = ADD;
                                instr_decoded_o.wb_origin = ALU;
                                instr_decoded_o.store_to_mem = 1'b0;
                            end
                        endcase
                    end
                    default: begin
                        // illegal instruction treated as NOP being a x0 + x0
                        // without write

                        instr_decoded_o.write_enable = 1'b0;
                        instr_decoded_o.rs1_or_pc = RS1;
                        instr_decoded_o.rs2_or_imm = RS2;
                        instr_decoded_o.addr_rs1 = '0;
                        instr_decoded_o.addr_rs2 = '0;
                        instr_decoded_o.addr_rd = '0;
                        instr_decoded_o.alu_op = ADD;
                        instr_decoded_o.wb_origin = ALU;
                        instr_decoded_o.store_to_mem = 1'b0;
                    end
                endcase
            end

            OP_ALU: begin
                instr_decoded_o.write_enable = 1'b1;
                instr_decoded_o.rs1_or_pc = RS1;
                instr_decoded_o.rs2_or_imm = RS2;
                instr_decoded_o.wb_origin = ALU;
                instr_decoded_o.store_to_mem = 1'b0;
                instr_decoded_o.jump_kind = BNONE;

                case (instr_i.rtype.func3)
                    F3_ADD_SUB: begin // F3_MUL also
                        case (instr_i.rtype.func7)
                            F7_ALU_NORMAL: begin
                                instr_decoded_o.alu_op = ADD;
                            end
                            F7_ALU_MODIFIED: begin
                                instr_decoded_o.alu_op = SUB;
                            end
                            F7_MUL: begin
                                instr_decoded_o.alu_op = ADD;
                                instr_decoded_o.is_mul = 1'b1;
                                instr_decoded_o.exe_stages = EXE_STAGES_MULT;
                            end
                            default: begin
                                // illegal instruction treated as NOP being a x0 + x0
                                // without write

                                instr_decoded_o.write_enable = 1'b0;
                                instr_decoded_o.rs1_or_pc = RS1;
                                instr_decoded_o.rs2_or_imm = RS2;
                                instr_decoded_o.addr_rs1 = '0;
                                instr_decoded_o.addr_rs2 = '0;
                                instr_decoded_o.addr_rd = '0;
                                instr_decoded_o.alu_op = ADD;
                                instr_decoded_o.wb_origin = ALU;
                                instr_decoded_o.store_to_mem = 1'b0;
                            end
                        endcase
                    end
                    F3_SLL: begin
                         case (instr_i.rtype.func7)
                            F7_ALU_NORMAL: begin
                                instr_decoded_o.alu_op = SLL;
                            end
                            default: begin
                                // illegal instruction treated as NOP being a x0 + x0
                                // without write

                                instr_decoded_o.write_enable = 1'b0;
                                instr_decoded_o.rs1_or_pc = RS1;
                                instr_decoded_o.rs2_or_imm = RS2;
                                instr_decoded_o.addr_rs1 = '0;
                                instr_decoded_o.addr_rs2 = '0;
                                instr_decoded_o.addr_rd = '0;
                                instr_decoded_o.alu_op = ADD;
                                instr_decoded_o.wb_origin = ALU;
                                instr_decoded_o.store_to_mem = 1'b0;
                            end
                        endcase
                    end
                    F3_SLT: begin
                         case (instr_i.rtype.func7)
                            F7_ALU_NORMAL: begin
                                instr_decoded_o.alu_op = SLT;
                            end
                            default: begin
                                // illegal instruction treated as NOP being a x0 + x0
                                // without write

                                instr_decoded_o.write_enable = 1'b0;
                                instr_decoded_o.rs1_or_pc = RS1;
                                instr_decoded_o.rs2_or_imm = RS2;
                                instr_decoded_o.addr_rs1 = '0;
                                instr_decoded_o.addr_rs2 = '0;
                                instr_decoded_o.addr_rd = '0;
                                instr_decoded_o.alu_op = ADD;
                                instr_decoded_o.wb_origin = ALU;
                                instr_decoded_o.store_to_mem = 1'b0;
                            end
                        endcase
                    end
                    F3_SLTU: begin
                         case (instr_i.rtype.func7)
                            F7_ALU_NORMAL: begin
                                instr_decoded_o.alu_op = SLTU;
                            end
                            default: begin
                                // illegal instruction treated as NOP being a x0 + x0
                                // without write

                                instr_decoded_o.write_enable = 1'b0;
                                instr_decoded_o.rs1_or_pc = RS1;
                                instr_decoded_o.rs2_or_imm = RS2;
                                instr_decoded_o.addr_rs1 = '0;
                                instr_decoded_o.addr_rs2 = '0;
                                instr_decoded_o.addr_rd = '0;
                                instr_decoded_o.alu_op = ADD;
                                instr_decoded_o.wb_origin = ALU;
                                instr_decoded_o.store_to_mem = 1'b0;
                            end
                        endcase
                    end
                    F3_XOR: begin
                         case (instr_i.rtype.func7)
                            F7_ALU_NORMAL: begin
                                instr_decoded_o.alu_op = XOR;
                            end
                            default: begin
                                // illegal instruction treated as NOP being a x0 + x0
                                // without write

                                instr_decoded_o.write_enable = 1'b0;
                                instr_decoded_o.rs1_or_pc = RS1;
                                instr_decoded_o.rs2_or_imm = RS2;
                                instr_decoded_o.addr_rs1 = '0;
                                instr_decoded_o.addr_rs2 = '0;
                                instr_decoded_o.addr_rd = '0;
                                instr_decoded_o.alu_op = ADD;
                                instr_decoded_o.wb_origin = ALU;
                                instr_decoded_o.store_to_mem = 1'b0;
                            end
                        endcase
                    end
                    F3_SRL_SRA: begin
                         case (instr_i.rtype.func7)
                            F7_ALU_NORMAL: begin
                                instr_decoded_o.alu_op = SRL;
                            end
                            F7_ALU_MODIFIED: begin
                                instr_decoded_o.alu_op = SRA;
                            end
                            default: begin
                                // illegal instruction treated as NOP being a x0 + x0
                                // without write

                                instr_decoded_o.write_enable = 1'b0;
                                instr_decoded_o.rs1_or_pc = RS1;
                                instr_decoded_o.rs2_or_imm = RS2;
                                instr_decoded_o.addr_rs1 = '0;
                                instr_decoded_o.addr_rs2 = '0;
                                instr_decoded_o.addr_rd = '0;
                                instr_decoded_o.alu_op = ADD;
                                instr_decoded_o.wb_origin = ALU;
                                instr_decoded_o.store_to_mem = 1'b0;
                            end
                        endcase
                    end
                    F3_OR: begin
                         case (instr_i.rtype.func7)
                            F7_ALU_NORMAL: begin
                                instr_decoded_o.alu_op = OR;
                            end
                            default: begin
                                // illegal instruction treated as NOP being a x0 + x0
                                // without write

                                instr_decoded_o.write_enable = 1'b0;
                                instr_decoded_o.rs1_or_pc = RS1;
                                instr_decoded_o.rs2_or_imm = RS2;
                                instr_decoded_o.addr_rs1 = '0;
                                instr_decoded_o.addr_rs2 = '0;
                                instr_decoded_o.addr_rd = '0;
                                instr_decoded_o.alu_op = ADD;
                                instr_decoded_o.wb_origin = ALU;
                                instr_decoded_o.store_to_mem = 1'b0;
                            end
                        endcase
                    end
                    F3_AND: begin
                         case (instr_i.rtype.func7)
                            F7_ALU_NORMAL: begin
                                instr_decoded_o.alu_op = AND;
                            end
                            default: begin
                                // illegal instruction treated as NOP being a x0 + x0
                                // without write

                                instr_decoded_o.write_enable = 1'b0;
                                instr_decoded_o.rs1_or_pc = RS1;
                                instr_decoded_o.rs2_or_imm = RS2;
                                instr_decoded_o.addr_rs1 = '0;
                                instr_decoded_o.addr_rs2 = '0;
                                instr_decoded_o.addr_rd = '0;
                                instr_decoded_o.alu_op = ADD;
                                instr_decoded_o.wb_origin = ALU;
                                instr_decoded_o.store_to_mem = 1'b0;
                            end
                        endcase
                    end

                    default: begin
                        // illegal instruction treated as NOP being a x0 + x0
                        // without write

                        instr_decoded_o.write_enable = 1'b0;
                        instr_decoded_o.rs1_or_pc = RS1;
                        instr_decoded_o.rs2_or_imm = RS2;
                        instr_decoded_o.addr_rs1 = '0;
                        instr_decoded_o.addr_rs2 = '0;
                        instr_decoded_o.addr_rd = '0;
                        instr_decoded_o.alu_op = ADD;
                        instr_decoded_o.store_to_mem = 1'b0;
                    end
                endcase
            end

            OP_LUI: begin
                instr_decoded_o.write_enable = 1'b1;
                instr_decoded_o.rs1_or_pc = RS1;
                instr_decoded_o.rs2_or_imm = IMM;
                instr_decoded_o.alu_op = ADD;
                instr_decoded_o.wb_origin = ALU;
                instr_decoded_o.store_to_mem = 1'b0;
                instr_decoded_o.jump_kind = BNONE;

                instr_decoded_o.addr_rs1 = '0; // Hardcoded to x0 which is hardwired to 0
            end

            OP_AUIPC: begin
                instr_decoded_o.write_enable = 1'b1;
                instr_decoded_o.rs1_or_pc = PC;
                instr_decoded_o.rs2_or_imm = IMM;
                instr_decoded_o.alu_op = ADD;
                instr_decoded_o.wb_origin = ALU;
                instr_decoded_o.store_to_mem = 1'b0;
                instr_decoded_o.jump_kind = BNONE;
            end

            OP_LW: begin
                instr_decoded_o.write_enable = 1'b1;
                instr_decoded_o.rs1_or_pc = RS1;
                instr_decoded_o.rs2_or_imm = IMM;
                instr_decoded_o.alu_op = ADD;
                instr_decoded_o.wb_origin = MEM;
                instr_decoded_o.store_to_mem = 1'b0;
                instr_decoded_o.jump_kind = BNONE;
            end
            OP_SW: begin
                instr_decoded_o.write_enable = 1'b0;
                instr_decoded_o.rs1_or_pc = RS1;
                instr_decoded_o.rs2_or_imm = IMM;
                instr_decoded_o.alu_op = ADD;
                instr_decoded_o.wb_origin = ALU; // Not really needed because not write enable on regfile
                instr_decoded_o.store_to_mem = 1'b1;
                instr_decoded_o.jump_kind = BNONE;
            end
            OP_BRANCH: begin
                instr_decoded_o.write_enable = 1'b0;
                instr_decoded_o.rs1_or_pc = PC;
                instr_decoded_o.rs2_or_imm = IMM;
                instr_decoded_o.alu_op = ADD;
                instr_decoded_o.wb_origin = ALU; // Not really needed because not write enable on regfile
                instr_decoded_o.store_to_mem = 1'b0;
                instr_decoded_o.jump_kind = BNONE;

                case (instr_i.btype.func3)
                    F3_BEQ: begin
                        instr_decoded_o.jump_kind = BEQ;
                    end
                    F3_BNE: begin
                        instr_decoded_o.jump_kind = BNE;
                    end
                    F3_BLT: begin
                        instr_decoded_o.jump_kind = BLT;
                    end
                    F3_BLTU: begin
                        instr_decoded_o.jump_kind = BLTU;
                    end
                    F3_BGE: begin
                        instr_decoded_o.jump_kind = BGE;
                    end
                    F3_BGEU: begin
                        instr_decoded_o.jump_kind = BGEU;
                    end
                    default: begin
                        instr_decoded_o.jump_kind = BNONE;
                        // As there is not write permission on the register
                        // file nor memory by forcing to not take the branch
                        // we can also have a NOP behavior
                    end
                endcase
            end
            OP_JAL: begin
                instr_decoded_o.write_enable = 1'b1;
                instr_decoded_o.rs1_or_pc = PC;
                instr_decoded_o.rs2_or_imm = IMM;
                instr_decoded_o.alu_op = ADD;
                instr_decoded_o.wb_origin = PC_4;
                instr_decoded_o.store_to_mem = 1'b0;
                instr_decoded_o.jump_kind = JUMP;
            end
            OP_JALR: begin
                instr_decoded_o.write_enable = 1'b1;
                instr_decoded_o.rs1_or_pc = RS1;
                instr_decoded_o.rs2_or_imm = IMM;
                instr_decoded_o.alu_op = ADD;
                instr_decoded_o.wb_origin = PC_4;
                instr_decoded_o.store_to_mem = 1'b0;
                instr_decoded_o.jump_kind = JUMP;
            end
            default: begin
                // illegal instruction treated as NOP being a x0 + x0
                // without write

                instr_decoded_o.write_enable = 1'b0;
                instr_decoded_o.rs1_or_pc = RS1;
                instr_decoded_o.rs2_or_imm = RS2;
                instr_decoded_o.addr_rs1 = '0;
                instr_decoded_o.addr_rs2 = '0;
                instr_decoded_o.addr_rd = '0;
                instr_decoded_o.alu_op = ADD;
                instr_decoded_o.wb_origin = ALU;
                instr_decoded_o.store_to_mem = 1'b0;
                instr_decoded_o.jump_kind = BNONE;
            end
        endcase

        // hardwire source registers to x0 if there is no reading from there
        // to avoid problems with hazard detection
        if ((instr_decoded_o.rs1_or_pc == PC && instr_decoded_o.jump_kind == BNONE) || instr_i.rtype.opcode == OP_JAL) begin
            instr_decoded_o.addr_rs1 = '0;
        end

        if ((instr_decoded_o.rs2_or_imm == IMM && instr_decoded_o.jump_kind == BNONE && instr_decoded_o.store_to_mem == 1'b0) || instr_i.rtype.opcode == OP_JAL) begin
            instr_decoded_o.addr_rs2 = '0;
        end
    end

endmodule
