/* MR-sys verilator main
 *
 * Copyright 2020-2022 Matt Evans
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *    http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

#include <stdlib.h>
#include <unistd.h>
#include <signal.h>
#include <errno.h>
#include <fcntl.h>
#include <limits.h>
#include <time.h>

#include "testbench.h"
#include "arch_state.h"

/* Globals */
Testbench *tb = 0;
char *uart_init_string = (char *)"";
volatile uint64_t current_limit = 0;
volatile int sig_request = 0;
#define SR_DUMP_REGS	1
#define SR_SAVE_STATE	2
char *save_state_filename = NULL;
unsigned int save_state_generation = 0;

extern void checker(Testbench *tb);
extern void checker_init(Testbench *tb, uint32_t log_flags);

double sc_time_stamp ()
{
        return tb->get_tickcount();
}

static void print_help(char *nom)
{
	fprintf(stderr, "Syntax:\n\t%s [options]\n\nOptions:\n"
		"\t-t <VCD filename>\n"
		"\t-T <trace from cycle N>\n"
		"\t-s <int32 DIP value>\n"
		"\t-i <initial string to send to console>\n"
		"\t-l <cycle count limit>\n"
		"\t-p <initial PC override>\n"
		"\t-S <state save filename>\n"
		"\t-x \tSave state at exit\n"
		"\t-R <restore file>\n"
		"\t-A <restore arch state file>\n"
#ifdef CHECKER
                "\t-F <checker log flags>\n"
#endif
                "\t-X <uninitialised random seed>\n"
		"\n",
		nom);
}

static void	sighandler(int sig)
{
	/* Signals might interrupt at a point at which state is only
	 * semi-coherent, so instead change the limit to drop out of
	 * the main loop and deal with requests there.
	 */
	if (sig == SIGUSR1) {
		sig_request |= SR_DUMP_REGS;
		current_limit = 0;
	} else if (sig == SIGUSR2) {
		sig_request |= SR_SAVE_STATE;
		current_limit = 0;
	}
}

static void 	setup_sighandlers(void)
{
	signal(SIGUSR1, sighandler);
	signal(SIGUSR2, sighandler);
}

static void 	dump_regs(Testbench *tb)
{
	printf("--------------------------------------------------------------------------------\n"
	       "Cycle %lld:\tPC %08x  MSR %08x  LR %08x  CTR %08x\n",
	       tb->get_tickcount(),
	       tb->getTop()->tb_top->MR->CPU->CPU->MEM->memory_pc_r,
	       tb->getTop()->tb_top->MR->CPU->CPU->MEM->memory_msr_r,
	       tb->getTop()->tb_top->MR->CPU->CPU->DE->SPRF->as_LR,
	       tb->getTop()->tb_top->MR->CPU->CPU->DE->SPRF->as_CTR);
	printf("XER %08x  CR %08x  SRR0 %08x  SRR1 %08x  DAR %08x  DSISR %08x\n",
	       (uint32_t)(((tb->getTop()->tb_top->MR->CPU->CPU->DE->as_XERCR >> 3)
			   & 0xe0000000) |
			  ((tb->getTop()->tb_top->MR->CPU->CPU->DE->as_XERCR >> 35)
			   & 0x7f)),
	       (uint32_t)(tb->getTop()->tb_top->MR->CPU->CPU->DE->as_XERCR & 0xffffffff),
	       tb->getTop()->tb_top->MR->CPU->CPU->DE->SPRF->as_SRR0,
	       tb->getTop()->tb_top->MR->CPU->CPU->DE->SPRF->as_SRR1,
	       tb->getTop()->tb_top->MR->CPU->CPU->DE->SPRF->as_DAR,
	       tb->getTop()->tb_top->MR->CPU->CPU->DE->SPRF->as_DSISR);
	for (int i = 0; i < 32; i++) {
		if ((i & 7) == 0)
			printf("GPR%02d\t", i);
		printf("%08x ",
		       tb->getTop()->tb_top->MR->CPU->CPU->DE->GPRF->registers[i]);
		if ((i & 7) == 7)
			printf("\n");
	}
	printf("--------------------------------------------------------------------------------\n");
	// Other stats here.
}

static void	save_state(Testbench *tb)
{
	char filename[PATH_MAX];

	dump_regs(tb);

	if (save_state_generation == 0)
		strncpy(filename, save_state_filename, PATH_MAX);
	else
		snprintf(filename, PATH_MAX, "%s.%d", save_state_filename, save_state_generation);
	save_state_generation++;

	printf("Saving state to '%s': ", filename);

	VerilatedSave vs;

	vs.open(filename);
	if (!vs.isOpen()) {
		printf("State save FAILED (can't open file)\n");
	} else {
		vs << *tb->getTop();

		vs.flush();
		vs.close(); // ??
		printf("State save success\n");
	}
}

static void	restore_state(Testbench *tb, char *filename)
{
	printf("Restoring state from '%s': ", filename);

	VerilatedRestore vl;

	vl.open(filename);
	if (!vl.isOpen()) {
		printf("State restore FAILED (can't open file)\n");
	} else {
		vl.fill();

		vl >> *tb->getTop();

		vl.close();
		printf("State restore success\n");
	}

	dump_regs(tb);
}

static void	restore_arch_state(Testbench *tb, char *filename)
{
	int fd, r;

	fd = open(filename, O_RDONLY);
	if (fd < 0) {
		printf("Can't open state file '%s' (errno %d)\n",
		       filename, errno);
		return;
	}
	printf("Restoring arch state from '%s' (fd %d): ", filename, fd);

	r = tb_restore_arch_state(fd, tb);
	if (!r)
		printf("State restore success\n");
	else
		printf("State restore FAILED\n");

	dump_regs(tb);

	close(fd);
}

int main(int argc, char **argv)
{
	char *exe_name = argv[0];
	int ch;
	uint64_t sw = 0;
	uint64_t tick_limit = ~0; // Never runs infinitely, but millenia will do
	uint64_t trace_from = 0;
	int override_pc = 0;
	uint32_t override_pc_val;
	char *restore_fname = NULL;
	char *restore_arch_fname = NULL;
	int save_at_exit = 0;
#ifdef CHECKER
        uint32_t checker_log_flags = 0;
#endif
        uint64_t random_seed = time(NULL);

	save_state_filename = strdup("sim_dump.bin");

	Verilated::commandArgs(argc, argv);
	tb = new Testbench();

	while ((ch = getopt(argc, argv, "t:s:i:l:T:p:R:S:xA:X:"
#ifdef CHECKER
                            "F:"
#endif
                            "h")) != -1) {
                switch (ch) {
                        case 't':
				printf("Writing VCD trace to %s\n", optarg);
				// The docs claim using $dumpfile works; I get
				// an unsupp PLI error.  This enables VCD
				// output:
				tb->opentrace(optarg);
                                break;

			case 'T':
				trace_from = strtoull(optarg, NULL, 0);
				printf("Tracing from cycle %lu\n", trace_from);
				tb->traceFrom(trace_from);
                                break;

			case 's':
				sw = strtoul(optarg, NULL, 0);
				printf("Setting DIP switches to %08x\n", (uint32_t)sw);
				sw |= 0x8000000000000000;
				break;

			case 'i':
				uart_init_string = strdup(optarg);
				printf("Initial string '%s'\n", uart_init_string);
				break;

			case 'l':
				tick_limit = strtoull(optarg, NULL, 0);
				printf("Setting tick limit to %lu\n", tick_limit);
				break;

			case 'p':
				override_pc = 1;
				override_pc_val = strtoull(optarg, NULL, 0);
				printf("Overriding initial PC to 0x%08x\n", override_pc_val);
				break;

			case 'R':
				restore_fname = strdup(optarg);
				break;

			case 'S':
				free(save_state_filename);
				save_state_filename = strdup(optarg);
				printf("Setting save state filename to %s\n", save_state_filename);
				break;

			case 'x':
				save_at_exit = 1;
				printf("Saving state at exit\n");
				break;

			case 'A':
				restore_arch_fname = strdup(optarg);
				printf("Setting arch restore filename to %s\n", restore_arch_fname);
				break;
#ifdef CHECKER
			case 'F':
				checker_log_flags = strtoull(optarg, NULL, 0);
				printf("Checker log flags 0x%08x\n", checker_log_flags);
				break;
#endif
                        case 'X':
                                random_seed = strtoull(optarg, NULL, 0);
                                break;
			case 'h':
			default:
				print_help(exe_name);
				return 1;
		}
	}

	//////////////////////////////////////////////////////////////////////

        printf("Random seed 0x%016llx\n", random_seed);
        srand48(random_seed);

	setup_sighandlers();

	tb->ioemul_init();

#ifdef CHECKER
        checker_init(tb, checker_log_flags);
#endif

	printf("--------------------------------------------------------------------------------\n");

        tb->reset();

	/* If switches set, set switches */
	if (sw) {
		tb->getTop()->tb_top->gpio = sw & 0xffffffff;
	}

	if (override_pc) {
		tb->getTop()->tb_top->MR->CPU->CPU->IF->current_pc = override_pc_val;
	}

	if (restore_fname) {
		restore_state(tb, restore_fname);
	}

	if (restore_arch_fname) {
		restore_arch_state(tb, restore_arch_fname);
	}

	/* Main loop */
	do {
		current_limit = tick_limit;
		while(!tb->done() && tb->get_tickcount() < current_limit) {
			tb->tick();

#ifdef BRANCH_TRACE
                        if (tb->getTop()->tb_top->MR->CPU->CPU->MEM->new_pc_valid) {
                                printf("%08x\n", tb->getTop()->tb_top->MR->CPU->CPU->MEM->new_pc);
                        }
#endif
#ifdef SYSCALL_TRACE
                        if (tb->getTop()->tb_top->MR->CPU->CPU->MEM->memory_valid_r &&
                                tb->getTop()->tb_top->MR->CPU->CPU->MEM->memory_fault_r == 4) {
                                printf("+++ STRACE PC %08x: sc(%4d): args=%08x %08x %08x %08x\n",
                                       tb->getTop()->tb_top->MR->CPU->CPU->MEM->memory_pc_r,
                                       tb->getTop()->tb_top->MR->CPU->CPU->DE->GPRF->registers[0],
                                       tb->getTop()->tb_top->MR->CPU->CPU->DE->GPRF->registers[3],
                                       tb->getTop()->tb_top->MR->CPU->CPU->DE->GPRF->registers[4],
                                       tb->getTop()->tb_top->MR->CPU->CPU->DE->GPRF->registers[5],
                                       tb->getTop()->tb_top->MR->CPU->CPU->DE->GPRF->registers[6]
                                        );

                        }
#endif
#ifdef CHECKER
                        checker(tb);
#endif
		}

		// Broken out of loop e.g. from signal handler?
		if (sig_request) {
			if (sig_request & SR_DUMP_REGS) {
				dump_regs(tb);
			}
			if (sig_request & SR_SAVE_STATE) {
				save_state(tb);
			}
			sig_request = 0;
		}
	} while (!tb->done() && tb->get_tickcount() < tick_limit);

        printf("Complete:  Committed %d instructions, %d stall cycles, %lu cycles total\n",
               tb->getTop()->tb_top->MR->CPU->CPU->WB->counter_instr_commit,
               tb->getTop()->tb_top->MR->CPU->CPU->WB->counter_stall_cycle,
               tb->get_tickcount());

	dump_regs(tb);
	if (save_at_exit)
		save_state(tb);

        exit(EXIT_SUCCESS);
}

