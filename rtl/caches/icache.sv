module icache
    import tartaruga_pkg::*;
    import riscv_pkg::*;
(
    input  logic clk_i,
    input  logic rstn_i,
    input  bus32_t pc_i,

    output bus32_t mem_pc_o,
    output logic req_valid_o,
    input logic req_ready_i,
    input logic [127:0] mem_instr_line_i,
    input logic rsp_valid_i,
    output logic rsp_ready_o,
    input bus32_t rsp_mem_addr_i,

    output instruction_t instr_o,
    output logic valid_o
);

    localparam int NUM_SETS = 16;
    localparam int ASSOCIATIVITY = 2;
    localparam int INDEX_BITS = $clog2(NUM_SETS);
    localparam int WORDS_PER_LINE = 4;
    localparam int OFFSET_BITS = 2 + $clog2(WORDS_PER_LINE);
    localparam int TAG_BITS = 32 - INDEX_BITS - OFFSET_BITS;
    localparam int LRU_COUNTER_BITS = $clog2(ASSOCIATIVITY);
    localparam int WORD_SEL_BITS = $clog2(WORDS_PER_LINE);

    typedef struct {
        logic valid;
        logic [TAG_BITS-1:0] tag;
        instruction_t data[WORDS_PER_LINE];
    } cache_line_t;

    cache_line_t cache_mem[NUM_SETS][ASSOCIATIVITY];
    logic [LRU_COUNTER_BITS-1:0] lru_counter[NUM_SETS];

    logic [INDEX_BITS-1:0] index;
    logic [TAG_BITS-1:0] tag_in;
    logic [WORD_SEL_BITS-1:0] word_offset;
    
    assign index = pc_i[OFFSET_BITS + INDEX_BITS - 1 : OFFSET_BITS];
    assign tag_in = pc_i[31 : OFFSET_BITS + INDEX_BITS];
    assign word_offset = pc_i[WORD_SEL_BITS+1:2];

    bus32_t line_aligned_addr;
    assign line_aligned_addr = {pc_i[31:OFFSET_BITS], {OFFSET_BITS{1'b0}}};
    assign mem_pc_o = line_aligned_addr;

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

    assign instr_o = hit ? cache_mem[index][hit_way_sel].data[word_offset] : NOP_INSTR_HEX;
    assign valid_o = hit;

    logic pending_req; // track if a request is pending
    logic [INDEX_BITS-1:0] pending_index;
    logic [TAG_BITS-1:0] pending_tag;

    assign req_valid_o = (~hit && ~pending_req);
    assign rsp_ready_o = 1'b1; // always ready to accept response

    instruction_t received_line[WORDS_PER_LINE];

    always_comb begin
        for (int i = 0; i < WORDS_PER_LINE; i++) begin
            received_line[i] = mem_instr_line_i[(i*32)+:32];
        end
    end

    always_ff @(posedge clk_i or negedge rstn_i) begin
        if (!rstn_i) begin
            pending_req <= 1'b0;
            pending_index <= '0;
            pending_tag <= '0;
            
            for (int i = 0; i < NUM_SETS; i++) begin
                for (int j = 0; j < ASSOCIATIVITY; j++) begin
                    cache_mem[i][j].valid <= 1'b0;
                    cache_mem[i][j].tag <= '0;
                    for (int k = 0; k < WORDS_PER_LINE; k++) begin
                        cache_mem[i][j].data[k] <= '0;
                    end
                    lru_counter[i] <= j[LRU_COUNTER_BITS-1:0];
                end
            end
        end else begin
            if (req_valid_o && req_ready_i) begin
                pending_req <= 1'b1;
                pending_index <= index;
                pending_tag <= tag_in;
            end else if (rsp_valid_i) begin
                pending_req <= 1'b0;
            end

            if (hit) begin
                logic [LRU_COUNTER_BITS-1:0] old_lru;
                old_lru = lru_counter[index];
                
                for (int i = 0; i < ASSOCIATIVITY; i++) begin
                    if (i[LRU_COUNTER_BITS-1:0] == hit_way_sel) begin
                        lru_counter[index] <= '0;
                    end else if (lru_counter[index] < old_lru) begin
                        lru_counter[index] <= lru_counter[index] + 1'b1;
                    end
                end
            end
            
            if (rsp_valid_i) begin
                logic [LRU_COUNTER_BITS-1:0] lru_way;
                logic [INDEX_BITS-1:0] rsp_index;
                logic [TAG_BITS-1:0] rsp_tag;
                
                rsp_index = rsp_mem_addr_i[OFFSET_BITS + INDEX_BITS - 1 : OFFSET_BITS];
                rsp_tag = rsp_mem_addr_i[31 : OFFSET_BITS + INDEX_BITS];
                
                lru_way = '0;
                for (int i = 0; i < ASSOCIATIVITY; i++) begin
                    if (lru_counter[rsp_index] == (LRU_COUNTER_BITS)'(ASSOCIATIVITY-1)) begin
                        lru_way = i[LRU_COUNTER_BITS-1:0];
                    end
                end
                
                cache_mem[rsp_index][lru_way].valid <= 1'b1;
                cache_mem[rsp_index][lru_way].tag <= rsp_tag;
                
                for (int k = 0; k < WORDS_PER_LINE; k++) begin
                    cache_mem[rsp_index][lru_way].data[k] <= received_line[k];
                end
                
                for (int i = 0; i < ASSOCIATIVITY; i++) begin
                    if (i[LRU_COUNTER_BITS-1:0] == lru_way) begin
                        lru_counter[rsp_index] <= '0;
                    end else if (lru_counter[rsp_index] < 
                               (LRU_COUNTER_BITS)'(ASSOCIATIVITY-1)) begin
                        lru_counter[rsp_index] <= 
                            lru_counter[rsp_index] + 1'b1;
                    end
                end
            end
        end
    end

endmodule
