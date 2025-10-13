module immediate
    import tartaruga_pkg::*;
    import riscv_pkg::*;
(
    input instr_data_t instr_i,
    output bus32_t imm_o
);

    always_comb begin
        case (instr_i.instr.rtype.opcode)
            OP_LUI: begin
                imm_o = {{12{instr_i.instr.utype.imm[31]}}, instr_i.instr.utype.imm};
            end
            default: begin
                imm_o = '0;
            end
        endcase
    end

endmodule
