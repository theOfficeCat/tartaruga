package tartaruga_pkg;
    ///////////////////////////////////////////////////////////////////////////////
    // PARAMETERS
    ///////////////////////////////////////////////////////////////////////////////

    parameter IMEM_POS = 4096;
    parameter REG_COUNT = 32;


    ///////////////////////////////////////////////////////////////////////////////
    // TYPES
    ///////////////////////////////////////////////////////////////////////////////

    typedef logic [31:0] bus32_t;

    typedef logic [4:0] reg_addr_t;


    ///////////////////////////////////////////////////////////////////////////////
    // STRUCTURES
    ///////////////////////////////////////////////////////////////////////////////

    typedef enum logic [3:0] {
        ADD,
        SUB,
        SLT,
        SLTU,
        SLL,
        SRL,
        SRA,
        XOR,
        OR,
        AND
    } alu_op_t;

    typedef enum logic {
        RS2,
        IMM
    } rs2_or_imm_t;

    typedef enum logic {
        RS1,
        PC
    } rs1_or_pc_t;

    typedef enum logic {
        ALU,
        MEM
    } alu_or_mem_t;

    typedef struct packed {
        logic [31:25] func7;
        logic [24:20] rs2;
        logic [19:15] rs1;
        logic [14:12] func3;
        logic [11:7]  rd;
        logic [6:0]   opcode;
    } rtype_t;

    typedef struct packed {
        logic [31:12] imm;
        logic [11:7]  rd;
        logic [6:0]   opcode;
    } utype_t;

    typedef struct packed {
        logic [31:20] imm;
        logic [19:15] rs1;
        logic [14:12] func3;
        logic [11:7]  rd;
        logic [6:0]   opcode;
    } itype_t;

    typedef struct packed {
        logic [31:25] imm5;
        logic [24:20] rs2;
        logic [19:15] rs1;
        logic [14:12] func3;
        logic [11:7]  imm0;
        logic [6:0]  opcode;
    } stype_t;


    typedef union packed {
        logic [31:0] instruction;
        rtype_t rtype;
        utype_t utype;
        itype_t itype;
        stype_t stype;
        // Add types of instructions as structs of 32 bits to ease the decode
    } instruction_t;

    typedef struct packed {
        bus32_t pc;
        instruction_t instr;
        
        reg_addr_t addr_rs1;
        reg_addr_t addr_rs2;
        reg_addr_t addr_rd;

        logic write_enable;
        rs1_or_pc_t rs1_or_pc;
        rs2_or_imm_t rs2_or_imm;
        alu_op_t alu_op;

        alu_or_mem_t alu_or_mem;
        logic store_to_mem;
    } instr_data_t;

    typedef struct packed {
        instr_data_t instr;
        bus32_t data_rs1;
        bus32_t data_rs2;
        bus32_t immediate;
    } decode_to_exe_t;

    typedef struct packed {
        instr_data_t instr;
        bus32_t data_rs2;
        bus32_t result;
    } exe_to_mem_t;

    typedef struct packed {
        instr_data_t instr;
        bus32_t result;
    } mem_to_wb_t;

endpackage
