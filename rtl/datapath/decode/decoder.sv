module decoder
    import tartaruga_pkg::*;
    import riscv_pkg::*;
(
    input bus32_t pc_i,
    input instruction_t instr_i,
    output instr_data_t instr_decoded_o
);

    //assign instr_decoded_o = '0;

    always_comb begin
        instr_decoded_o.pc = pc_i;
        instr_decoded_o.instr = instr_i;
        instr_decoded_o.addr_rs1 = instr_i.rtype.rs1;
        instr_decoded_o.addr_rs2 = instr_i.rtype.rs2;
        instr_decoded_o.addr_rd = instr_i.rtype.rd;
        
        case (instr_i.rtype.opcode)
            OP_ALU_I: begin
                instr_decoded_o.write_enable = 1'b1;
                instr_decoded_o.rs1_or_pc = RS1;
                instr_decoded_o.rs2_or_imm = IMM;

                case (instr_i.rtype.func3)
                    F3_ADDI: begin
                        instr_decoded_o.alu_op = ADD;
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
                    end
                endcase
            end

            OP_ALU: begin
                instr_decoded_o.write_enable = 1'b1;
                instr_decoded_o.rs1_or_pc = RS1;
                instr_decoded_o.rs2_or_imm = RS2;

                case (instr_i.rtype.func3)
                    F3_ADDI: begin
                        instr_decoded_o.alu_op = ADD;
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
                    end
                endcase
            end

            OP_LUI: begin
                instr_decoded_o.write_enable = 1'b1;
                instr_decoded_o.rs1_or_pc = RS1;
                instr_decoded_o.rs2_or_imm = IMM;
                instr_decoded_o.alu_op = ADD;

                instr_decoded_o.addr_rs1 = '0; // Hardcoded to r0 which is hardwired to 0
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
            end
        endcase
    end

endmodule
