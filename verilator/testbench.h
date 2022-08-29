#ifndef TESTBENCH_H
#define TESTBENCH_H

/* Based on TB class from https://zipcpu.com/blog/2017/06/21/looking-at-verilator.html
 *
 * The templating just made things messy, so removed - not needed.
 */

#include <stdlib.h>
#include <inttypes.h>
#include "Vtb_top.h"
#include "verilated.h"
#include "verilated_vcd_c.h"
#include "Vtb_top__Syms.h"


class Testbench {
	uint64_t	m_tickcount;
	uint64_t	m_tick_trace_threshold;
	Vtb_top		*m_core;
        VerilatedVcdC	*m_trace;
public:
	Testbench(void) {
		m_trace = 0;
		m_core = new Vtb_top;
		m_tickcount = 0l;
		m_tick_trace_threshold = ~0;
                Verilated::traceEverOn(true);
	}

	Vtb_top *getTop() { return m_core; }

	virtual	void	opentrace(const char *vcdname) {
		if (!m_trace) {
			m_trace = new VerilatedVcdC;
			m_core->trace(m_trace, 99);
			m_trace->open(vcdname);
			m_tick_trace_threshold = 0;
		}
	}

	virtual void 	traceFrom(uint64_t trace_from) {
		m_tick_trace_threshold = trace_from;
	}

	// Close a trace file
	virtual void	close(void) {
		if (m_trace) {
			m_trace->close();
			m_trace = NULL;
			m_tick_trace_threshold = ~0;
		}
	}

	virtual ~Testbench(void) {
		delete m_core;
		m_core = NULL;
	}

	virtual void	reset(void) {
		m_core->reset = 1;
		// Lite version doesn't do any IO stuff before reset:
		this->tick_lite();
		this->tick_lite();
		this->tick_lite();
		this->tick_lite();
		m_core->reset = 0;
	}

	virtual void	tick(void) {
		// Increment our own internal time reference
		m_tickcount++;

		// Make sure any combinatorial logic depending upon
		// inputs that may have changed before we called tick()
		// has settled before the rising edge of the clock.
                //		m_core->clk = 0;
                //		m_core->eval();
		// if(m_trace) m_trace->dump(10*m_tickcount-2);
                // ME: No comb inputs (for now!)

		// Toggle the clock

		// Rising edge
		m_core->clk = 1;
		m_core->eval();

		ioemul();

		if (m_tickcount >= m_tick_trace_threshold)
			m_trace->dump((vluint64_t)(10*m_tickcount));

		// Falling edge
		m_core->clk = 0;
		m_core->eval();

		if (m_tickcount >= m_tick_trace_threshold) {
			// This portion, though, is a touch different.
			// After dumping our values as they exist on the
			// negative clock edge ...
			m_trace->dump((vluint64_t)(10*m_tickcount+5));
			//
			// We'll also need to make sure we flush any I/O to
			// the trace file, so that we can use the assert()
			// function between now and the next tick if we want to.
			m_trace->flush();
		}
	}

	virtual void	tick_lite(void) {
		m_tickcount++;
		m_core->clk = 1;
		m_core->eval();
		if (m_tickcount >= m_tick_trace_threshold)
			m_trace->dump((vluint64_t)(10*m_tickcount));

		m_core->clk = 0;
		m_core->eval();
		if (m_tickcount >= m_tick_trace_threshold)
			m_trace->dump((vluint64_t)(10*m_tickcount));
	}

	virtual bool	done(void) { return (Verilated::gotFinish()); }

        uint64_t 	get_tickcount() { return m_tickcount; }
	void		ioemul(void);
	void		ioemul_init(void);

private:
	/* IO interfaces */
	static const uint64_t	IO_WORK_UART 	= 0x00000001;
	static const uint64_t	IO_WORK_DBG  	= 0x00000002;

	uint64_t	io_poll_work(void);
	uint64_t	io_poll_sockets(void);

	uint8_t		io_dbg_rx_data(void);
	uint8_t		io_uart_rx_data(void);

	int		uart_listen_skt;
	int		uart_skt;

	int		dbg_listen_skt;
	int		dbg_skt;
};

#endif
