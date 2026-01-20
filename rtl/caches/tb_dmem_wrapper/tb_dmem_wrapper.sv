module tb_dmem_wrapper;
    typedef logic [31:0] bus32_t;

    logic clk_i;
    logic rstn_i;

    logic       req_valid_i;
    logic       req_ready_o;
    bus32_t     addr_i;
    logic       we_i;
    logic [127:0] data_wr_i;

    logic       rsp_valid_o;
    logic       rsp_ready_i;
    bus32_t     rsp_mem_addr_o;
    logic [127:0] data_line_o;

    dmem_wrapper imem_wrapper (
        .clk_i(clk_i),
        .rstn_i(rstn_i),
        .req_valid_i(req_valid_i),
        .req_ready_o(req_ready_o),
        .addr_i(addr_i),
        .we_i(we_i),
        .data_wr_i(data_wr_i),
        .rsp_valid_o(rsp_valid_o),
        .rsp_ready_i(rsp_ready_i),
        .rsp_mem_addr_o(rsp_mem_addr_o),
        .data_line_o(data_line_o)
    );

    initial clk_i = 0;
    always #5 clk_i = ~clk_i;

    initial begin
        $dumpfile("wave.fst");
        $dumpvars(0, tb_dmem_wrapper);

        rstn_i = 0;

        #20;

        rstn_i = 1;

        @(negedge clk_i);

        req_valid_i = 1;
        we_i = 1;
        addr_i = 32'h00002000;
        data_wr_i = 128'hDEADBEEF_CAFEBABE_12345678_9ABCDEF0;

        @(negedge clk_i);
        req_valid_i = 0;

        repeat (20) @(negedge clk_i);

        req_valid_i = 1;
        we_i = 0;
        addr_i = 32'h00002000;
        @(negedge clk_i);
        req_valid_i = 0;
        repeat (20) @(negedge clk_i);



        $finish;
    end

endmodule
