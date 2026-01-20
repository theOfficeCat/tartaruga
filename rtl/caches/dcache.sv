module dcache
    import tartaruga_pkg::*;
    import riscv_pkg::*;
(
    input  logic clk_i,
    input  logic rstn_i,
    input  bus32_t addr_i,
    input  bus32_t data_wr_i,
    input  logic we_i,
    input  logic valid_i,
    output bus32_t data_rd_o,
    output logic ready_o,
    output bus32_t mem_addr_o,
    output logic mem_req_valid_o,
    input  logic mem_req_ready_i,
    input  logic [127:0] mem_data_line_i,
    output logic mem_we_o,
    output logic [127:0] mem_data_wr_o,
    input  logic mem_rsp_valid_i,
    output logic mem_rsp_ready_o,
    input  bus32_t mem_rsp_addr_i
);

    localparam int NUM_SETS = 16;
    localparam int ASSOCIATIVITY = 2;
    localparam int WORDS_PER_LINE = 4;
    localparam int INDEX_BITS = $clog2(NUM_SETS);
    localparam int OFFSET_BITS = 2 + $clog2(WORDS_PER_LINE);
    localparam int TAG_BITS = 32 - INDEX_BITS - OFFSET_BITS;
    localparam int LRU_COUNTER_BITS = $clog2(ASSOCIATIVITY);
    localparam int WORD_SEL_BITS = $clog2(WORDS_PER_LINE);

    typedef struct {
        logic valid;
        logic dirty;
        logic [TAG_BITS-1:0] tag;
        bus32_t data[WORDS_PER_LINE];
    } cache_line_t;

    cache_line_t cache_mem[NUM_SETS][ASSOCIATIVITY];
    logic [LRU_COUNTER_BITS-1:0] lru_counter[NUM_SETS];

    logic [INDEX_BITS-1:0] index;
    logic [TAG_BITS-1:0] tag_in;
    logic [WORD_SEL_BITS-1:0] word_offset;

    assign index = addr_i[OFFSET_BITS + INDEX_BITS - 1 : OFFSET_BITS];
    assign tag_in = addr_i[31 : OFFSET_BITS + INDEX_BITS];
    assign word_offset = addr_i[WORD_SEL_BITS+1:2];

    bus32_t line_aligned_addr;
    assign line_aligned_addr = {addr_i[31:OFFSET_BITS], {OFFSET_BITS{1'b0}}};
    assign mem_addr_o = line_aligned_addr;

    logic hit;
    logic [ASSOCIATIVITY-1:0] hit_way;
    logic [LRU_COUNTER_BITS-1:0] hit_way_sel;

    always_comb begin
        hit = 1'b0;
        hit_way = '0;
        hit_way_sel = '0;

        for (int i = 0; i < ASSOCIATIVITY; i++) begin
            if (cache_mem[index][i].valid && (cache_mem[index][i].tag == tag_in)) begin
                hit = 1'b1;
                hit_way[i] = 1'b1;
                hit_way_sel = i[LRU_COUNTER_BITS-1:0];
            end
        end
    end

    assign data_rd_o = (hit && !we_i) ? cache_mem[index][hit_way_sel].data[word_offset] : '0;

    typedef enum logic [1:0] {
        IDLE,
        READ_MISS,
        WRITE_BACK,
        WRITE_MISS
    } state_t;

    state_t state, next_state;

    logic [INDEX_BITS-1:0] pending_index;
    logic [TAG_BITS-1:0] pending_tag;
    logic [WORD_SEL_BITS-1:0] pending_offset;
    bus32_t pending_data_wr;
    logic pending_we;
    logic [$clog2(ASSOCIATIVITY)-1:0] victim_way;

    logic [127:0] victim_data_line;
    assign victim_data_line = {
        cache_mem[pending_index][victim_way].data[3],
        cache_mem[pending_index][victim_way].data[2],
        cache_mem[pending_index][victim_way].data[1],
        cache_mem[pending_index][victim_way].data[0]
    };

    // Señales de control
    logic cache_update;
    logic [INDEX_BITS-1:0] update_index;
    logic [$clog2(ASSOCIATIVITY)-1:0] update_way;

    assign ready_o = (state == IDLE) && (!valid_i || (valid_i && hit));

    assign mem_req_valid_o = (state == READ_MISS || state == WRITE_MISS || state == WRITE_BACK) && mem_req_ready_i;
    assign mem_we_o = (state == WRITE_BACK);

    assign mem_data_wr_o = (state == WRITE_BACK) ? victim_data_line : data_wr_i;

    assign mem_rsp_ready_o = 1'b1;

    always_comb begin
        victim_way = '0;
        for (int i = 0; i < ASSOCIATIVITY; i++) begin
            if (lru_counter[pending_index] == (LRU_COUNTER_BITS)'(ASSOCIATIVITY-1)) begin
                victim_way = i[$clog2(ASSOCIATIVITY)-1:0];
            end
        end
    end

    bus32_t received_line[WORDS_PER_LINE];

    always_comb begin
        for (int i = 0; i < WORDS_PER_LINE; i++) begin
            received_line[i] = mem_data_line_i[(i*32)+:32];
        end
    end

    always_ff @(posedge clk_i or negedge rstn_i) begin
        if (!rstn_i) begin
            state <= IDLE;
            pending_index <= '0;
            pending_tag <= '0;
            pending_offset <= '0;
            pending_data_wr <= '0;
            pending_we <= 1'b0;

            for (int i = 0; i < NUM_SETS; i++) begin
                for (int j = 0; j < ASSOCIATIVITY; j++) begin
                    cache_mem[i][j].valid <= 1'b0;
                    cache_mem[i][j].dirty <= 1'b0;
                    cache_mem[i][j].tag <= '0;
                    for (int k = 0; k < WORDS_PER_LINE; k++) begin
                        cache_mem[i][j].data[k] <= '0;
                    end
                    lru_counter[i] <= j[LRU_COUNTER_BITS-1:0];
                end
            end
        end else begin
            state <= next_state;

            if (mem_rsp_valid_i && (state == READ_MISS || state == WRITE_MISS)) begin
                cache_mem[pending_index][victim_way].valid <= 1'b1;
                cache_mem[pending_index][victim_way].dirty <= pending_we;
                cache_mem[pending_index][victim_way].tag <= pending_tag;

                for (int k = 0; k < WORDS_PER_LINE; k++) begin
                    cache_mem[pending_index][victim_way].data[k] <= received_line[k];
                end

                if (pending_we) begin
                    cache_mem[pending_index][victim_way].data[pending_offset] <= pending_data_wr;
                end

                for (int i = 0; i < ASSOCIATIVITY; i++) begin
                    if (i[$clog2(ASSOCIATIVITY)-1:0] == victim_way) begin
                        lru_counter[pending_index] <= '0;
                    end else if (lru_counter[pending_index] <
                               (LRU_COUNTER_BITS)'(ASSOCIATIVITY-1)) begin
                        lru_counter[pending_index] <=
                            lru_counter[pending_index] + 1'b1;
                    end
                end
            end

            if (valid_i && hit && we_i && state == IDLE) begin
                cache_mem[index][hit_way_sel].data[word_offset] <= data_wr_i;
                cache_mem[index][hit_way_sel].dirty <= 1'b1;

                for (int i = 0; i < ASSOCIATIVITY; i++) begin
                    if (i[$clog2(ASSOCIATIVITY)-1:0] == hit_way_sel) begin
                        lru_counter[index] <= '0;
                    end else if (lru_counter[index] <
                               (LRU_COUNTER_BITS)'(ASSOCIATIVITY-1)) begin
                        lru_counter[index] <= lru_counter[index] + 1'b1;
                    end
                end
            end

            if (valid_i && hit && !we_i && state == IDLE) begin
                for (int i = 0; i < ASSOCIATIVITY; i++) begin
                    if (i[$clog2(ASSOCIATIVITY)-1:0] == hit_way_sel) begin
                        lru_counter[index] <= '0;
                    end else if (lru_counter[index] <
                               (LRU_COUNTER_BITS)'(ASSOCIATIVITY-1)) begin
                        lru_counter[index] <= lru_counter[index] + 1'b1;
                    end
                end
            end

            if (valid_i && !hit && state == IDLE) begin
                pending_index <= index;
                pending_tag <= tag_in;
                pending_offset <= word_offset;
                pending_data_wr <= data_wr_i;
                pending_we <= we_i;
            end

            if (mem_rsp_valid_i && state == WRITE_BACK) begin
                cache_mem[pending_index][victim_way].dirty <= 1'b0;
            end
        end
    end

    always_comb begin
        next_state = state;

        case (state)
            IDLE: begin
                if (valid_i && !hit) begin
                    if (cache_mem[index][victim_way].valid &&
                        cache_mem[index][victim_way].dirty) begin
                        next_state = WRITE_BACK;
                    end else if (we_i) begin
                        next_state = WRITE_MISS;
                    end else begin
                        next_state = READ_MISS;
                    end
                end
            end

            WRITE_BACK: begin
                if (mem_rsp_valid_i) begin
                    if (pending_we) begin
                        next_state = WRITE_MISS;
                    end else begin
                        next_state = READ_MISS;
                    end
                end
            end

            READ_MISS, WRITE_MISS: begin
                if (mem_rsp_valid_i) begin
                    next_state = IDLE;
                end
            end
        endcase
    end

endmodule
