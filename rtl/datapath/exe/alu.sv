module alu
    import tartaruga_pkg::*;
(
    input bus32_t data_rs1_i,
    input bus32_t data_rs2_i,
    input alu_op_t alu_op_i,
    output bus32_t data_rd_o
);
    always_comb begin
        case (alu_op_i)
            ADD: begin
                data_rd_o = data_rs1_i + data_rs2_i;
            end
            default: begin
                data_rd_o = '0;
            end
        endcase
    end
endmodule
