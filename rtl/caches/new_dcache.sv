
module new_dcache
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
    localparam int WORDS_PER_LINE = 4;
    localparam int INDEX_BITS = $clog2(NUM_SETS);
    localparam int OFFSET_BITS = 2 + $clog2(WORDS_PER_LINE);
    localparam int TAG_BITS = 32 - INDEX_BITS - OFFSET_BITS;
    localparam int WORD_SEL_BITS = $clog2(WORDS_PER_LINE);

    typedef struct {
        logic valid;
        logic [TAG_BITS-1:0] tag;
        logic[127:0] data;
    } cache_line_t;


    cache_line_t cache_mem[NUM_SETS];

    logic [INDEX_BITS-1:0] index;
    logic [TAG_BITS-1:0] tag_in;
    logic [WORD_SEL_BITS-1:0] word_offset;

    assign index = addr_i[OFFSET_BITS + INDEX_BITS - 1 : OFFSET_BITS];
    assign tag_in = addr_i[31 : OFFSET_BITS + INDEX_BITS];
    assign word_offset = addr_i[WORD_SEL_BITS+1:2];

    bus32_t line_aligned_addr;
    assign line_aligned_addr = {addr_i[31:OFFSET_BITS], {OFFSET_BITS{1'b0}}};

    logic hit;

    always_comb begin
        hit = 1'b0;

        if (cache_mem[index].valid && (cache_mem[index].tag == tag_in)) begin
            hit = 1'b1;
        end
    end


    typedef enum logic [1:0] {
        IDLE,
        READ_MISS,
        WRITE_MISS,
        LOAD_LINE
    } state_t;

    state_t state, next_state;

    always_comb begin
        next_state = state;

        case (state)
            IDLE: begin
                if (valid_i && !hit && we_i) begin
                    next_state = WRITE_MISS;
                end else if (valid_i && !hit && !we_i) begin
                    next_state = READ_MISS;
                end else begin
                    next_state = IDLE;
                end
            end
            READ_MISS: begin
                if (mem_rsp_valid_i) begin
                    next_state = LOAD_LINE;
                end
            end
            WRITE_MISS: begin
                if (mem_rsp_valid_i) begin
                    next_state = LOAD_LINE;
                end
            end
            LOAD_LINE: begin
                next_state = IDLE;
            end
            default: begin
                next_state = IDLE;
            end
        endcase
    end

    logic [127:0] line;
    logic [TAG_BITS-1:0] tag;
    logic valid;

    always_comb begin
        data_rd_o = '0;
        ready_o = 1'b0;
        mem_data_wr_o = '0;
        mem_we_o = '0;
        mem_req_valid_o = '0;
        mem_addr_o = '0;

        line = cache_mem[index].data;
        tag = cache_mem[index].tag;
        valid = cache_mem[index].valid;
        case (state)
            IDLE: begin
                // READ & HIT
                if (valid_i && hit && !we_i) begin
                    data_rd_o = cache_mem[index].data[32*word_offset +: 32];
                    ready_o = 1'b1;
                // WRITE & HIT
                end else if (valid_i && hit && we_i) begin
                    line[32*word_offset +: 32] = data_wr_i;

                    mem_req_valid_o = 1'b1;
                    mem_we_o = 1'b1;
                    mem_data_wr_o = cache_mem[index].data;
                    mem_data_wr_o[32*word_offset +: 32] = data_wr_i;
                    mem_addr_o = addr_i;

                    if (mem_req_ready_i) begin
                        ready_o = 1'b1;
                    end
                end
            end
            READ_MISS, WRITE_MISS: begin
                if(mem_req_ready_i) begin
                    mem_req_valid_o = 1'b1;
                    mem_addr_o = addr_i;
                    mem_we_o = 1'b0;
                end else begin
                    mem_req_valid_o = 1'b0;
                    mem_addr_o = '0;
                    mem_we_o = 1'b0;
                end
            end
            LOAD_LINE: begin
                line = mem_data_line_i;
                tag = tag_in;
                valid = 1'b1;
            end
            default: begin
                data_rd_o = '0;
                ready_o = 1'b0;
                mem_data_wr_o = '0;
                mem_we_o = '0;
                mem_req_valid_o = '0;
                mem_addr_o = '0;

                line = cache_mem[index].data;
            end
        endcase
    end

    always_ff @(posedge clk_i or negedge rstn_i) begin
        if (!rstn_i) begin
            state <= IDLE;

            for (int i = 0; i < NUM_SETS; ++i) begin
                    cache_mem[i].valid <= 1'b0;
                    cache_mem[i].tag <= '0;
                    cache_mem[i].data <= '0;
            end

        end else begin
            state <= next_state;
            cache_mem[index].data <= line;
            cache_mem[index].tag <= tag;
            cache_mem[index].valid <= valid;
        end

    end

    assign mem_rsp_ready_o = 1'b1;

endmodule
