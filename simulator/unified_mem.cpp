#include <svdpi.h>
#include <fstream>
#include <iostream>
#include <iomanip>
#include <string>
#include <cstdint>
#include <cstring>


static uint32_t mem[1024*256]; // 1MiB memory
static bool mem_initialized = false;

extern "C" int read_mem(int addr) {
    if (!mem_initialized) {
        std::memset(mem, 0, sizeof(mem));
        mem_initialized = true;
    }

    int index = (addr >> 2);

    if (index >= 0 && index < (1024*256)) {
        return static_cast<int>(mem[index]);
    } else {
        std::cerr << "[DPI] Error: read_mem address out of bounds: 0x"
                  << std::hex << addr << std::dec << std::endl;
        return 0;
    }
}

extern "C" void write_mem(int addr, int data) {
    if (!mem_initialized) {
        std::memset(mem, 0, sizeof(mem));
        mem_initialized = true;
    }

    int index = (addr >> 2);

    if (index >= 0 && index < (1024*256)) {
        mem[index] = static_cast<uint32_t>(data);
    } else {
        std::cerr << "[DPI] Error: write_mem address out of bounds: 0x"
                  << std::hex << addr << std::dec << std::endl;
    }
}

extern "C" void init_page_tables() {
    if (!mem_initialized) {
        std::memset(mem, 0, sizeof(mem));
        mem_initialized = true;
    }

    // Reservar espacio para tablas de páginas en las primeras 8KB de memoria física
    // L1 Table en 0x1000 (4KB), L2 Tables en 0x2000 (8KB)
    
    // Inicializar L1 Table (nivel 1) - una entrada apuntando a L2 Table
    // Cada entrada de 32 bits: bit 0 = válido, bits [19:0] = dirección física/PPN
    write_mem(0x1000, 0x2001);  // Entrada 0: apunta a L2 Table en 0x2000, válido=1
    
    // Inicializar L2 Table (nivel 2) - mapeo identidad para las primeras 256 páginas (1MB)
    // Cada entrada: (dirección_física << 12) | 1 (válido)
    for (int i = 0; i < 256; i++) {
        uint32_t phys_addr = i * 0x1000;  // 4KB por página
        write_mem(0x2000 + i*4, (phys_addr << 12) | 0x1);
    }
    
    std::cout << "[DPI] Page tables initialized (L1 at 0x1000, L2 at 0x2000)" << std::endl;
    std::cout << "[DPI] Identity mapping for first 1MB of physical memory" << std::endl;
}

extern void write_mem_dump(const char* path) {
    std::ofstream file(path);

    if (!file.is_open()) {
        std::cerr << "[DPI] Error: could not open file for writing memory dump: " << path << "\n";
        return;
    }

    // Dump entire memory in blocks of 4 words (16 bytes) showing address
    for (size_t i = 0; i < (1024*256); i += 4) {
        file << std::setfill('0') << std::setw(8) << std::hex << (i * 4) << ": "
             << std::setw(8) << std::hex << mem[i] << " "
             << std::setw(8) << std::hex << mem[i + 1] << " "
             << std::setw(8) << std::hex << mem[i + 2] << " "
             << std::setw(8) << std::hex << mem[i + 3] << "\n";
    }
    file.close();
    std::cout << "[DPI] Memory dump written to " << path << "\n";
}
