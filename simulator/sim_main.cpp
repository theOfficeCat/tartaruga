/*#include "Vtop.h"            // Verilator genera este header (V + nombre del top)
#include "verilated.h"       // Librería base de Verilator
#include "verilated_vcd_c.h" // Para traza VCD (si usas --trace)

#include <iostream>
#include <cstdlib>  // for getenv
#include <string>

// Tiempo simulado (en ticks)
vluint64_t main_time = 0;

// Función obligatoria para Verilator (retorna tiempo actual)
double sc_time_stamp() { return main_time; }

int main(int argc, char **argv) {
    Verilated::commandArgs(argc, argv); // procesa args estándar

    Verilated::traceEverOn(true); // antes de instanciar el top o de cualquier eval()
    // Instancia del diseño top
    Vtop *top = new Vtop;

    // Control de traza
    VerilatedVcdC* tfp = nullptr;
    bool gen_trace = false;
    const char* env_trace = std::getenv("GEN_TRACE"); // ejemplo: GEN_TRACE=1 make run
    if (env_trace && std::string(env_trace) == "1") {
        Verilated::traceEverOn(true);
        tfp = new VerilatedVcdC;
        top->trace(tfp, 99);   // nivel de profundidad
        tfp->open("trace.vcd");
        gen_trace = true;
        std::cout << "[sim] VCD tracing enabled (trace.vcd)\n";
    }*/
#include "Vtop.h"
#include "verilated.h"
#include "verilated_fst_c.h"
#include <iostream>
#include <cstdlib>
#include <string>

vluint64_t main_time = 0;
double sc_time_stamp() { return main_time; }

int main(int argc, char **argv) {
    Verilated::commandArgs(argc, argv);
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

    return 0;
}

