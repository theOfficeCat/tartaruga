// d_mem.cpp
#include <svdpi.h>
#include <fstream>
#include <iostream>
#include <string>
#include <cstdint>
#include <cstring>

static uint32_t d_mem[4096];
static bool d_mem_initialized = false;

extern "C" int read_dmem(int addr) {
    if (!d_mem_initialized) {
        std::memset(d_mem, 0, sizeof(d_mem));
        d_mem_initialized = true;
    }
    
    int index = (addr >> 2);
    
    if (index >= 0 && index < (4096)) {
        return static_cast<int>(d_mem[index]);
    } else {
        std::cerr << "[DPI] Error: read_dmem address out of bounds: 0x" 
                  << std::hex << addr << std::dec << std::endl;
        return 0;
    }
}

extern "C" void write_dmem(int addr, int data) {
    if (!d_mem_initialized) {
        std::memset(d_mem, 0, sizeof(d_mem));
        d_mem_initialized = true;
    }
    
    int index = (addr >> 2);
    
    if (index >= 0 && index < (4096)) {
        d_mem[index] = static_cast<uint32_t>(data);
    } else {
        std::cerr << "[DPI] Error: write_dmem address out of bounds: 0x" 
                  << std::hex << addr << std::dec << std::endl;
    }
}
