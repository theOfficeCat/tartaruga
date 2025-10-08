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
        for (int i = 0; i < IMEM_POS; ++i) begin
            if (~rstn_i) begin
                dummy_instr_mem_q[i] <= i;
            end
            else begin
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
