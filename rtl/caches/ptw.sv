module ptw 
    import tartaruga_pkg::*;
(
    input logic clk_i,
    input logic rstn_i,
    input logic tlb_miss_i,
    input logic [31:0] virt_addr_i,
    input logic [31:0] rm5_i,
    output logic mem_req_valid_o,
    output logic [31:0] mem_req_addr_o,
    input logic mem_req_ready_i,
    input logic mem_rsp_valid_i,
    input logic [127:0] mem_rsp_data_i,
    output logic tlb_update_o,
    output logic [19:0] update_vpn_o,
    output logic [19:0] update_ppn_o,
    output logic ptw_busy_o
);

    typedef enum logic [2:0] {
        IDLE,
        READ_L1,
        WAIT_L1,
        READ_L2,
        WAIT_L2,
        UPDATE,
        DEFAULT
    } ptw_state_t;

    ptw_state_t state, next_state;
    logic [9:0] l1_index;
    logic [9:0] l2_index;
    logic [19:0] l2_base;
    logic [19:0] current_vpn;

    always_ff @(posedge clk_i or negedge rstn_i) begin
        if (!rstn_i) begin
            state <= IDLE;
        end else begin
            state <= next_state;
        end
    end

    always_comb begin
        next_state = state;
        case (state)
            IDLE: begin
                if (tlb_miss_i) begin
                    next_state = READ_L1;
                end
            end
            READ_L1: begin
                if (mem_req_ready_i) begin
                    next_state = WAIT_L1;
                end
            end
            WAIT_L1: begin
                if (mem_rsp_valid_i) begin
                    next_state = READ_L2;
                end
            end
            READ_L2: begin
                if (mem_req_ready_i) begin
                    next_state = WAIT_L2;
                end
            end
            WAIT_L2: begin
                if (mem_rsp_valid_i) begin
                    next_state = UPDATE;
                end
            end
            UPDATE: begin
                next_state = IDLE;
            end
            default: begin
                next_state = IDLE;
            end
        endcase
    end

    always_ff @(posedge clk_i) begin
        if (tlb_miss_i && state == IDLE) begin
            l1_index <= virt_addr_i[31:22];
            l2_index <= virt_addr_i[21:12];
            current_vpn <= virt_addr_i[31:12];
        end
        if (state == WAIT_L1 && mem_rsp_valid_i) begin
            l2_base <= mem_rsp_data_i[19:0];
        end
    end

    assign mem_req_valid_o = (state == READ_L1) || (state == READ_L2);
    assign mem_req_addr_o = (state == READ_L1) ? 
                           {12'b0, rm5_i[19:0]} + (l1_index << 2) :
                           {12'b0, l2_base} + (l2_index << 2);

    assign tlb_update_o = (state == UPDATE);
    assign update_vpn_o = current_vpn;
    assign update_ppn_o = (state == UPDATE) ? mem_rsp_data_i[19:0] : '0;
    assign ptw_busy_o = (state != IDLE);

endmodule
