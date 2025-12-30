module top
    import tartaruga_pkg::*;
(
    input logic clk_i,
    input logic rstn_i,
    output logic commit_valid_o
);

    datapath datapath_inst (
        .clk_i(clk_i),
        .rstn_i(rstn_i),
        .commit_valid_o(commit_valid_o)
    );

endmodule
