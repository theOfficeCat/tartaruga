module branch
    import tartaruga_pkg::*;
(
    input bus32_t data_rs1_i,
    input bus32_t data_rs2_i,
    input jump_kind_t jump_kind_i,
    output logic taken_o
);
    logic equal, less_signed, less_unsigned;

    assign equal = data_rs1_i == data_rs2_i;
    assign less_signed = $signed(data_rs1_i) < $signed(data_rs2_i);
    assign less_unsigned = data_rs1_i < data_rs2_i;

    always_comb begin
        case (jump_kind_i)
            BNONE: begin
                taken_o = 1'b0;
            end
            JUMP: begin
                taken_o = 1'b1;
            end
            BNE: begin
                taken_o = ~equal;
            end
            BEQ: begin
                taken_o = equal;
            end
            BLT: begin
                taken_o = less_signed;
            end
            BLTU: begin
                taken_o = less_unsigned;
            end
            BGE: begin
                taken_o = ~less_signed;
            end
            BGEU: begin
                taken_o = ~less_unsigned;
            end
            default: begin
                taken_o = 1'b0;
            end
        endcase
    end
endmodule
