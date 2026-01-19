module store_buffer
    import tartaruga_pkg::*;
(
    input  logic                        clk_i,
    input  logic                        rstn_i,

    input  bus32_t                      data_i,
    input  bus32_t                      addr_i,
    input  logic                        load_i,
    output logic                        bypass_o,
    output bus32_t                      data_rd_o,

    input  logic                        req_valid_i,
    output logic                        req_ready_o,

    output logic                        rsp_valid_o,
    input  logic                        rsp_ready_i,
    output bus32_t                      addr_o,
    output bus32_t                      data_wr_o,

    output store_buffer_idx_t           store_buffer_idx_o,

    input  logic                        store_buffer_commit_i,
    input  store_buffer_idx_t           store_buffer_idx_commit_i,

    input logic [STORE_BUFFER_SIZE-1:0] store_buffer_discard_i
);

    typedef struct packed {
        bus32_t       data;
        bus32_t       addr;
        logic         valid;
        logic         committed;
        logic         discarded;
    } store_buffer_entry_t;

    store_buffer_entry_t store_buffer_q [STORE_BUFFER_SIZE-1:0];
    store_buffer_entry_t store_buffer_d [STORE_BUFFER_SIZE-1:0];

    rob_idx_t head_ptr_q, head_ptr_d;
    rob_idx_t tail_ptr_q, tail_ptr_d;

    // Sequential logic
    always_ff @(posedge clk_i or negedge rstn_i) begin
        if (!rstn_i) begin
            head_ptr_q <= '0;
            tail_ptr_q <= '0;
            for (int i = 0; i < STORE_BUFFER_SIZE; i++) begin
                store_buffer_q[i] <= '{default: '0};
            end
        end else begin
            head_ptr_q <= head_ptr_d;
            tail_ptr_q <= tail_ptr_d;
            for (int i = 0; i < STORE_BUFFER_SIZE; i++) begin
                store_buffer_q[i] <= store_buffer_d[i];
            end
        end
    end


    // Combinational logic
    always_comb begin
        // Default assignments
        for (int i = 0; i < STORE_BUFFER_SIZE; i++) begin
            store_buffer_d[i] = store_buffer_q[i];
        end
        head_ptr_d = head_ptr_q;
        tail_ptr_d = tail_ptr_q;

        // Handle new store buffer entry
        if (req_valid_i && req_ready_o) begin
            store_buffer_d[tail_ptr_q] = '{
                data       : data_i,
                addr       : addr_i,
                valid      : 1'b1,
                committed  : 1'b0,
                discarded  : 1'b0
            };
            tail_ptr_d = (tail_ptr_q + 1) % STORE_BUFFER_SIZE;
        end

        // Send to dcache if head entry is committed and not discarded
        if (store_buffer_q[head_ptr_q].valid && store_buffer_q[head_ptr_q].committed) begin
            rsp_valid_o = 1'b1;
            addr_o = store_buffer_q[head_ptr_q].addr;
            data_wr_o = store_buffer_q[head_ptr_q].data;
            // Mark entry as invalid when the dcache accepts it
            if (rsp_ready_i) begin
                store_buffer_d[head_ptr_q].valid = 1'b0;
                head_ptr_d = (head_ptr_q + 1) % STORE_BUFFER_SIZE;
            end else begin
                head_ptr_d = head_ptr_q;
            end
        end else if (store_buffer_q[head_ptr_q].valid && store_buffer_q[head_ptr_q].discarded) begin
            // Discard the entry
            store_buffer_d[head_ptr_q].valid = 1'b0;
            head_ptr_d = (head_ptr_q + 1) % STORE_BUFFER_SIZE;
            rsp_valid_o = 1'b0;
            addr_o = '0;
            data_wr_o = '0;
        end else begin
            rsp_valid_o = 1'b0;
            addr_o = '0;
            data_wr_o = '0;
        end

        // Handle commit signal
        if (store_buffer_commit_i) begin
            store_buffer_d[store_buffer_idx_commit_i].committed = 1'b1;
        end
        // Handle discard signals
        for (int i = 0; i < STORE_BUFFER_SIZE; i++) begin
            if (store_buffer_discard_i[i]) begin
                store_buffer_d[i].discarded = 1'b1;
            end
        end
    end

    assign req_ready_o = !((tail_ptr_q == head_ptr_q) && store_buffer_q[head_ptr_q].valid);
    assign store_buffer_idx_o = tail_ptr_q;

    always_comb begin
        // Default read data
        data_rd_o = '0;
        bypass_o = 1'b0;
        // Search for matching address in store buffer
        for (store_buffer_idx_t i = (tail_ptr_q - 1)%STORE_BUFFER_SIZE; i != tail_ptr_q; i = (i - 1 + STORE_BUFFER_SIZE)%STORE_BUFFER_SIZE) begin
            if (store_buffer_q[i].valid && (store_buffer_q[i].addr == addr_i)) begin
                data_rd_o = store_buffer_q[i].data;
                bypass_o = 1'b1;
                break;
            end
        end
    end

endmodule
