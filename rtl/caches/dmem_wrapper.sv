`ifdef TB
    function int read_mem(input int addr);
        return addr;
    endfunction
    function void write_mem(input int addr, input int data);
        $display("Write to addr %h: %h", addr, data);
    endfunction
`else
    import "DPI-C" function int read_mem(input int addr);
    import "DPI-C" function void write_mem(input int addr, input int data);
`endif

module dmem_wrapper
    import tartaruga_pkg::*;
(
    input  logic     clk_i,
    input  logic     rstn_i,
    input  logic     req_valid_i,
    output logic     req_ready_o,
    input  bus32_t   addr_i,
    input  logic     we_i,
    input  bus32_t   data_wr_i,
    output logic     rsp_valid_o,
    input  logic     rsp_ready_i,
    output bus32_t   rsp_mem_addr_o,
    output logic [127:0] data_line_o
);

    localparam int LAT = 5;

    bus32_t req_addr_pipe [LAT-1:0];
    logic req_valid_pipe [LAT-1:0];

    logic [127:0] data_pipe [LAT-1:0];
    logic         valid_pipe [LAT-1:0];
    bus32_t       rsp_mem_addr_pipe [LAT-1:0];
    logic         we_pipe [LAT-1:0];
    bus32_t       data_wr_pipe [LAT-1:0];

    always_comb begin
        req_ready_o = 1'b1;
        for (int i = 0; i < LAT; i++) begin
            req_ready_o &= ~valid_pipe[i];
        end
        for (int i = 0; i < LAT; i++) begin
            req_ready_o &= ~req_valid_pipe[i];
        end
    end

    assign data_line_o = data_pipe[LAT-1];
    assign rsp_valid_o = valid_pipe[LAT-1];
    assign rsp_mem_addr_o = rsp_mem_addr_pipe[LAT-1];

    always_ff @(posedge clk_i or negedge rstn_i) begin
        if (!rstn_i) begin
            for (int i = 0; i < LAT; i++) begin
                data_pipe[i]  <= '0;
                valid_pipe[i] <= 1'b0;
                rsp_mem_addr_pipe[i] <= '0;
                req_addr_pipe[i] <= '0;
                req_valid_pipe[i] <= 1'b0;
                we_pipe[i] <= 1'b0;
                data_wr_pipe[i] <= '0;
            end
        end else begin
            if (rsp_valid_o && rsp_ready_i) begin
                valid_pipe[LAT-1] <= 1'b0;
            end

            for (int i = LAT-1; i > 0; i--) begin
                if (!valid_pipe[i]) begin
                    valid_pipe[i] <= valid_pipe[i-1];
                    data_pipe[i]  <= data_pipe[i-1];
                    rsp_mem_addr_pipe[i] <= rsp_mem_addr_pipe[i-1];
                    we_pipe[i] <= we_pipe[i-1];
                    data_wr_pipe[i] <= data_wr_pipe[i-1];
                    valid_pipe[i-1] <= 1'b0;
                end

                req_addr_pipe[i] <= req_addr_pipe[i-1];
                req_valid_pipe[i] <= req_valid_pipe[i-1];
            end

            if (req_valid_pipe[LAT-1]) begin
                automatic int base_idx = (addr_i >> 2) & 32'hFFF;

                if (we_pipe[LAT-1]) begin
                    write_mem(req_addr_pipe[LAT-1], data_pipe[LAT-1]);

                    data_pipe[0] <= {
                        read_mem({req_addr_pipe[LAT-1][31:4], 4'hC}),
                        read_mem({req_addr_pipe[LAT-1][31:4], 4'h8}),
                        read_mem({req_addr_pipe[LAT-1][31:4], 4'h4}),
                        read_mem({req_addr_pipe[LAT-1][31:4], 4'h0})
                    };
                end else begin
                    data_pipe[0] <= {
                        read_mem({req_addr_pipe[LAT-1][31:4], 4'hC}),
                        read_mem({req_addr_pipe[LAT-1][31:4], 4'h8}),
                        read_mem({req_addr_pipe[LAT-1][31:4], 4'h4}),
                        read_mem({req_addr_pipe[LAT-1][31:4], 4'h0})
                    };
                end

                valid_pipe[0] <= req_valid_pipe[LAT-1];
                rsp_mem_addr_pipe[0] <= {req_addr_pipe[LAT-1][31:4], 4'h0};
                we_pipe[0] <= we_i;
                data_wr_pipe[0] <= data_wr_i;
            end

            req_addr_pipe[0] <= addr_i;
            req_valid_pipe[0] <= req_valid_i;
        end
    end

endmodule
