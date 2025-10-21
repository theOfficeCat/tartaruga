#include <svdpi.h>
#include <iostream>
#include <iomanip>
#include <fstream>

std::ofstream commit_file;

extern "C" void init_commit(std::string path) {
    commit_file = std::ofstream(path);
}

extern "C" void print_commit(int pc, int instr, int result) {
    commit_file << std::hex << std::setfill('0')
              << "PC: 0x" << std::setw(8) << pc
              << " : 0x" << std::setw(8) << instr << std::endl
              << "\tresult: 0x" << std::setw(8) << result << std::endl;
}

extern "C" void close_commit() {
    commit_file.close();
}
