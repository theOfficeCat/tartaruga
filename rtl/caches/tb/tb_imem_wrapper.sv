module tb_imem_wrapper;
    typedef logic [31:0] bus32_t;
    localparam int IMEM_POS = 4096;

    logic clk_i;
    logic rstn_i;

    logic       req_valid_i;
    logic       req_ready_o;
    bus32_t     pc_i;

    logic       rsp_valid_o;
    logic       rsp_ready_i;
    bus32_t     instr_o;

    imem_wrapper dut (
        .clk_i        (clk_i),
        .rstn_i       (rstn_i),
        .req_valid_i  (req_valid_i),
        .req_ready_o  (req_ready_o),
        .pc_i         (pc_i),
        .rsp_valid_o  (rsp_valid_o),
        .rsp_ready_i  (rsp_ready_i),
        .instr_o      (instr_o)
    );

    initial clk_i = 0;
    always #5 clk_i = ~clk_i;

    initial begin
        $dumpfile("wave.fst");
        $dumpvars(0, tb_imem_wrapper);

        rstn_i = 0;
        req_valid_i = 0;
        pc_i = '0;
        rsp_ready_i = 1;
        #20;
        rstn_i = 1;

        repeat (2) @(posedge clk_i);

        send_request(32'h0000_0004);
        repeat (2) @(posedge clk_i);
        send_request(32'h0000_0008);
        repeat (2) @(posedge clk_i);
        send_request(32'h0000_000C);
        repeat (2) @(posedge clk_i);
        send_request(32'h0000_0010);
        repeat (2) @(posedge clk_i);

        repeat (15) @(posedge clk_i);

        $finish;
    end

    task send_request(input bus32_t pc);
        begin
            $display("[%0t] Start of sending request", $time);
            pc_i <= pc;
            req_valid_i <= 1'b1;

            do @(posedge clk_i); while (!req_ready_o);
            @(posedge clk_i);
            req_valid_i <= 1'b0;
            $display("[%0t] End of sending request", $time);
        end
    endtask

    always @(posedge clk_i) begin
        if (rsp_valid_o && rsp_ready_i) begin
            $display("[%0t] RESP: INSTR=%h", $time, instr_o);
        end
    end

endmodule
