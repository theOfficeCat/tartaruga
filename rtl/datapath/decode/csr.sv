module csr
    import tartaruga_pkg::*;
    import riscv_pkg::*;
(
    input  logic         clk_i,
    input  logic         rstn_i,

    // From decode
    input  logic         csr_read_i,
    input  logic         csr_write_i,
    input  csr_addr_t    csr_addr_i,
    input  bus32_t       csr_write_data_i,

    // Exception
    input  logic         xcpt_i,
    input  xcpt_code_t   xcpt_code_i,
    input  bus32_t       xcpt_pc_i,
    input  bus32_t       xcpt_value_i,

    // To execute
    output logic         csr_read_valid_o,
    output bus32_t       csr_read_data_o
);

    bus32_t mepc;
    bus32_t mcause;

    // CSR read logic
    always_comb begin
        csr_read_valid_o = 1'b0;
        csr_read_data_o  = 32'b0;

        if (csr_read_i) begin
            csr_read_valid_o = 1'b1;
            case (csr_addr_i)
                CSR_MEPCT_ADDR:  csr_read_data_o = mepc;
                CSR_MCAUSE_ADDR: csr_read_data_o = mcause;
                default:         csr_read_data_o = 32'b0; // Unknown CSR
            endcase
        end
    end

    // CSR write logic
    always_ff @(posedge clk_i, negedge rstn_i) begin
        if (~rstn_i) begin
            mepc   <= 32'b0;
            mcause <= 32'b0;
        end else begin
            // Exception handling
            if (xcpt_i) begin
                mepc   <= xcpt_pc_i;
                mcause <= {27'b0, xcpt_code_i}; // Assuming xcpt_code_i is 5 bits
            end else if (csr_write_i) begin
                case (csr_addr_i)
                    CSR_MEPCT_ADDR:  mepc   <= csr_write_data_i;
                    CSR_MCAUSE_ADDR: mcause <= csr_write_data_i;
                    default: ; // Unknown CSR, do nothing
                endcase
            end
        end
    end

endmodule
