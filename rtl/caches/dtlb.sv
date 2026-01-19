module dtlb 
    import tartaruga_pkg::*;
(
    input logic clk_i,
    input logic rstn_i,
    input logic valid_i,
    input logic [31:0] virt_addr_i,
    input logic rm4_bit0_i,
    input logic update_i,
    input logic [19:0] update_vpn_i,
    input logic [19:0] update_ppn_i,
    output logic ready_o,
    output logic [19:0] phys_addr_o,
    output logic tlb_hit_o,
    output logic tlb_miss_o
);

    typedef struct packed {
        logic valid;
        logic [19:0] vpn;
        logic [19:0] ppn;
    } tlb_entry_t;

    parameter TLB_SIZE = 16;
    localparam TLB_IDX_BITS = $clog2(TLB_SIZE);

    tlb_entry_t [TLB_SIZE-1:0] tlb_entries;
    logic [TLB_IDX_BITS-1:0] lru_counter;

    always_ff @(posedge clk_i or negedge rstn_i) begin
        if (!rstn_i) begin
            for (int i = 0; i < TLB_SIZE; i++) begin
                tlb_entries[i].valid <= 1'b0;
            end
            lru_counter <= '0;
        end else if (update_i) begin
            tlb_entries[lru_counter].valid <= 1'b1;
            tlb_entries[lru_counter].vpn <= update_vpn_i;
            tlb_entries[lru_counter].ppn <= update_ppn_i;
            lru_counter <= lru_counter + 1;
        end
    end

    logic hit;
    logic [19:0] hit_ppn;
    always_comb begin
        hit = 1'b0;
        hit_ppn = '0;
        for (int i = 0; i < TLB_SIZE; i++) begin
            if (tlb_entries[i].valid && tlb_entries[i].vpn == virt_addr_i[31:12]) begin
                hit = 1'b1;
                hit_ppn = tlb_entries[i].ppn;
            end
        end
    end

    assign ready_o = 1'b1;
    assign tlb_hit_o = hit && valid_i && !rm4_bit0_i;
    assign tlb_miss_o = !hit && valid_i && !rm4_bit0_i;
    assign phys_addr_o = rm4_bit0_i ? virt_addr_i[19:0] : 
                        (hit ? {hit_ppn, virt_addr_i[11:0]} : virt_addr_i[19:0]);

endmodule
