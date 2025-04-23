#Check for sanity to avoid later confusion
ifneq ($(words $(CURDIR)),1)
	$(error Unsupported: GUN Make cannot build in directories containing spaces, build elsewhere: '$(CURDIR)')
endif

#$(VERILATOR_ROOT) is in the environment
VERILATOR = verilator
VERILATOR_COVERAGE = verilator_coverage

# Generate C++ in executable form
VERILATOR_FLAGS += -cc --exe
# Optimize
VERILATOR_FLAGS += -x-assign fast
# Warn abount lint issues; may not want this on less solid designs
VERILATOR_FLAGS += -Wall
# Make waveforms
VERILATOR_FLAGS += --trace
# Generate coverage analysis
VERILATOR_FLAGS += --coverage
# Ban warn about unused signal
VERILATOR_FLAGS += --Wno-UNUSEDSIGNAL
#Ban warn about pin connect empty
#VERILATOR_FLAGS += --Wno-PINCONNECTEMPTY
#Input verilog file
VSRCS = $(shell find $(abspath ./vcode) -name "*.v")
VERILATOR_INPUT = $(VSRCS) sim_main.cpp
TOP = --top-module top

default:
	@echo "-- VERILATE % BUILD --------"

	$(VERILATOR) $(VERILATOR_FLAGS) $(VERILATOR_INPUT) $(TOP) 
	@echo "--Verilator--"
	@echo "--Build--"
	$(MAKE) -j -C obj_dir -f ../Makefile_obj
	@echo "--Build--"
	@rm -rf logs
	@mkdir -p logs
	obj_dir/Vtop +trace

	@rm -rf logs/annotated
	$(VERILATOR_COVERAGE) --annotate logs/annotated logs/coverage.dat
	@echo "--DONE------------"
	gtkwave ./logs/vlt_dump.vcd

clean:
	-rm -rf obj_dir logs *.log *.dmp *.vpd coverage core
