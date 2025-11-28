package riscv_pkg;
    import tartaruga_pkg::*;

    typedef enum logic [6:0] {
        OP_LW      = 7'b0000011,
        OP_ALU_I   = 7'b0010011,
        OP_AUIPC   = 7'b0010111,
        OP_SW      = 7'b0100011,
        OP_ALU     = 7'b0110011,
        OP_LUI     = 7'b0110111,
        OP_BRANCH  = 7'b1100011,
        OP_JAL     = 7'b1101111
    } opcode_t;

    typedef enum logic [2:0] {
        F3_ADD_SUB = 3'b000,
        F3_SLL     = 3'b001,
        F3_SLT     = 3'b010,
        F3_SLTU    = 3'b011,
        F3_XOR     = 3'b100,
        F3_SRL_SRA = 3'b101,
        F3_OR      = 3'b110,
        F3_AND     = 3'b111
    } f3_alu_t;

    typedef enum logic [2:0] {
        F3_BEQ  = 3'b000,
        F3_BNE  = 3'b001,
        F3_BLT  = 3'b100,
        F3_BGE  = 3'b101,
        F3_BLTU = 3'b110,
        F3_BGEU = 3'b111
    } f3_branch_t;

    typedef enum logic [6:0] {
        F7_ALU_NORMAL   = 7'b0000000,
        F7_ALU_MODIFIED = 7'b0100000
    } f7_alu_modifier_t;

    //typedef enum logic [2:0] {
    //    F3_ADDI = 3'b000
    //} f3_alu_i_t;
    //
    // We can reuse the one for the ALU without immediate

    bus32_t NOP_INSTR_HEX = 32'h00000033;
endpackage
