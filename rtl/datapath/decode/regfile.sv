module regfile
    import tartaruga_pkg::*;
(
    input logic clk_i,
    input logic rstn_i,
    input reg_addr_t addr_rs1_i,
    input reg_addr_t addr_rs2_i,
    input reg_addr_t addr_rd_i,
    input bus32_t data_rd_i,
    input logic write_enable_i,
    output bus32_t data_rs1_o,
    output bus32_t data_rs2_o
);

bus32_t [REG_COUNT-1:0] registers_d;
bus32_t [REG_COUNT-1:0] registers_q;

always_ff @(posedge clk_i, negedge rstn_i) begin
    if (~rstn_i) begin
        for (int i = 0; i < REG_COUNT-1; ++i) begin
            registers_q[i] <= '0;
        end
    end
    else begin
        for (int i = 1; i < REG_COUNT-1; ++i) begin
            if ((reg_addr_t'(i) == addr_rd_i) && (write_enable_i == 1'b1)) begin
                registers_q[i] <= data_rd_i;
            end
            else begin
                registers_q[i] <= registers_d[i];
            end
        end
    end
end

assign data_rs1_o = registers_q[addr_rs1_i];
assign data_rs2_o = registers_q[addr_rs2_i];
assign registers_d = registers_q;

endmodule
