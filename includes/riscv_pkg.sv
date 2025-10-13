package riscv_pkg;
    typedef enum logic [6:0] {
        OP_ALU_I   = 7'b0010011,
        OP_AUIPC   = 7'b0010111,
        OP_ALU     = 7'b0110011,
        OP_LUI     = 7'b0110111
    } opcode_t;

    typedef enum logic [2:0] {
        F3_ADD = 3'b000
    } f3_alu_t;

    typedef enum logic [2:0] {
        F3_ADDI = 3'b000
    } f3_alu_i_t;
endpackage
