#include "Vtop.h"
#include "verilated.h"
#include "verilated_fst_c.h"
#include <iostream>
#include <cstdlib>
#include <string>

extern "C" bool load_data(const char* path);
extern "C" void init_commit(std::string path);
extern "C" void close_commit();

vluint64_t main_time = 0;
double sc_time_stamp() { return main_time; }

int main(int argc, char **argv) {
    Verilated::commandArgs(argc, argv);

    if (argc < 2) {
        std::cerr << "No program to execute" << std::endl;
        return 1;
    }

    std::cerr << argv[1] << std::endl;

    load_data(argv[1]);
    init_commit(std::string(argv[1]) + std::string(".commit"));

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
    const uint64_t max_cycles = 100; // límite de seguridad
    for (uint64_t cycle = 0; cycle < max_cycles && !Verilated::gotFinish(); ++cycle) {
        // clock negativo
        top->clk_i = 0;
        top->eval();
        if (gen_trace) tfp->dump(main_time);
        main_time++;

        // clock positivo
        top->clk_i = 1;
        top->eval();
        if (gen_trace) tfp->dump(main_time);
        main_time++;


        // condición de parada opcional (por ejemplo, una señal done)
        // if (top->done) break;
    }

    std::cout << "[sim] Finished at cycle " << main_time/2 << std::endl;

    // Cierra traza y limpia
    if (gen_trace) {
        tfp->close();
        delete tfp;
    }
    top->final();
    delete top;

    close_commit();

    return 0;
}

