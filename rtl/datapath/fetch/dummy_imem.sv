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
            for (int i = 0; i < IMEM_POS; ++i) begin
                dummy_instr_mem_q[i] <= '0;
            end
            //dummy_instr_mem_q[0] <= 32'h000F50B7;
            //dummy_instr_mem_q[1] <= 32'h00002117;
            dummy_instr_mem_q[0] <= 32'h123450b7;
            dummy_instr_mem_q[1] <= 32'h67808093;
            dummy_instr_mem_q[2] <= 32'h87654137;
            dummy_instr_mem_q[3] <= 32'h32110113;
            dummy_instr_mem_q[4] <= 32'h002081b3;
            dummy_instr_mem_q[5] <= 32'h401101b3;
            dummy_instr_mem_q[6] <= 32'h001121b3;
            dummy_instr_mem_q[7] <= 32'h001131b3;
            dummy_instr_mem_q[8] <= 32'h001111b3;
            dummy_instr_mem_q[9] <= 32'h001151b3;
            dummy_instr_mem_q[10] <= 32'h401151b3;
            dummy_instr_mem_q[11] <= 32'h001141b3;
            dummy_instr_mem_q[12] <= 32'h001161b3;
            dummy_instr_mem_q[13] <= 32'h001171b3;
            dummy_instr_mem_q[14] <= 32'h10000213;
            dummy_instr_mem_q[15] <= 32'h02322023;
            dummy_instr_mem_q[16] <= 32'h00000033;
            dummy_instr_mem_q[17] <= 32'h00000033;
            dummy_instr_mem_q[18] <= 32'h00000033;
            dummy_instr_mem_q[19] <= 32'h00000033;
            dummy_instr_mem_q[20] <= 32'h02022283;
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
