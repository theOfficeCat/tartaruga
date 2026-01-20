TOP       := tb_new_dcache
OBJ_DIR   := obj_dir
EXE       := $(OBJ_DIR)/V$(TOP)

VERILATOR := verilator

SV_SRCS := \
	../../../includes/tartaruga_pkg.sv \
	../../../includes/riscv_pkg.sv \
	../new_dcache.sv \
	tb_new_dcache.sv

VERILATOR_FLAGS := \
	--binary \
	--sv \
	--timing \
	--trace \
	--trace-fst \
	--trace-structs \
	--trace-depth 99 \
	--Wno-UNUSEDPARAM \
	--Wno-INITIALDLY \
	-DTB \
	--top-module $(TOP)

all: run

$(EXE): $(SV_SRCS)
	$(VERILATOR) $(VERILATOR_FLAGS) $(SV_SRCS)
	$(MAKE) -C $(OBJ_DIR) -f V$(TOP).mk

run: $(EXE)
	./$(EXE)

clean:
	rm -rf $(OBJ_DIR) *.vcd

.PHONY: all run clean
