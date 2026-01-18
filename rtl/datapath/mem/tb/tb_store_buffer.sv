module tb_store_buffer;
    import tartaruga_pkg::*;
    logic              clk_i;
    logic              rstn_i;

    exe_to_mem_t       exe_to_mem_i;
    bus32_t            data_i;
    bus32_t            addr_i;
    logic              valid_i;

    logic              req_valid_o;
    logic              req_ready_i;
    bus32_t            addr_o;
    bus32_t            data_wr_o;

    logic              rsp_valid_i;
    logic              rsp_ready_o;

    logic              store_buffer_commit_i;
    store_buffer_idx_t store_buffer_idx_commit_i;

    logic              store_buffer_discard_i;
    store_buffer_idx_t store_buffer_idx_discard_i;

    logic              full_o;

    store_buffer dut (
        .clk_i(clk_i),
        .rstn_i(rstn_i),
        .exe_to_mem_i(exe_to_mem_i),
        .data_i(data_i),
        .addr_i(addr_i),
        .valid_i(valid_i),
        .req_valid_o(req_valid_o),
        .req_ready_i(req_ready_i),
        .addr_o(addr_o),
        .data_wr_o(data_wr_o),
        .rsp_valid_i(rsp_valid_i),
        .rsp_ready_o(rsp_ready_o),
        .store_buffer_commit_i(store_buffer_commit_i),
        .store_buffer_idx_commit_i(store_buffer_idx_commit_i),
        .store_buffer_discard_i(store_buffer_discard_i),
        .store_buffer_idx_discard_i(store_buffer_idx_discard_i),
        .full_o(full_o)
    );

    // Clock generation
    initial clk_i = 0;
    always #5 clk_i = ~clk_i;

    initial begin
        $dumpfile("tb_store_buffer.fst");
        $dumpvars(0, tb_store_buffer);

        // Initialize inputs
        rstn_i = 0;
        exe_to_mem_i = '{default: '0};
        data_i = '0;
        addr_i = '0;
        valid_i = 0;
        req_ready_i = 1;
        rsp_valid_i = 0;
        rsp_ready_o = 1;
        store_buffer_commit_i = 0;
        store_buffer_idx_commit_i = '0;
        store_buffer_discard_i = 0;
        store_buffer_idx_discard_i = '0;

        // Release reset
        #15;
        rstn_i = 1;

        // Add your testbench stimulus here

        data_i = 32'hDEADBEEF;
        addr_i = 32'h1000_0000;
        valid_i = 1;
        exe_to_mem_i = '{default: '0};

        @(posedge clk_i);
        valid_i = 0;

        @(posedge clk_i);

        data_i = 32'hCAFEBABE;
        addr_i = 32'h1000_0004;
        valid_i = 1;
        exe_to_mem_i = '{default: '0};

        @(posedge clk_i);
        valid_i = 0;

        @(posedge clk_i);

        data_i = 32'hBAADF00D;
        addr_i = 32'h1000_0008;
        valid_i = 1;
        exe_to_mem_i = '{default: '0};

        @(posedge clk_i);
        valid_i = 0;

        @(posedge clk_i);

        data_i = 32'hFEEDFACE;
        addr_i = 32'h1000_000C;
        valid_i = 1;
        exe_to_mem_i = '{default: '0};

        @(posedge clk_i);
        valid_i = 0;

        @(posedge clk_i);

        store_buffer_commit_i = 1;
        store_buffer_idx_commit_i = 1;

        @(posedge clk_i);

        store_buffer_commit_i = 0;

        store_buffer_discard_i = 1;
        store_buffer_idx_discard_i = 2;

        @(posedge clk_i);

        store_buffer_discard_i = 0;

        store_buffer_commit_i = 1;
        store_buffer_idx_commit_i = 3;

        repeat(5) @(posedge clk_i);

        store_buffer_commit_i = 1;
        store_buffer_idx_commit_i = 0;

        @(posedge clk_i);

        rsp_valid_i = 1;

        @(posedge clk_i);

        rsp_valid_i = 0;

        @(posedge clk_i);
        @(posedge clk_i);
        @(posedge clk_i);

        rsp_valid_i = 1;

        #100;
        $finish;
    end
endmodule
