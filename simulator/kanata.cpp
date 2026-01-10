#include <iterator>
#include <svdpi.h>
#include <iostream>
#include <iomanip>
#include <fstream>
#include <map>
#include <string>

std::ofstream kanata_file;
std::ofstream kanata_dbg_file;

enum Kanata_Stages {
    FETCH,
    DECODE,
    EXECUTE,
    MEMORY,
    WRITEBACK,
    COMMIT,
    NONE
};

std::map<int, std::string> stage_to_str = {
    {FETCH, "Fetch"},
    {DECODE, "Decode"},
    {EXECUTE, "Execute"},
    {MEMORY, "Memory"},
    {WRITEBACK, "Writeback"},
    {COMMIT, "Commit"},
    {NONE, "None"}
};

std::map <int, Kanata_Stages> instruction_stage;

extern "C" void init_kanata(std::string path) {
    kanata_file = std::ofstream(path);

    kanata_file << "Kanata\t0004" << std::endl;
    kanata_file << "C=\t0" << std::endl;

    instruction_stage.clear();

    kanata_dbg_file = std::ofstream("kanata_dbg.log");
    kanata_dbg_file << "Kanata Debug Log" << std::endl;
}

extern "C" void print_kanata(
    bool valid_fetch,
    bool valid_decode,
    bool valid_execute,
    bool valid_memory,
    bool valid_writeback,
    bool valid_commit,

    int id_fetch,
    int id_decode,
    int id_execute,
    int id_memory,
    int id_writeback,
    int id_commit,

    int pc_decode,
    int instr_decode,

    bool flush
) {
    kanata_file << "C\t1" << std::endl;

    kanata_dbg_file << "----------------------------------------" << std::endl;

    kanata_dbg_file << "Cycle Update:" << std::endl;

    int prev_curr_fetch = instruction_stage.find(id_fetch) != instruction_stage.end() ? instruction_stage[id_fetch] : NONE;
    int prev_curr_decode = instruction_stage.find(id_decode) != instruction_stage.end() ? instruction_stage[id_decode] : NONE;
    int prev_curr_execute = instruction_stage.find(id_execute) != instruction_stage.end() ? instruction_stage[id_execute] : NONE;
    int prev_curr_memory = instruction_stage.find(id_memory) != instruction_stage.end() ? instruction_stage[id_memory] : NONE;
    int prev_curr_writeback = instruction_stage.find(id_writeback) != instruction_stage.end() ? instruction_stage[id_writeback] : NONE;
    int prev_curr_commit = instruction_stage.find(id_commit) != instruction_stage.end() ? instruction_stage[id_commit] : NONE;

    kanata_dbg_file << "  Fetch ID: " << id_fetch << " Prev Stage: " << stage_to_str[prev_curr_fetch] << " Valid: " << valid_fetch << std::endl;
    kanata_dbg_file << "  Decode ID: " << id_decode << " Prev Stage: " << stage_to_str[prev_curr_decode] << " Valid: " << valid_decode << std::endl;
    kanata_dbg_file << "  \t PC: " << std::hex << std::setfill('0')
                   << "0x" << std::setw(8) << pc_decode
                   << " Instr: "
                   << "0x" << std::setw(8) << instr_decode << std::dec << std::endl;
    kanata_dbg_file << "  Execute ID: " << id_execute << " Prev Stage: " << stage_to_str[prev_curr_execute] << " Valid: " << valid_execute << std::endl;
    kanata_dbg_file << "  Memory ID: " << id_memory << " Prev Stage: " << stage_to_str[prev_curr_memory] << " Valid: " << valid_memory << std::endl;
    kanata_dbg_file << "  Writeback ID: " << id_writeback << " Prev Stage: " << stage_to_str[prev_curr_writeback] << " Valid: " << valid_writeback << std::endl;
    kanata_dbg_file << "  Commit ID: " << id_commit << " Prev Stage: " << stage_to_str[prev_curr_commit] << " Valid: " << valid_commit << std::endl;

    kanata_dbg_file << std::endl;

    kanata_dbg_file << "  Flush: " << flush << std::endl;

    if (flush) {
        for (auto const& [id, stage] : instruction_stage) {
            if (stage != COMMIT && (stage != NONE) && !(stage == WRITEBACK && id == id_commit)) {
                kanata_file << "E\t" << id << "\t0\t";
                switch (stage) {
                    case FETCH:
                        kanata_file << "F" << std::endl;
                        break;
                    case DECODE:
                        kanata_file << "D" << std::endl;
                        break;
                    case EXECUTE:
                        kanata_file << "E" << std::endl;
                        break;
                    case MEMORY:
                        kanata_file << "M" << std::endl;
                        break;
                    case WRITEBACK:
                        kanata_file << "W" << std::endl;
                        break;
                    default:
                        break;
                }
                kanata_file << "R\t" << id << "\t0\t" << 1 << std::endl;
            }
            else if (stage == WRITEBACK && id == id_commit) {
                kanata_file << "E\t" << id << "\t0\tW" << std::endl;
                kanata_file << "R\t" << id << "\t0\t" << 0 << std::endl;
            }
            else if (stage == NONE) {
                kanata_file << "R\t" << id << "\t0\t" << 1 << std::endl;
            }
        }

        instruction_stage.clear();
    }
    else {
        // FETCH
        if (prev_curr_fetch != FETCH) {
            kanata_file << "I\t" << id_fetch << "\t" << id_fetch << "\t0" << std::endl;
            kanata_file << "S\t" << id_fetch << "\t0\t" << "F" << std::endl;
        }

        // DECODE
        if (prev_curr_decode != DECODE && valid_decode && prev_curr_decode != NONE) {
            kanata_file << "E\t" << id_decode << "\t0\t" << "F" << std::endl;
            kanata_file << "S\t" << id_decode << "\t0\t" << "D" << std::endl;

            kanata_file << "L\t" << id_decode << "\t0\t"
                        << std::hex << std::setfill('0')
                        << "0x" << std::setw(8) << pc_decode << " "
                        << "0x" << std::setw(8) << instr_decode << std::dec << std::endl;
        }

        // EXECUTE
        if (prev_curr_execute != EXECUTE && valid_execute && prev_curr_execute != NONE) {
            kanata_file << "E\t" << id_execute << "\t0\t" << "D" << std::endl;
            kanata_file << "S\t" << id_execute << "\t0\t" << "E" << std::endl;
        }

        // MEMORY
        if (prev_curr_memory != MEMORY && valid_memory && prev_curr_memory != NONE) {
            kanata_file << "E\t" << id_memory << "\t0\t" << "E" << std::endl;
            kanata_file << "S\t" << id_memory << "\t0\t" << "M" << std::endl;
        }

        // WRITEBACK
        if (prev_curr_writeback != WRITEBACK && valid_writeback && prev_curr_writeback != NONE) {
            kanata_file << "E\t" << id_writeback << "\t0\t" << "M" << std::endl;
            kanata_file << "S\t" << id_writeback << "\t0\t" << "W" << std::endl;
        }

        // COMMIT
        if (prev_curr_commit != COMMIT && valid_commit && prev_curr_commit != NONE) {
            kanata_file << "E\t" << id_commit << "\t0\t" << "W" << std::endl;
            kanata_file << "R\t" << id_commit << "\t0\t" << 0 << std::endl;

            instruction_stage.erase(id_commit);
        }

        instruction_stage[id_fetch] = FETCH;

        if (valid_decode && prev_curr_decode != NONE)
            instruction_stage[id_decode] = DECODE;
        else if (prev_curr_decode == NONE)
            instruction_stage[id_decode] = NONE;

        if (valid_execute && prev_curr_execute != NONE)
            instruction_stage[id_execute] = EXECUTE;
        else if (prev_curr_execute == NONE)
            instruction_stage[id_execute] = NONE;

        if (valid_memory && prev_curr_memory != NONE)
            instruction_stage[id_memory] = MEMORY;
        else if (prev_curr_memory == NONE)
            instruction_stage[id_memory] = NONE;

        if (valid_writeback && prev_curr_writeback != NONE)
            instruction_stage[id_writeback] = WRITEBACK;
        else if (prev_curr_writeback == NONE)
            instruction_stage[id_writeback] = NONE;
    }

}

extern "C" void close_kanata() {
    kanata_file.close();
}
