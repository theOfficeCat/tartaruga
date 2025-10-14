module immediate
    import tartaruga_pkg::*;
    import riscv_pkg::*;
(
    input instr_data_t instr_i,
    output bus32_t imm_o
);

    always_comb begin
        case (instr_i.instr.rtype.opcode)
            OP_LUI, OP_AUIPC: begin
                imm_o = {instr_i.instr.utype.imm, 12'b0};
            end
            OP_ALU_I, OP_LW: begin // All the instructions use the sign-extended value of the immediate. As the sifts ose only the 5 LSB and the MSB of the imm is 0 we can reuse the same extender
                imm_o = {{20{instr_i.instr.itype.imm[31]}}, instr_i.instr.itype.imm};
            end
            OP_SW: begin
                imm_o = {{20{instr_i.instr.stype.imm5[31]}}, instr_i.instr.stype.imm5, instr_i.instr.stype.imm0};
            end
            default: begin
                imm_o = '0;
            end
        endcase
    end

endmodule
