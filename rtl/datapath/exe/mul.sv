module mul
    import tartaruga_pkg::*;
(
    input logic clk_i,
    input logic rstn_i,
    input bus32_t data_rs1_i,
    input bus32_t data_rs2_i,
    output bus32_t data_rd_o
);

    bus32_t result;

    assign result = data_rs1_i*data_rs2_i;

    // 5 cycles delay


    bus32_t [EXE_STAGES_MULT-2:0] delay;

    always_ff @(negedge rstn_i, posedge clk_i) begin
        if (~rstn_i) begin
            delay <= '0;
        end else begin
            delay[0] <= result;
            for (int i = 1; i < EXE_STAGES_MULT-1; i++) begin
                delay[i] <= delay[i-1];
            end
        end
    end

    assign data_rd_o = delay[EXE_STAGES_MULT-2];

endmodule
