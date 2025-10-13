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
            SUB: begin
                data_rd_o = data_rs1_i - data_rs2_i;
            end
            SLT: begin
                data_rd_o = {31'b0, ($signed(data_rs1_i) < $signed(data_rs2_i))};
            end
            SLTU: begin
                data_rd_o = {31'b0, (data_rs1_i < data_rs2_i)};
            end
            SLL: begin
                data_rd_o = data_rs1_i << data_rs2_i[4:0];
            end
            SRL: begin
                data_rd_o = data_rs1_i >> data_rs2_i[4:0];
            end
            SRA: begin
                data_rd_o = $signed(data_rs1_i) >>> data_rs2_i[4:0];
            end
            XOR: begin
                data_rd_o = data_rs1_i ^ data_rs2_i;
            end
            OR: begin
                data_rd_o = data_rs1_i | data_rs2_i;
            end
            AND: begin
                data_rd_o = data_rs1_i & data_rs2_i;
            end
            default: begin
                data_rd_o = '0;
            end
        endcase
    end
endmodule
