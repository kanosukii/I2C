//For std::unique_ptr
#include <memory>
//Include common routines
#include <verilated.h>
//Include model header, generated form Verilating "top.v"
#include "Vtop.h"

int main(int argc, char** argv){

	//Prevent unused variable warnings
	if(false && argc && argv) {}

	//Create logs/ directory in case we have traces to put under it
	Verilated::mkdir("logs");

	//Construct a VerilatedContext to hold simulation and then deleting at end
	const std::unique_ptr<VerilatedContext> contextp{new VerilatedContext};

	//Set debug level, 0 is off, 9 is highest presently used
	contextp->debug(0);

	//Randomization reset (memory value) policy & make reset pin 1'b1 for 2 cycles
	contextp->randReset(2);

	//Verilator must compute traced signals
	contextp->traceEverOn(true);

	//Pass arguments so Verilated code can see them, a.g. $value$plusargs
	contextp->commandArgs(argc,argv);

	//Construct the Verilated model, from Vtop.h generated from Verilating "top.v"
	const std::unique_ptr<Vtop> top{new Vtop{contextp.get(), "TOP"}};	

	//Set Vtop's input signals
	top->clk = 0x0;
	top->rst = 0x1;
	top->wdata = 0x5f;
	top->addr = 0x1a;
	top->rw = 0x0;
	top->start = 0x0;

	while(contextp->time() < 1000){

	contextp->timeInc(1);//1 timeprecision period passes...
	
	top->clk = !top->clk;//Toggle a fast (time/2 period) clock

	if(contextp->time() > 3){
	top->rst = 0x0;
	};
	
	if((contextp->time() > 5 && contextp->time()< 15) || (contextp->time() > 400 && contextp->time()< 415))
		top->start = 0x1;
	else
		top->start = 0x0;

	if(contextp->time() > 400){
	top->rw = 0x1;
	};
	

	top->eval();
	}


	top->final();

#if VM_COVERAGE
		Verilated::mkdir("logs");
		contextp->coveragep()->write("logs/coverage.dat");
#endif

	return 0;
}
