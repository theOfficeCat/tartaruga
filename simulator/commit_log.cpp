#include <svdpi.h>
#include <iostream>
#include <iomanip>

extern "C" void print_commit(int pc, int instr, int result) {
    std::cout << std::hex << std::setfill('0')
              << "PC: 0x" << std::setw(8) << pc
              << " : 0x" << std::setw(8) << instr << std::endl
              << "\tresult: 0x" << std::setw(8) << result << std::endl;
}

