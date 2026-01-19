#include "Vtop.h"
#include "verilated.h"
#include "verilated_fst_c.h"
#include <iostream>
#include <cstdlib>
#include <string>

extern "C" bool load_data(const char* path);
extern "C" void init_commit(std::string path);
extern "C" void close_commit();

extern "C" void init_kanata(std::string path);
extern "C" void close_kanata();

extern bool load_elf(const char *path);
extern void write_mem_dump(const char* path);

vluint64_t main_time = 0;
double sc_time_stamp() { return main_time; }

int main(int argc, char **argv) {
    Verilated::commandArgs(argc, argv);

    if (argc < 2) {
        std::cerr << "No program to execute" << std::endl;
        return 1;
    }

    std::cerr << argv[1] << std::endl;

    //load_data(argv[1]);
    if (!load_elf(argv[1])) {
        std::cerr << "Failed to load ELF file: " << argv[1] << std::endl;
        return 1;
    }
    init_commit(std::string(argv[1]) + std::string(".commit"));
    init_kanata(std::string(argv[1]) + std::string(".kanata"));

    Verilated::traceEverOn(true); // activa trazas globales antes del eval

    Vtop *top = new Vtop;
    VerilatedFstC* tfp = nullptr;

    const char* env_trace = std::getenv("GEN_TRACE");
    bool gen_trace = (env_trace && std::string(env_trace) == "1");

    if (gen_trace) {
        tfp = new VerilatedFstC;
        top->trace(tfp, 99);   // profundidad alta
        tfp->open("trace.fst");
        std::cout << "[sim] Trazas FST habilitadas (trace.fst)\n";
    }

    // Inicializa señales
    top->clk_i   = 0;
    top->rstn_i = 0; // suponiendo reset activo bajo

    // Ciclos de reset
    for (int i = 0; i < 11; i++) {
        top->clk_i = !top->clk_i;
        top->eval();
        if (gen_trace) tfp->dump(main_time);
        main_time++;
    }
    top->rstn_i = 1; // libera reset

    // Bucle principal de simulación
    //const uint64_t max_cycles = 10000; // límite de seguridad
    //for (uint64_t cycle = 0; cycle < max_cycles && !Verilated::gotFinish(); ++cycle) {
    uint32_t cycles_without_commit = 0;
    uint32_t total_cycles = 0;
    uint32_t commited_instructions = 0;
    while (!Verilated::gotFinish() && cycles_without_commit <= 100 && main_time < 100000) {
        // clock negativo
        top->clk_i = 0;
        top->eval();
        if (gen_trace) tfp->dump(main_time);
        main_time++;

        total_cycles++;
        if (top->commit_valid_o == 1) {
            cycles_without_commit = 0;
            commited_instructions++;
        } else {
            cycles_without_commit++;
        }

        // clock positivo
        top->clk_i = 1;
        top->eval();
        if (gen_trace) tfp->dump(main_time);
        main_time++;


        // condición de parada opcional (por ejemplo, una señal done)
        // if (top->done) break;
    }

    std::cout << "[sim] Finished at cycle " << main_time/2 << std::endl;

    std::cout << "[sim] Total cycles: " << total_cycles << std::endl;
    std::cout << "[sim] Committed instructions: " << commited_instructions << std::endl;
    std::cout << "[sim] IPC: " << (double)commited_instructions / total_cycles << std::endl;
    std::cout << "[sim] CPI: " << (double)total_cycles / commited_instructions << std::endl;

    if (cycles_without_commit >= 100) {
        std::cout << "[sim] Execution killed for more than 100 cycles without commiting instructions" << std::endl;
    }

    write_mem_dump("memory_dump.txt");

    // Cierra traza y limpia
    if (gen_trace) {
        tfp->close();
        delete tfp;
    }
    top->final();
    delete top;

    close_commit();
    close_kanata();

    return 0;
}
