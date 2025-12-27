TOP       := tb_imem_wrapper
OBJ_DIR   := obj_dir
EXE       := $(OBJ_DIR)/V$(TOP)

VERILATOR := verilator

SV_SRCS := \
	../../../includes/tartaruga_pkg.sv \
	../imem_wrapper.sv \
	tb_imem_wrapper.sv

VERILATOR_FLAGS := \
	--binary \
	--sv \
	--timing \
	--trace \
	--trace-fst \
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
