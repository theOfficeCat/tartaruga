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
    input  logic [127:0]   data_wr_i,
    output logic     rsp_valid_o,
    input  logic     rsp_ready_i,
    output bus32_t   rsp_mem_addr_o,
    output logic [127:0] data_line_o
);

    localparam int LAT = 5;

    logic req_valid_pipe [LAT-1:0];
    bus32_t req_addr_pipe [LAT-1:0];
    logic we_pipe [LAT-1:0];
    logic [127:0] data_wr_pipe [LAT-1:0];

    logic rsp_valid_pipe [LAT-1:0];
    bus32_t rsp_mem_addr_pipe [LAT-1:0];
    logic [127:0] data_pipe [LAT-1:0];

    always_ff @(posedge clk_i or negedge rstn_i) begin
        if (!rstn_i) begin
            for (int i = 0; i < LAT; i++) begin
                req_valid_pipe[i] <= 1'b0;
                req_addr_pipe[i] <= '0;
                we_pipe[i] <= 1'b0;
                data_wr_pipe[i] <= '0;
            end
        end else begin
            // Shift pipeline stages
            for (int i = LAT-1; i > 0; i--) begin
                req_valid_pipe[i] <= req_valid_pipe[i-1];
                req_addr_pipe[i] <= req_addr_pipe[i-1];
                we_pipe[i] <= we_pipe[i-1];
                data_wr_pipe[i] <= data_wr_pipe[i-1];

                rsp_valid_pipe[i] <= rsp_valid_pipe[i-1];
                rsp_mem_addr_pipe[i] <= rsp_mem_addr_pipe[i-1];
                data_pipe[i] <= data_pipe[i-1];
            end

            // Load new request
            req_valid_pipe[0] <= req_valid_i;
            req_addr_pipe[0] <= addr_i;
            we_pipe[0] <= we_i;
            data_wr_pipe[0] <= data_wr_i;

            // Process memory operation
            if (req_valid_pipe[LAT-1]) begin
                if (we_pipe[LAT-1]) begin
                    for (int i = 0; i < 4; i++) begin
                        write_mem(req_addr_pipe[LAT-1] + i*4, data_wr_pipe[LAT-1][i*32 +: 32]);
                    end
                end else begin
                    logic [127:0] read_data;
                    for (int i = 0; i < 4; i++) begin
                        read_data[i*32 +: 32] = read_mem(req_addr_pipe[LAT-1] + i*4);
                    end
                    data_pipe[0] <= read_data;
                end
                rsp_mem_addr_pipe[0] <= req_addr_pipe[LAT-1];
                rsp_valid_pipe[0] <= 1'b1;
            end else begin
                rsp_valid_pipe[0] <= 1'b0;
            end
        end
    end

    always_comb begin
        req_ready_o = 1'b1;

        for (int i = 0; i < LAT; i++) begin
            req_ready_o &= ~req_valid_pipe[i];
        end

        for (int i = 0; i < LAT; i++) begin
            req_ready_o &= ~rsp_valid_pipe[i];
        end
    end

    assign data_line_o     = data_pipe[LAT-1];
    assign rsp_valid_o = rsp_valid_pipe[LAT-1];
    assign rsp_mem_addr_o = rsp_mem_addr_pipe[LAT-1];

endmodule
