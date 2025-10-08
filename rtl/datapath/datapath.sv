module datapath
    import tartaruga_pkg::*;
(
    input logic clk_i,
    input logic rstn_i
);
    bus32_t instruction;

    // Fetch
    fetch fetch_inst (
        .clk_i(clk_i),
        .rstn_i(rstn_i),
        .instr_o(instruction)
    );

endmodule
