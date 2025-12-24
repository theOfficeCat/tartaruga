import "DPI-C" function int read_mem(input int pc);


module imem_wrapper 
    import tartaruga_pkg::*;
(
    input logic clk_i,
    input logic rstn_i,
    input bus32_t pc_i,
    output bus32_t instr_o
);
    bus32_t [IMEM_POS-1:0] imem;

    initial begin
        for (int i = 0; i < IMEM_POS; ++i) begin
            imem[i] = read_mem(i);
        end
    end

    assign instr_o = imem[(pc_i >> 2) & 32'hFFF];
endmodule
