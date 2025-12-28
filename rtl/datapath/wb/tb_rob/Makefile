TOP       := tb_rob
OBJ_DIR   := obj_dir
EXE       := $(OBJ_DIR)/V$(TOP)

VERILATOR := verilator

SV_SRCS := \
	../../../../includes/tartaruga_pkg.sv \
	../rob.sv \
	tb_rob.sv

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
	--Wno-WIDTH \
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
