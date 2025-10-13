module dummy_imem 
    import tartaruga_pkg::*;
(
    input logic clk_i,
    input logic rstn_i,
    input bus32_t pc_i,
    output bus32_t instr_o
);

    bus32_t [IMEM_POS-1:0] dummy_instr_mem_d;
    bus32_t [IMEM_POS-1:0] dummy_instr_mem_q;

    always_ff @(posedge clk_i, negedge rstn_i) begin
        if (~rstn_i) begin
            dummy_instr_mem_q[0] <= 32'h000F50B7;
            dummy_instr_mem_q[1] <= 32'h00002117;
            dummy_instr_mem_q[2] <= 32'hFFF08193;
            dummy_instr_mem_q[3] <= 32'h00004237;
            for (int i = 4; i < IMEM_POS; ++i) begin
                dummy_instr_mem_q[i] <= '0;
            end
        end else begin
            for (int i = 0; i < IMEM_POS; ++i) begin
                dummy_instr_mem_q[i] <= dummy_instr_mem_d[i];
            end
        end
    end

    assign instr_o = dummy_instr_mem_q[(pc_i >> 2) & 32'hFFF];
    
    always_comb begin
        for (int i = 0; i < IMEM_POS; ++i) begin
            dummy_instr_mem_d[i] = dummy_instr_mem_q[i];
        end
    end

endmodule
