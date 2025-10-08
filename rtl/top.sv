module top
    import tartaruga_pkg::*;
(
    input logic clk_i,
    input logic rstn_i
);

    datapath datapath_inst (
        .clk_i(clk_i),
        .rstn_i(rstn_i)
    );

endmodule
