# Makefile: Verilator + filelist
# Uso:
#   make            -> genera el ejecutable de simulación
#   make run        -> ejecuta la simulación
#   make wave       -> ejecuta la simulación y genera trace.vcd si tu sim_main lo habilita
#   make clean      -> limpia artefactos

# --- Configurables ---
VERILATOR ?= verilator
TOP        ?= top    # nombre del top-level module (sin prefijos)
FILELIST   ?= filelist.lst
BUILD_DIR  ?= obj_dir
SIM_MAIN   ?= simulator/sim_main.cpp simulator/commit_log.cpp simulator/kanata.cpp simulator/elf_reader.cpp simulator/unified_mem.cpp

CXXFLAGS  ?= -std=c++17 -O2
VERILATOR_FLAGS ?= --cc --exe --trace-fst --trace-structs --trace-depth 99 -Wall -Wno-UNUSED -Wno-WIDTH -Wno-PINCONNECTEMPTY -MMD --assert --debug
# Añade includes si hace falta, por ejemplo: CPPFLAGS += -I../rtl/include

# --- lectura de filelist: ignora comentarios y líneas vacías ---
# cada línea del FILELIST debe ser la ruta a un .v / .sv
SRCS := $(shell awk '!/^#/ && NF {print $$0}' $(FILELIST))

# fichero ejecutable esperado (Verilator genera V$(TOP) dentro de BUILD_DIR)
EXEC := $(BUILD_DIR)/V$(TOP)

.PHONY: all verilate build run wave clean show-files

all: $(EXEC)

# Regla principal: correr Verilator y compilar con el Makefile que genera
$(EXEC): $(FILELIST) $(SIM_MAIN)
	@echo "=== Verilating: top=$(TOP), build_dir=$(BUILD_DIR) ==="
	@mkdir -p $(BUILD_DIR)
	$(VERILATOR) $(VERILATOR_FLAGS) -Mdir $(BUILD_DIR) --top-module $(TOP) $(SRCS) --exe $(SIM_MAIN) --build
	@# el flag --build compila y enlaza automáticamente en la mayoría de versiones
	@# si tu versión de verilator no soporta --build, puedes usar:
	@# $(VERILATOR) $(VERILATOR_FLAGS) -Mdir $(BUILD_DIR) --top-module $(TOP) $(SRCS) --exe $(SIM_MAIN)
	@# $(MAKE) -C $(BUILD_DIR) -f V$(TOP).mk
	@echo "=== Build finished: $(EXEC) ==="

# Forzar solo la generación de la capa verilator (sin compilar) -- útil para depurar
verilate: $(FILELIST)
	@mkdir -p $(BUILD_DIR)
	$(VERILATOR) $(VERILATOR_FLAGS) -Mdir $(BUILD_DIR) --top-module $(TOP) $(SRCS) --exe $(SIM_MAIN)
	@echo "Verilated sources are in $(BUILD_DIR)"

# Ejecutar la simulación (asume que el ejecutable se creó)
run: all
	@echo "=== Ejecutando $(EXEC) ==="
	@$(EXEC) $(RUN_ARGS)

# Ejecutar y pedir traza (si sim_main.cpp soporta un flag o env var)
wave: all
	@echo "=== Ejecutando con traza (vcd) ==="
	@# Puedes definir en sim_main.cpp que si existe la env VAR GEN_TRACE=1 cree un vcd
	@GEN_TRACE=1 $(EXEC) $(RUN_ARGS)

# Muestra las fuentes leídas desde filelist (útil para depuración)
show-files:
	@echo "=== Files read from $(FILELIST) ==="
	@awk '{ if ($$0 ~ /^#/ || $$0 ~ /^$$/) next; print $$0 }' $(FILELIST)

clean:
	@echo "Cleaning $(BUILD_DIR) and Verilator-generated files..."
	-@rm -rf $(BUILD_DIR) obj_dir *.vcd *.dat *.log *.wdb csrc **/*.out **/*.program **/*.commit
	-@find . -name "*~" -delete
	@echo "Clean done."

# Si quieres pasar banderas extra al compilador, úsalo así:
#   make CXXFLAGS="-g -O0 -DDEBUG" run
