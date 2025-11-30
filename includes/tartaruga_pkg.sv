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

    typedef enum logic [1:0] {
        ALU,
        MEM,
        MUL,
        PC_4
    } wb_origin_t;

    typedef enum logic [2:0] {
        JUMP,
        BNE,
        BEQ,
        BLT,
        BLTU,
        BGE,
        BGEU,
        BNONE
    } jump_kind_t;

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

    typedef struct packed {
        logic [31:31] imm12;
        logic [30:25] imm5;
        logic [24:20] rs2;
        logic [19:15] rs1;
        logic [14:12] func3;
        logic [11:8]  imm1;
        logic [7:7]   imm11;
        logic [6:0]   opcode;
    } btype_t;

    typedef struct packed {
        logic [31:31] imm20;
        logic [30:21] imm1;
        logic [20:20] imm11;
        logic [19:12] imm12;
        logic [11:7]  rd;
        logic [6:0]   opcode;
    } jtype_t;

    typedef union packed {
        logic [31:0] instruction;
        rtype_t rtype;
        utype_t utype;
        itype_t itype;
        stype_t stype;
        btype_t btype;
        jtype_t jtype;
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

        wb_origin_t wb_origin;
        logic store_to_mem;

        jump_kind_t jump_kind;

        logic [2:0] exe_stages;
        logic is_mul;
    } instr_data_t;

    typedef struct packed {
        instr_data_t instr;
        logic valid;
        bus32_t data_rs1;
        bus32_t data_rs2;
        bus32_t immediate;
    } decode_to_exe_t;

    typedef struct packed {
        instr_data_t instr;
        logic valid;
        bus32_t data_rs2;
        bus32_t result;

        logic branch_taken;
    } exe_to_mem_t;

    typedef struct packed {
        instr_data_t instr;
        logic valid;
        bus32_t result;

        logic branch_taken;
        bus32_t branched_pc;
    } mem_to_wb_t;

    parameter EXE_STAGES_DEFAULT = 1;
    parameter EXE_STAGES_MULT = 4;
    parameter MAX_EXE_STAGES = (EXE_STAGES_DEFAULT > EXE_STAGES_MULT) ? EXE_STAGES_DEFAULT : EXE_STAGES_MULT;

    localparam decode_to_exe_t NOP_INSTR = '{
        instr: '{
            pc:            '0,
            instr:         32'h00000033,
            addr_rs1:      '0,
            addr_rs2:      '0,
            addr_rd:       '0,
            write_enable:  1'b0,
            rs1_or_pc:     RS1,
            rs2_or_imm:    RS2,
            alu_op:        ADD,
            wb_origin:     ALU,
            store_to_mem:  1'b0,
            jump_kind:     BNONE,
            exe_stages:    3'b1,
            is_mul:        1'b0
        },
        valid:     1'b0,
        data_rs1:  '0,
        data_rs2:  '0,
        immediate: '0
    };


    function automatic logic reg_hazard(
        input logic [4:0] rs,
        input logic [4:0] rd,
        input logic write_en
    );
        return (write_en && (rd != 5'd0) && (rd == rs));
    endfunction

endpackage
