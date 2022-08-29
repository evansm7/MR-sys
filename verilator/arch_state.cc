/* MR-sys verilated sim architectural state import, and checker
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

#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <inttypes.h>

#include "testbench.h"
#include "arch_state.h"


typedef struct {
	uint64_t 	name;
	uint64_t 	len; // Excluding header, in bytes (rounded to 8)
	uint64_t 	data;
} ss_chunk_t;


#define STS_GPR_FMT	"GPR%02d"
#define STS_SR_FMT	"SR%02d"
#define STS_MEM		"MEMBLK"

#define STS_MEM_CHUNK_SZ	0x200000


int 	tb_restore_arch_state(int fd, Testbench *tb)
{
	uint64_t 	val;
	ss_chunk_t	ch;
	int		r;

	do {
		r = read(fd, &ch, sizeof(ch));
		if (r != sizeof(ch)) 	break;

		// What's the chunk just read?
		if (!strcmp("PC", (char *)&ch.name)) {
			tb->getTop()->tb_top->MR->CPU->CPU->IF->current_pc = ch.data;
			tb->getTop()->tb_top->MR->CPU->CPU->IF->fetch_pc = ch.data;
		} else if (!strcmp("MSR", (char *)&ch.name)) {
			tb->getTop()->tb_top->MR->CPU->CPU->IF->current_msr = ch.data;
			tb->getTop()->tb_top->MR->CPU->CPU->IF->fetch_msr = ch.data;
		} else if (!strcmp("CTR", (char *)&ch.name))
			tb->getTop()->tb_top->MR->CPU->CPU->DE->SPRF->as_CTR = ch.data;
		else if (!strcmp("LR", (char *)&ch.name))
			tb->getTop()->tb_top->MR->CPU->CPU->DE->SPRF->as_LR = ch.data;
		else if (!strcmp("XER", (char *)&ch.name))
			tb->getTop()->tb_top->MR->CPU->CPU->DE->as_XERCR =
				((ch.data & 0x7f) << 35) | ((ch.data & 0xe0000000) << 3) |
				(tb->getTop()->tb_top->MR->CPU->CPU->DE->as_XERCR & 0xffffffff);
		else if (!strcmp("CR", (char *)&ch.name))
			tb->getTop()->tb_top->MR->CPU->CPU->DE->as_XERCR =
				(tb->getTop()->tb_top->MR->CPU->CPU->DE->as_XERCR & ~0xffffffff) |
				(ch.data & 0xffffffff);
		else if (!strcmp("HID0", (char *)&ch.name))
		{ /* No register */ }
		else if (!strcmp("HID1", (char *)&ch.name))
		{ /* No register */ }
		else if (!strcmp("SPRG0", (char *)&ch.name))
			tb->getTop()->tb_top->MR->CPU->CPU->DE->SPRF->as_SPRG0 = ch.data;
		else if (!strcmp("SPRG1", (char *)&ch.name))
			tb->getTop()->tb_top->MR->CPU->CPU->DE->SPRF->as_SPRG1 = ch.data;
		else if (!strcmp("SPRG2", (char *)&ch.name))
			tb->getTop()->tb_top->MR->CPU->CPU->DE->SPRF->as_SPRG2 = ch.data;
		else if (!strcmp("SPRG3", (char *)&ch.name))
			tb->getTop()->tb_top->MR->CPU->CPU->DE->SPRF->as_SPRG3 = ch.data;
		else if (!strcmp("SRR0", (char *)&ch.name))
			tb->getTop()->tb_top->MR->CPU->CPU->DE->SPRF->as_SRR0 = ch.data;
		else if (!strcmp("SRR1", (char *)&ch.name))
			tb->getTop()->tb_top->MR->CPU->CPU->DE->SPRF->as_SRR1 = ch.data;
		else if (!strcmp("DAR", (char *)&ch.name))
			tb->getTop()->tb_top->MR->CPU->CPU->DE->SPRF->as_DAR = ch.data;
		else if (!strcmp("DSISR", (char *)&ch.name))
			tb->getTop()->tb_top->MR->CPU->CPU->DE->SPRF->as_DSISR = ch.data;
		else if (!strcmp("DEC", (char *)&ch.name))
			tb->getTop()->tb_top->MR->CPU->CPU->DE->TBDEC->as_DEC = ch.data;
		else if (!strcmp("TB", (char *)&ch.name))
			tb->getTop()->tb_top->MR->CPU->CPU->DE->TBDEC->as_TB = ch.data;
		else if (!strcmp("SDR1", (char *)&ch.name))
			tb->getTop()->tb_top->MR->CPU->CPU->DE->SPRF->as_SDR1 = ch.data;
		else if (!strcmp("IBAT0U", (char *)&ch.name))
			tb->getTop()->tb_top->MR->CPU->CPU->DE->SPRF->as_IBAT0U = ch.data;
		else if (!strcmp("IBAT0L", (char *)&ch.name))
			tb->getTop()->tb_top->MR->CPU->CPU->DE->SPRF->as_IBAT0L = ch.data;
		else if (!strcmp("IBAT1U", (char *)&ch.name))
			tb->getTop()->tb_top->MR->CPU->CPU->DE->SPRF->as_IBAT1U = ch.data;
		else if (!strcmp("IBAT1L", (char *)&ch.name))
			tb->getTop()->tb_top->MR->CPU->CPU->DE->SPRF->as_IBAT1L = ch.data;
		else if (!strcmp("IBAT2U", (char *)&ch.name))
			tb->getTop()->tb_top->MR->CPU->CPU->DE->SPRF->as_IBAT2U = ch.data;
		else if (!strcmp("IBAT2L", (char *)&ch.name))
			tb->getTop()->tb_top->MR->CPU->CPU->DE->SPRF->as_IBAT2L = ch.data;
		else if (!strcmp("IBAT3U", (char *)&ch.name))
			tb->getTop()->tb_top->MR->CPU->CPU->DE->SPRF->as_IBAT3U = ch.data;
		else if (!strcmp("IBAT3L", (char *)&ch.name))
			tb->getTop()->tb_top->MR->CPU->CPU->DE->SPRF->as_IBAT3L = ch.data;
		else if (!strcmp("DBAT0U", (char *)&ch.name))
			tb->getTop()->tb_top->MR->CPU->CPU->DE->SPRF->as_DBAT0U = ch.data;
		else if (!strcmp("DBAT0L", (char *)&ch.name))
			tb->getTop()->tb_top->MR->CPU->CPU->DE->SPRF->as_DBAT0L = ch.data;
		else if (!strcmp("DBAT1U", (char *)&ch.name))
			tb->getTop()->tb_top->MR->CPU->CPU->DE->SPRF->as_DBAT1U = ch.data;
		else if (!strcmp("DBAT1L", (char *)&ch.name))
			tb->getTop()->tb_top->MR->CPU->CPU->DE->SPRF->as_DBAT1L = ch.data;
		else if (!strcmp("DBAT2U", (char *)&ch.name))
			tb->getTop()->tb_top->MR->CPU->CPU->DE->SPRF->as_DBAT2U = ch.data;
		else if (!strcmp("DBAT2L", (char *)&ch.name))
			tb->getTop()->tb_top->MR->CPU->CPU->DE->SPRF->as_DBAT2L = ch.data;
		else if (!strcmp("DBAT3U", (char *)&ch.name))
			tb->getTop()->tb_top->MR->CPU->CPU->DE->SPRF->as_DBAT3U = ch.data;
		else if (!strcmp("DBAT3L", (char *)&ch.name))
			tb->getTop()->tb_top->MR->CPU->CPU->DE->SPRF->as_DBAT3L = ch.data;
		else if (!strcmp("IRQ", (char *)&ch.name))
		{ /* No register yet */ }
		else if (!strcmp("IC_ISR", (char *)&ch.name)) {
                        /* This is the captured state of edge inputs,
                         * assuming levels will sort themselves out in
                         * due course.
                         */
                        tb->getTop()->tb_top->MR->INTC->pending = ch.data >> 4; // FIXME, probe size
                } else if (!strcmp("IC_IER", (char *)&ch.name)) {
                        tb->getTop()->tb_top->MR->INTC->enabled = ch.data;
                } else if (!strcmp("IC_MER", (char *)&ch.name)) {
                        tb->getTop()->tb_top->MR->INTC->me = ch.data & 1;
                        tb->getTop()->tb_top->MR->INTC->hie = !!(ch.data & 2);
                } else if (!strcmp("CON_SR", (char *)&ch.name))	{
                        /* Actually, wat.. this is calculated live
                         * from FIFO status, which isn't supported
                         * yet.  FIFOs are empty.
                         */
		} else if (!strcmp("CON_ISR", (char *)&ch.name)) {
                        tb->getTop()->tb_top->MR->CONSOLE_UART->REGIF->irq_status = ch.data;
		} else if (!strcmp("CON_IER", (char *)&ch.name)) {
                        tb->getTop()->tb_top->MR->CONSOLE_UART->REGIF->irq_enable = ch.data;
                } else if (!strcmp(STS_MEM, (char *)&ch.name)) {
			/* Memory block */
			uint64_t base = ch.data;
			uint64_t len = ch.len;
#ifndef REAL_RAM
			// MR3 platform has two banks, starting at 0 and starting 0x01000000:
                        void *to;
                        if (base < 0x01000000)
                                to = &tb->getTop()->tb_top->MR->genblk1__DOT__RAMA_BRAM->RAM[base/8];
                        else
                                to = &tb->getTop()->tb_top->MR->genblk1__DOT__RAMB_BRAM->RAM[(base-0x01000000)/8];
                        r = read(fd, to, len-8);
#else
#warning "Arch state restore only supported when using BRAM"
                        r = -1;
#endif
			if (r < len-8) {
				printf("Short read on memory chunk! (%d)\n", r);
				break;
			}
			printf("Restored RAM chunk %08x-%08x\n", (uint32_t)base, (uint32_t)(base+len-8-1));
		} else {
			// Multi-named things
			int found = 0;

			// SRs
			for (int i = 0; i < 16; i++) {
				char name[8];
				sprintf(name, STS_SR_FMT, i);
				if (!strcmp(name, (char *)&ch.name)) {
					tb->getTop()->tb_top->MR->CPU->CPU->MEM->segment[i] = ch.data;
					found = 1;
					break;
				}
			}

			// GPRs
			if (!found) {
				for (int i = 0; i < 32; i++) {
					char name[8];
					sprintf(name, STS_GPR_FMT, i);
					if (!strcmp(name, (char *)&ch.name)) {
						tb->getTop()->tb_top->MR->CPU->CPU->DE->GPRF->registers[i] = ch.data;
						found = 1;
						break;
					}
				}
			}

			if (!found) {
				printf("--- Unknown arch state chunk '%s', ignoring\n",
				       (char *)&ch.name);
			}
		}
	} while (r > 0);

	return 0;
}

#ifdef CHECKER

/* The checker uses (parts of) MR-ISS to execute an interpreted instruction
 * when WB commits a real instruction, comparing register state after and looking
 * for differences.
 *
 * This relies on an MR-ISS build (make libiss.a DUMMY_MEM_ACCESS=1) in the same directory.
 */

#include "MR-ISS/PPCCPUState.h"
#define DUMMY_MEM_ACCESS 1
#include "MR-ISS/PPCInterpreter.h"
#include "MR-ISS/PPCMMU.h"

uint32_t log_enables_mask = 0;
PPCCPUState pcs; // FIXME construct from vars
PPCInterpreter interp;
PPCMMU mmu;


void checker_init(Testbench *tb, uint32_t log_flags)
{
        printf("Initialising checker\n");
        interp.setCPUState(&pcs);
        interp.setMMU(&mmu);

        log_enables_mask = log_flags;
}

void checker(Testbench *tb)
{
        /* If this cycle commits a valid instruction (and not a
         * fault), then execute the instruction in the interpreter and
         * compare any integer/flags results.
         *
         * Loads are supported in so far as the value from MR's cache
         * is forwarded to the instruction; realistically, this just
         * validates the update forms.  Stores are a NOP.
         *
         * Faults from memory ops or IF are hard to check, so are
         * ignored.  Illegal/syscall could be, but "looks like it
         * works" so not spending that effort yet.
         *
         * In future will have to disable forwarding for this to work!
         * Reg file assumed up to date!
         */
        if (tb->getTop()->tb_top->MR->CPU->CPU->MEM->memory_valid_i &&
            tb->getTop()->tb_top->MR->CPU->CPU->MEM->memory_fault_r == 0) {
                uint32_t inst = tb->getTop()->tb_top->MR->CPU->CPU->MEM->memory_instr_r;
                uint32_t pc = tb->getTop()->tb_top->MR->CPU->CPU->MEM->memory_pc_r;

                /* Dig out the arch state: */
                for (int i = 0; i < 32; i++) {
                        pcs.setGPR(i, tb->getTop()->tb_top->MR->CPU->CPU->DE->GPRF->registers[i]);
                }
                pcs.setPC(pc);
                pcs.setMSR(tb->getTop()->tb_top->MR->CPU->CPU->MEM->memory_msr_r);
                pcs.setCTR(tb->getTop()->tb_top->MR->CPU->CPU->DE->SPRF->as_CTR);
                pcs.setLR(tb->getTop()->tb_top->MR->CPU->CPU->DE->SPRF->as_LR);
                pcs.setXER(((tb->getTop()->tb_top->MR->CPU->CPU->DE->as_XERCR >> 3) & 0xe0000000) |
                           ((tb->getTop()->tb_top->MR->CPU->CPU->DE->as_XERCR >> 35) & 0x7f));
                pcs.setCR(tb->getTop()->tb_top->MR->CPU->CPU->DE->as_XERCR & 0xffffffff);
                /* TB is annoying because right now it's 1 or 2 cycles ahead of the value read.
                 * So, just capture the result to work around so that mftb works OK:
                 */
                pcs.setTB(tb->getTop()->tb_top->MR->CPU->CPU->MEM->memory_R0_r |
                          ((uint64_t)tb->getTop()->tb_top->MR->CPU->CPU->MEM->memory_R0_r << 32));
                pcs.setDEC(tb->getTop()->tb_top->MR->CPU->CPU->DE->TBDEC->as_DEC);
                pcs.setSPRG0(tb->getTop()->tb_top->MR->CPU->CPU->DE->SPRF->as_SPRG0);
                pcs.setSPRG1(tb->getTop()->tb_top->MR->CPU->CPU->DE->SPRF->as_SPRG1);
                pcs.setSPRG2(tb->getTop()->tb_top->MR->CPU->CPU->DE->SPRF->as_SPRG2);
                pcs.setSPRG3(tb->getTop()->tb_top->MR->CPU->CPU->DE->SPRF->as_SPRG3);
                pcs.setSRR0(tb->getTop()->tb_top->MR->CPU->CPU->DE->SPRF->as_SRR0);
                pcs.setSRR1(tb->getTop()->tb_top->MR->CPU->CPU->DE->SPRF->as_SRR1);
                pcs.setDAR(tb->getTop()->tb_top->MR->CPU->CPU->DE->SPRF->as_DAR);
                pcs.setDSISR(tb->getTop()->tb_top->MR->CPU->CPU->DE->SPRF->as_DSISR);

                // FIXME: BATs and SRs, SDR1

                /* Hack for loads: furtle out the read data and return that via PPCMMU: */
                interp.read_data = tb->getTop()->tb_top->MR->CPU->CPU->MEM->DTC->DCACHE->DFMTR->data;

                interp.setPCInst(pc, inst); // For interpreter's disassembler
                interp.decode(inst);

                /* Compare state: */
                uint32_t iv, hv;
                int mismatch = 0;
                if (tb->getTop()->tb_top->MR->CPU->CPU->WB->writeback_gpr_port0_en_int) {
                        unsigned int gpr = tb->getTop()->tb_top->MR->CPU->CPU->WB->writeback_gpr_port0_reg_int;
                        iv = pcs.getGPR(gpr);
                        hv = tb->getTop()->tb_top->MR->CPU->CPU->WB->writeback_gpr_port0_value_int;

                        if (iv != hv) {
                                printf("*** %08x (cycle %10ld) %08x:  GPR%02d: WB %08x vs interp %08x (p0)\n",
                                       pc, tb->get_tickcount(), inst, gpr, hv, iv);
                                mismatch = 1;
                        }
                }
                if (tb->getTop()->tb_top->MR->CPU->CPU->WB->writeback_gpr_port1_en_int) {
                        unsigned int gpr = tb->getTop()->tb_top->MR->CPU->CPU->WB->writeback_gpr_port1_reg_int;
                        iv = pcs.getGPR(gpr);
                        hv = tb->getTop()->tb_top->MR->CPU->CPU->WB->writeback_gpr_port1_value_int;

                        if (iv != hv) {
                                printf("*** %08x (cycle %10ld) %08x:  GPR%02d: WB %08x vs interp %08x (p1)\n",
                                       pc, tb->get_tickcount(), inst, gpr, hv, iv);
                                mismatch = 1;
                        }
                }
                if (tb->getTop()->tb_top->MR->CPU->CPU->WB->writeback_xercr_en_int) {
                        uint64_t v = tb->getTop()->tb_top->MR->CPU->CPU->WB->writeback_xercr_value_int;
                        uint32_t hxer = ((v >> 3) & 0xe0000000) | ((v >> 35) & 0x7f);
                        uint32_t hcr = v & 0xffffffff;

                        if ((pcs.getCR() != hcr) || (pcs.getXER() != hxer)) {
                                printf("*** %08x (cycle %10ld) %08x:  WB XER %08x CR %08x vs interp XER %08x CR %08x\n",
                                       pc, tb->get_tickcount(), inst, hxer, hcr, pcs.getXER(), pcs.getCR());
                                mismatch = 1;
                        }
                }
                // FIXME, SPR alteration:
                // tb_top->MR->CPU->CPU->WB->writeback_spr_en_int
                // tb_top->MR->CPU->CPU->WB->writeback_sspr_en_int

                if (mismatch) {
                }
        }
}

/* Misc support for MR-ISS junk */

int     lprintf(const char *format, ...)
{
        va_list va;
        va_start(va, format);
        vfprintf(stderr, format, va);
        va_end(va);
        return 0;
}

void    sim_quit(void)
{
        printf("Quitty quit quit\n");
}


#endif // CHECKER
