module store_buffer
    import tartaruga_pkg::*;
(
    input  logic              clk_i,
    input  logic              rstn_i,

    // From MEM stage
    input  exe_to_mem_t       exe_to_mem_i,
    input  bus32_t            data_i,
    input  bus32_t            addr_i,
    input  logic              valid_i,

    // To DMem
    output logic              req_valid_o,
    input  logic              req_ready_i,
    output bus32_t            addr_o,
    output bus32_t            data_wr_o,

    // From DMem
    input  logic              rsp_valid_i,
    output logic              rsp_ready_o,

    input  logic              store_buffer_commit_i,
    input  store_buffer_idx_t store_buffer_idx_commit_i,

    input  logic              store_buffer_discard_i,
    input  store_buffer_idx_t store_buffer_idx_discard_i,

    output logic              full_o
);

    typedef struct packed {
        exe_to_mem_t  exe_to_mem;
        bus32_t       data;
        bus32_t       addr;
        logic         valid;
        logic         committed;
        logic         discard;
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
        head_ptr_d = head_ptr_q;
        tail_ptr_d = tail_ptr_q;
        req_valid_o = 1'b0;
        addr_o = '0;
        data_wr_o = '0;
        rsp_ready_o = 1'b0;

        for (int i = 0; i < STORE_BUFFER_SIZE; i++) begin
            store_buffer_d[i] = store_buffer_q[i];
        end

        if (valid_i) begin
            // Enqueue new store
            store_buffer_d[tail_ptr_q] = '{
                exe_to_mem: exe_to_mem_i,
                data: data_i,
                addr: addr_i,
                valid: 1'b1,
                committed: 1'b0,
                discard: 1'b0
            };
            tail_ptr_d = (tail_ptr_q + 1) % STORE_BUFFER_SIZE;
        end

        // Mark store as committed
        if (store_buffer_commit_i) begin
            store_buffer_d[store_buffer_idx_commit_i].committed = 1'b1;
        end

        // Mark store as discarded
        if (store_buffer_discard_i) begin
            store_buffer_d[store_buffer_idx_discard_i].discard = 1'b1;
        end

        // Issue store to DMem
        if (store_buffer_q[head_ptr_q].valid &&
            store_buffer_q[head_ptr_q].committed &&
            !store_buffer_q[head_ptr_q].discard) begin
            req_valid_o = 1'b1;
            addr_o = store_buffer_q[head_ptr_q].addr;
            data_wr_o = store_buffer_q[head_ptr_q].data;

            if (req_ready_i && rsp_valid_i) begin
                // Store completed
                store_buffer_d[head_ptr_q].valid = 1'b0;
                head_ptr_d = (head_ptr_q + 1) % STORE_BUFFER_SIZE;
                rsp_ready_o = 1'b1;
            end
        end

        // Remove discarded stores
        if (store_buffer_q[head_ptr_q].valid &&
            store_buffer_q[head_ptr_q].discard) begin
            store_buffer_d[head_ptr_q].valid = 1'b0;
            head_ptr_d = (head_ptr_q + 1) % STORE_BUFFER_SIZE;
        end
    end

    assign full_o = (tail_ptr_q == head_ptr_q) && store_buffer_q[head_ptr_q].valid;

endmodule
