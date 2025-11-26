module mul
    import tartaruga_pkg::*;
(
    input logic clk_i,
    input logic rstn_i,
    input bus32_t data_rs1_i,
    input bus32_t data_rs2_i,
    output bus32_t data_rd_o
);

    bus32_t data_rd_0, data_rd_1, data_rd_2, data_rd_3;

    assign data_rd_0 = data_rs1_i*data_rs2_i;

    always_ff @(posedge clk_i, negedge rstn_i) begin
        if (~rstn_i) begin
            data_rd_1 <= '0;
        end else begin
            data_rd_1 <= data_rd_0;
        end
    end

    always_ff @(posedge clk_i, negedge rstn_i) begin
        if (~rstn_i) begin
            data_rd_2 <= '0;
        end else begin
            data_rd_2 <= data_rd_1;
        end
    end

    always_ff @(posedge clk_i, negedge rstn_i) begin
        if (~rstn_i) begin
            data_rd_3 <= '0;
        end else begin
            data_rd_3 <= data_rd_2;
        end
    end

    assign data_rd_o = data_rd_3;

endmodule

