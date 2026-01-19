/*`ifdef TB
    function int read_mem(input int pc);
        return pc + 32'h1000;
    endfunction
`else
    import "DPI-C" function int read_mem(input int pc);
`endif
*/
module imem_wrapper
    import tartaruga_pkg::*;
(
    input  logic     clk_i,
    input  logic     rstn_i,

    // Request channel
    input  logic     req_valid_i,
    output logic     req_ready_o,
    input  bus32_t   pc_i,

    // Response channel
    output logic     rsp_valid_o,
    input  logic     rsp_ready_i,
    output bus32_t   rsp_mem_addr_o,
    output logic [511:0] instr_line_o
);

    bus32_t imem [IMEM_POS-1:0];

    initial begin
        for (int i = 0; i < IMEM_POS; ++i) begin
            imem[i] = read_mem(i);
        end
    end

    localparam int LAT = 5;

    bus32_t req_addr_pipe [LAT-1:0];
    logic req_valid_pipe [LAT-1:0];



    logic [511:0] data_pipe [LAT-1:0];
    logic   valid_pipe [LAT-1:0];
    bus32_t rsp_mem_addr_pipe [LAT-1:0];

    // Pipeline can accept a new request if unit is free
    always_comb begin
        req_ready_o = 1'b1;

        for (int i = 0; i < LAT; i++) begin
            req_ready_o &= ~valid_pipe[i];
        end
        for (int i = 0; i < LAT; i++) begin
            req_ready_o &= ~req_valid_pipe[i];
        end
    end

    assign instr_line_o     = data_pipe[LAT-1];
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
                    valid_pipe[i-1] <= 1'b0;
                end

                req_addr_pipe[i] <= req_addr_pipe[i-1];
                req_valid_pipe[i] <= req_valid_pipe[i-1];
            end

            if (req_valid_pipe[LAT-1]) begin
                automatic int base_idx = (req_addr_pipe[LAT-1] >> 2) & 32'hFFF;
                data_pipe[0] <= {
                    read_mem(req_addr_pipe[LAT-1] + 12 + 48),
                    read_mem(req_addr_pipe[LAT-1] + 8 + 48),
                    read_mem(req_addr_pipe[LAT-1] + 4 + 48),
                    read_mem(req_addr_pipe[LAT-1] + 48),
                    read_mem(req_addr_pipe[LAT-1] + 12 + 32),
                    read_mem(req_addr_pipe[LAT-1] + 8 + 32),
                    read_mem(req_addr_pipe[LAT-1] + 4 + 32),
                    read_mem(req_addr_pipe[LAT-1] + 32),
                    read_mem(req_addr_pipe[LAT-1] + 12 + 16),
                    read_mem(req_addr_pipe[LAT-1] + 8 + 16),
                    read_mem(req_addr_pipe[LAT-1] + 4 + 16),
                    read_mem(req_addr_pipe[LAT-1] + 16),
                    read_mem(req_addr_pipe[LAT-1] + 12),
                    read_mem(req_addr_pipe[LAT-1] + 8),
                    read_mem(req_addr_pipe[LAT-1] + 4),
                    read_mem(req_addr_pipe[LAT-1])
                };
                valid_pipe[0] <= 1'b1;
                rsp_mem_addr_pipe[0] <= req_addr_pipe[LAT-1];
            end

            req_addr_pipe[0] <= pc_i;
            req_valid_pipe[0] <= req_valid_i;
        end
    end

endmodule
