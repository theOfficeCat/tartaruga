module tb_new_dcache;
    import tartaruga_pkg::*;

    logic clk_i;
    logic rstn_i;

    bus32_t addr_i;

    bus32_t data_wr_i;
    logic we_i;
    logic valid_i;
    bus32_t data_rd_o;
    logic ready_o;
    bus32_t mem_addr_o;
    logic mem_req_valid_o;
    logic mem_req_ready_i;
    logic [127:0] mem_data_line_i;
    logic mem_we_o;
    logic [127:0] mem_data_wr_o;
    logic mem_rsp_valid_i;
    logic mem_rsp_ready_o;
    bus32_t mem_rsp_addr_i;

    new_dcache dut (
        .clk_i(clk_i),
        .rstn_i(rstn_i),
        .addr_i(addr_i),
        .data_wr_i(data_wr_i),
        .we_i(we_i),
        .valid_i(valid_i),
        .data_rd_o(data_rd_o),
        .ready_o(ready_o),
        .mem_addr_o(mem_addr_o),
        .mem_req_valid_o(mem_req_valid_o),
        .mem_req_ready_i(mem_req_ready_i),
        .mem_data_line_i(mem_data_line_i),
        .mem_we_o(mem_we_o),
        .mem_data_wr_o(mem_data_wr_o),
        .mem_rsp_valid_i(mem_rsp_valid_i),
        .mem_rsp_ready_o(mem_rsp_ready_o),
        .mem_rsp_addr_i(mem_rsp_addr_i)
    );

    initial clk_i = 0;
    always #5 clk_i = ~clk_i;

    initial begin
        $dumpfile("wave.fst");
        $dumpvars(0, tb_new_dcache);

        rstn_i = 0;
        #20;
        rstn_i = 1;
        mem_req_ready_i = 1'b1;

        @(negedge clk_i);

        valid_i = 1;
        we_i = 0;
        addr_i = 32'h00001000;

        @(negedge clk_i);
        @(negedge clk_i);
        @(negedge clk_i);

        mem_rsp_valid_i = 1;
        mem_data_line_i = 128'h0123456789ABCDEF0123456789ABCDEF;

        @(negedge clk_i);
        mem_rsp_valid_i = 0;
        @(negedge clk_i);

        valid_i = 0;
        addr_i = '0;

        @(negedge clk_i);
        @(negedge clk_i);

        valid_i = 1;
        we_i = 0;
        addr_i = 32'h0001000;

        @(negedge clk_i);
        @(negedge clk_i);
        @(negedge clk_i);

        valid_i = 1;
        we_i = 0;
        addr_i = 32'h00002000;

        @(negedge clk_i);
        @(negedge clk_i);
        @(negedge clk_i);

        mem_rsp_valid_i = 1;
        mem_data_line_i = 128'hFEDCBA9876543210FEDCBA9876543210;

        @(negedge clk_i);
        mem_rsp_valid_i = 0;
        @(negedge clk_i);

        valid_i = 0;
        addr_i = '0;

        @(negedge clk_i);
        @(negedge clk_i);


        @(negedge clk_i);
        @(negedge clk_i);
        @(negedge clk_i);
        @(negedge clk_i);
        @(negedge clk_i);

        rstn_i = 0;
        #20;
        rstn_i = 1;
        mem_req_ready_i = 1'b0;


        @(negedge clk_i);

        valid_i = 1;
        we_i = 1;
        addr_i = 32'h00004000;
        data_wr_i = 32'h89ABCDEF;
        @(negedge clk_i);
        @(negedge clk_i);
        @(negedge clk_i);

        mem_rsp_valid_i = 1;
        mem_data_line_i = 128'hFEDCBA9876543210FEDCBA9876543210;
        @(negedge clk_i);
        mem_rsp_valid_i = 0;
        @(negedge clk_i);
        @(negedge clk_i);
        @(negedge clk_i);

        mem_req_ready_i = 1'b1;

        @(negedge clk_i);
        valid_i = 1'b0;

        @(negedge clk_i);

        valid_i = 1;
        we_i = 1;
        addr_i = 32'h00004008;
        data_wr_i = 32'h01234567;
        @(negedge clk_i);
        @(negedge clk_i);
        @(negedge clk_i);

        mem_rsp_valid_i = 1;
        mem_data_line_i = 128'hFEDCBA9876543210FEDCBA9876543210;
        @(negedge clk_i);
        mem_rsp_valid_i = 0;
        @(negedge clk_i);
        @(negedge clk_i);
        @(negedge clk_i);

        mem_req_ready_i = 1'b1;

        @(negedge clk_i);
        valid_i = 1'b0;

        repeat(20) @(negedge clk_i);



        $finish;
    end
endmodule
