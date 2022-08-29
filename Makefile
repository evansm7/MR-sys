# MattRISC SoC Makefile
#
# Firmware & simulation
#
# Copyright 2020-2022 Matt Evans
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

DEBUG ?= 0
REAL_RAM ?= 0
NO_LTO ?= 0
WITH_CHECKER ?= 0
BRANCH_TRACE ?= 0
SYSCALL_TRACE ?= 0

SRC_PATH = src
INC_PATH = include
IVERILOG = iverilog
IVFLAGS = -g2009 -Wall -Wno-timescale

PATHS = -y MR-hw/src -y mic-hw/src -y src -y tb
PATHS += -IMR-hw/include -Itb
DEFS = -DSIM

ifneq ($(DEBUG), 0)
        DEFS += -DDEBUG
endif

VCFLAGS = -O3

ifneq ($(REAL_RAM), 0)
        DEFS += -DREAL_RAM
	PATHS += -y models/ -Imodels/
	VCFLAGS += -DREAL_RAM
endif

ifeq ($(NO_LTO), 0)
	VCFLAGS += -flto
endif

ifneq ($(WITH_CHECKER), 0)
	VCFLAGS += -DCHECKER
	OTHER_OBJECTS = ../MR-ISS/libiss.a
endif

ifneq ($(BRANCH_TRACE), 0)
	VCFLAGS += -DBRANCH_TRACE
endif

ifneq ($(SYSCALL_TRACE), 0)
	VCFLAGS += -DSYSCALL_TRACE
endif

VDEFS = -DVERILATOR_IO

VERILOG_SOURCES = mr_top.v

all:	run_tb_top

%.wave: %.vcd
	gtkwave $<

%.vcd:	%.vvp
	vvp $<

# TODO:
# Integrate with submodule makefiles, e.g. build_deps in the MR-hw repo.

################################################################################

# Main integrated CPU test:
tb_top.vvp:	tb/iv_tb_top.v
	$(IVERILOG) $(IVFLAGS) $(DEFS) $(PATHS) -o $@ $<

verilate_tb_top: tb/tb_top.v verilator/testbench.h verilator/main.cpp
	verilator --x-initial unique -Mdir verilator/obj_dir -Wall -Wno-fatal --trace --savable -cc tb/tb_top.v --top-module tb_top $(PATHS) -CFLAGS "$(VCFLAGS)" --exe ../main.cpp ../io.cpp ../arch_state.cc $(OTHER_OBJECTS) $(DEFS) $(VDEFS) -DVERILATOR=1
	(cd verilator/obj_dir ; make -f Vtb_top.mk -j 4)
	@echo "\nEXE is:  ./verilator/obj_dir/Vtb_top"

run_tb_top: verilate_tb_top
	@echo "\nRunning verilated build:\n"
	time ./verilator/obj_dir/Vtb_top

################################################################################

clean:
	rm -rf *.vvp *.vcd verilator/obj_dir
