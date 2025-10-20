// i_mem.cpp
#include <svdpi.h>
#include <fstream>
#include <iostream>
#include <string>
#include <cstdint>

static uint32_t i_mem[4096];

extern "C" int read_mem(int pc) {
    return static_cast<int>(i_mem[pc & 0xFFF]);
}

// DPI-friendly signature: use const char* instead of std::string
extern "C" bool load_data(const char* path) {
    if (!path) {
        std::cerr << "[DPI] load_data: null path provided\n";
        return false;
    }

    std::ifstream file(path);
    if (!file.is_open()) {
        std::cerr << "[DPI] Error: could not open file " << path << "\n";
        return false;
    }

    std::string line;
    int counter = 0;

    while (std::getline(file, line)) {
        // Remove carriage return if the file has Windows-style line endings (\r\n)
        if (!line.empty() && line.back() == '\r')
            line.pop_back();

        if (line.empty())
            continue; // skip empty lines

        // Ensure the line has at least 8 hex characters
        if (line.size() < 8) {
            std::cerr << "[DPI] Skipping short line: \"" << line << "\"\n";
            continue;
        }

        // Use only the first 8 characters (32 bits)
        std::string token = line.substr(0, 8);

        try {
            unsigned long val = std::stoul(token, nullptr, 16);
            if (val > 0xFFFFFFFFUL) {
                std::cerr << "[DPI] Warning: value out of 32-bit range: " << token << "\n";
                val = 0;
            }

            if (counter >= 4096) {
                std::cerr << "[DPI] Memory full, stopping after " << counter << " words\n";
                break;
            }

            i_mem[counter++] = static_cast<uint32_t>(val);
        } catch (const std::exception &e) {
            std::cerr << "[DPI] Error parsing hex line: \"" << token << "\" -> " << e.what() << "\n";
            continue;
        }
    }

    // Fill remaining memory with zeros
    for (; counter < 4096; ++counter)
        i_mem[counter] = 0;

    std::cerr << "[DPI] Loaded " << counter << " words into i_mem\n";
    return true;
}

