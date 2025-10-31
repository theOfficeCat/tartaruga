module dummy_dmem 
    import tartaruga_pkg::*;
(
    input logic clk_i,
    input logic rstn_i,
    input bus32_t pc_i,
    input bus32_t addr_i,
    input bus32_t data_wr_i,
    input logic we_mem_i,
    output bus32_t data_rd_o
);

    bus32_t [IMEM_POS-1:0] dummy_data_mem_d;
    bus32_t [IMEM_POS-1:0] dummy_data_mem_q;

    always_ff @(posedge clk_i, negedge rstn_i) begin
        if (~rstn_i) begin
            for (int i = 0; i < IMEM_POS; ++i) begin
                dummy_data_mem_q[i] <= '0;
            end
        end else begin
            for (int i = 0; i < IMEM_POS; ++i) begin
                dummy_data_mem_q[i] <= dummy_data_mem_d[i];
            end
        end

        if (addr_i == 32'h40000000 && we_mem_i == 1'b1) begin
            if (data_wr_i == 32'h1) begin
                $display("Execution succeeded at PC 0x%h\n", pc_i);
            end
            else if (data_wr_i == 32'h2) begin
                $display("Execution failed at PC 0x%h\n", pc_i);
            end
            else begin
                $display("Error at PC 0x%h\n", pc_i);
            end

            $finish(); // When writing to this position of memory we end the execution
        end
    end

    bus32_t addr_effective;


    assign addr_effective = (addr_i >> 2) & 32'hFFF;

    assign data_rd_o = dummy_data_mem_q[addr_effective];
    
    always_comb begin
        for (int i = 0; i < IMEM_POS; ++i) begin
            if (i == addr_effective && we_mem_i == 1'b1) begin
                dummy_data_mem_d[i] = data_wr_i;
            end
            else begin
                dummy_data_mem_d[i] = dummy_data_mem_q[i];
            end
        end
    end

endmodule
