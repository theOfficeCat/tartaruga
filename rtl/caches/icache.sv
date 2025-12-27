module icache
    import tartaruga_pkg::*;
    import riscv_pkg::*;
(
    input  logic clk_i,
    input  logic rstn_i,
    input  bus32_t pc_i,

    output bus32_t mem_pc_o,
    output logic req_valid_o,
    input  logic req_ready_i,
    input  instruction_t mem_instr_i,
    input logic rsp_valid_i,
    output logic rsp_ready_o,
    input bus32_t rsp_mem_addr_i,

    output instruction_t instr_o,
    output logic valid_o
);

    localparam int NUM_SETS = 16;
    localparam int ASSOCIATIVITY = 2;
    localparam int INDEX_BITS = $clog2(NUM_SETS);
    localparam int WORDS_PER_LINE = 1;
    localparam int OFFSET_BITS = 2 + $clog2(WORDS_PER_LINE);
    localparam int TAG_BITS = 32 - INDEX_BITS - OFFSET_BITS;

    typedef struct {
        logic valid;
        logic [TAG_BITS-1:0] tag;
        instruction_t data;
    } cache_line_t;

    cache_line_t cache_mem[NUM_SETS][ASSOCIATIVITY];
    logic [$clog2(ASSOCIATIVITY)-1:0] lru_counter[NUM_SETS][ASSOCIATIVITY];

    logic [INDEX_BITS-1:0] index;
    logic [TAG_BITS-1:0] tag_in;
    assign index = pc_i[OFFSET_BITS + INDEX_BITS - 1 : OFFSET_BITS];
    assign tag_in = pc_i[31 : OFFSET_BITS + INDEX_BITS];
    assign mem_pc_o = pc_i;

    logic hit;
    logic [ASSOCIATIVITY-1:0] hit_way;
    genvar w;
    generate
        for (w = 0; w < ASSOCIATIVITY; w++) begin : hit_gen
            assign hit_way[w] = cache_mem[index][w].valid && (cache_mem[index][w].tag == tag_in);
        end
    endgenerate

    assign hit = |hit_way;

    logic [$clog2(ASSOCIATIVITY)-1:0] hit_way_sel;
    always_comb begin
        hit_way_sel = '0;
        for (int i = 0; i < ASSOCIATIVITY; i++) begin
            if (hit_way[i])
                hit_way_sel = i[$clog2(ASSOCIATIVITY)-1:0];
        end
    end

    assign instr_o = hit ? cache_mem[index][hit_way_sel].data : NOP_INSTR_HEX;
    assign valid_o = hit;

    logic pending_req; // track if a request is pending
    assign req_valid_o = (~hit && ~pending_req);
    assign rsp_ready_o = 1'b1; // always ready to accept response

    always_ff @(posedge clk_i or negedge rstn_i) begin
        if (!rstn_i) begin
            pending_req <= 1'b0;

            for (int i = 0; i < NUM_SETS; i++) begin
                for (int j = 0; j < ASSOCIATIVITY; j++) begin
                    cache_mem[i][j].valid <= 1'b0;
                    cache_mem[i][j].tag <= '0;
                    cache_mem[i][j].data <= '0;
                    lru_counter[i][j] <= j[$clog2(ASSOCIATIVITY)-1:0];
                end
            end
        end
        else begin
            if (req_valid_o && req_ready_i) begin
                pending_req <= 1'b1;
            end
            else if (rsp_valid_i) begin
                pending_req <= 1'b0;
            end

            if (hit) begin
                logic [$clog2(ASSOCIATIVITY)-1:0] old_lru;
                old_lru = lru_counter[index][hit_way_sel];

                for (int i = 0; i < ASSOCIATIVITY; i++) begin
                    if (i[$clog2(ASSOCIATIVITY)-1:0] == hit_way_sel) begin
                        lru_counter[index][i] <= '0;
                    end
                    else if (lru_counter[index][i] < old_lru) begin
                        lru_counter[index][i] <= lru_counter[index][i] + 1'b1;
                    end
                end
            end
            else begin
                if (rsp_valid_i && rsp_mem_addr_i == pc_i) begin
                    logic [$clog2(ASSOCIATIVITY)-1:0] lru_way;
                    lru_way = '0;

                    for (int i = 0; i < ASSOCIATIVITY; i++) begin
                        if (lru_counter[index][i] == ($clog2(ASSOCIATIVITY))'(ASSOCIATIVITY-1)) begin
                            lru_way = i[$clog2(ASSOCIATIVITY)-1:0];
                        end
                    end

                    cache_mem[index][lru_way].valid <= 1'b1;
                    cache_mem[index][lru_way].tag <= tag_in;
                    cache_mem[index][lru_way].data <= mem_instr_i;

                    for (int i = 0; i < ASSOCIATIVITY; i++) begin
                        if (i[$clog2(ASSOCIATIVITY)-1:0] == lru_way) begin
                            lru_counter[index][i] <= '0;
                        end
                        else if (lru_counter[index][i] < ($clog2(ASSOCIATIVITY))'(ASSOCIATIVITY-1)) begin
                            lru_counter[index][i] <= lru_counter[index][i] + 1'b1;
                        end
                    end
                end
            end
        end
    end

endmodule
