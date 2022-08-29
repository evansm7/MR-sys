/* MR-sys verilated sim I/O routines
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
#include <netinet/in.h>
#include <arpa/inet.h>
#include <sys/socket.h>
#include <poll.h>
#include <fcntl.h>
#include "testbench.h"


////////////////////////////////////////////////////////////////////////////////
// Services exposed over sockets

#define CONSOLE_PORT 	2000
#define DEBUG_PORT 	2001

// Initial console string
extern char *uart_init_string;
static int uart_init_string_len = -1;
static int uart_init_string_pos = 0;

const int poll_interval_max = 10000;
const int poll_interval_min = 100;
const int poll_interval_delta = 100;
static int poll_interval_cur = poll_interval_max;

/* This function should be as fast as possible:
 *
 * - Look for received data that needs to be dealt with
 * - Look for any socket activity to manage
 */
uint64_t	Testbench::io_poll_work(void)
{
	uint64_t work = 0;

	// Sets bits corresponding to input streams
	work = io_poll_sockets();

	/***** Console UART *****/
	if (uart_init_string_pos < uart_init_string_len) {
		// May already be set due to socket input
		work |= IO_WORK_UART;
	}

	/***** Debug channel *****/
	// Nothing: only input from socket.
	return work;
}

uint8_t		Testbench::io_dbg_rx_data(void)
{
	uint8_t d;
	/* uart_poll_socket() said data was waiting */
	assert(dbg_skt != -1);
	int r = read(dbg_skt, &d, 1);
	// could poll here, and flag more_work_to_do as more bytes await
	return d;
}

uint8_t 	Testbench::io_uart_rx_data(void)
{
	uint8_t d;
	if (uart_init_string_pos < uart_init_string_len) {
		d = uart_init_string[uart_init_string_pos++];
	} else /* uart_poll_socket() said yes */ {
		assert(uart_skt != -1);
		int r = read(uart_skt, &d, 1);
	}
	return d;
}

static int	accept_conn(int lskt)
{
	int s;
	struct sockaddr_in addr;
	socklen_t alen = sizeof(addr);
	s = accept(lskt, (struct sockaddr *)&addr, &alen);
	if (s >= 0) {
		fprintf(stderr, "[%d: New connection (fd %d)]\n", lskt, s);
		if (fcntl(s, F_SETFL, O_NONBLOCK) == -1) {
			perror("Can't set socket non-blocking\n");
		}
	}
	return s;
}

uint64_t Testbench::io_poll_sockets(void)
{
	static int poll_count = 0;
	/* Hack:  Avoid doing a syscall every tick by polling
	 * fairly rarely - this will still give good interactive
	 * speeds but might not transfer data particularly quickly.
	 *
	 * The proper fix is to move polling into another thread, such that
	 * this test is one memory access in the common case.
	 */
	if (++poll_count < poll_interval_cur)
		return 0;
	poll_count = 0;

	//////////////////////////////////////////////////////////////////////

	uint64_t work = 0;

	const int num_services = 2;
	int num = num_services;

	// Poll on at least each service's listenFD:
	struct pollfd f[num_services * 2] = {
		[0] = {
                        .fd = uart_listen_skt,
                        .events = POLLIN,
                        .revents = 0
		},
		[1] = {
                        .fd = dbg_listen_skt,
                        .events = POLLIN,
                        .revents = 0
		},
	};

	// And, optionally poll on each service's connectionFD:
	struct {
		int *fd;
		uint64_t work_type;
	} client_fds[num_services];

	if (uart_skt != -1) {
		f[num].fd = uart_skt;
		f[num].events = POLLIN;
		f[num].revents = 0;
		client_fds[num-num_services].fd = &uart_skt;
		client_fds[num-num_services].work_type = IO_WORK_UART;
		num++;
	}

	if (dbg_skt != -1) {
		f[num].fd = dbg_skt;
		f[num].events = POLLIN;
		f[num].revents = 0;
		client_fds[num-num_services].fd = &dbg_skt;
		client_fds[num-num_services].work_type = IO_WORK_DBG;
		num++;
	}

	if (poll(f, num, 0) > 0) {
		int lskts[] = { uart_listen_skt, dbg_listen_skt };
		int *fds[] = { &uart_skt, &dbg_skt };

		for (int i = 0; i < num_services; i++) {
			if (f[i].revents != 0)
				*fds[i] = accept_conn(lskts[i]);
		}

		for (int i = num_services; i < num; i++) {
			if (f[i].revents & (POLLERR | POLLHUP)) {
				fprintf(stderr, "[Connection dropped on fd %d]\n",
					*client_fds[i-num_services].fd);
				*client_fds[i-num_services].fd = -1;
			} else if (f[i].revents & POLLIN) {
				work |= client_fds[i-num_services].work_type;
			}
		}
	}

	/* Hack on a hack: adjust the poll interval.  If we've had work the past
	 * N times we've looked, poll more frequently.  If we haven't, poll less
	 * frequently.  Bound by max/min.  (For simplicity, N=1)
	 */
	static int busy_last_time = 0;
	if (work && busy_last_time && poll_interval_cur > poll_interval_min) {
		poll_interval_cur -= poll_interval_delta;
	}
	if (!work && !busy_last_time && poll_interval_cur < poll_interval_max) {
		poll_interval_cur += poll_interval_delta;
	}
	busy_last_time = !!work;

	return work;
}

void Testbench::ioemul_init(void)
{
	struct sockaddr_in listenaddr;

	/* Init UART sockets */
	uart_skt = -1;

        if ((uart_listen_skt = socket(AF_INET, SOCK_STREAM, 0)) == -1) {
                perror("Can't create listening socket\n");
                return;
        }

        /* Bind the local address to the sending socket, any port number */
        listenaddr.sin_family = AF_INET;
        listenaddr.sin_addr.s_addr = INADDR_ANY;
        listenaddr.sin_port = htons(CONSOLE_PORT);

        if (bind(uart_listen_skt, (struct sockaddr *)&listenaddr, sizeof(listenaddr))) {
                perror("Can't bind() socket\n");
                return;
        }
        if (listen(uart_listen_skt, 1)) {
                perror("Can't listen() on socket\n");
                return;
        }

	printf("Console UART: listening on port %d (fd %d)\n",
	       CONSOLE_PORT, uart_listen_skt);


	/* Init debug sockets */
	dbg_skt = -1;

        if ((dbg_listen_skt = socket(AF_INET, SOCK_STREAM, 0)) == -1) {
                perror("Can't create listening socket\n");
                return;
        }

        listenaddr.sin_port = htons(DEBUG_PORT);

        if (bind(dbg_listen_skt, (struct sockaddr *)&listenaddr, sizeof(listenaddr))) {
                perror("Can't bind() socket\n");
                return;
        }
        if (listen(dbg_listen_skt, 1)) {
                perror("Can't listen() on socket\n");
                return;
        }

	printf("Debug requester: listening on port %d (fd %d)\n",
	       DEBUG_PORT, dbg_listen_skt);

	if (uart_init_string)
		uart_init_string_len = strlen(uart_init_string);
}

void Testbench::ioemul(void)
{
	uint64_t work;

	work = io_poll_work();

	//////////////////////////////////////////////////////////////////////
	// UART TX
	/* Look for console UART stuff */
	if (m_core->tb_top->MR->CONSOLE_UART->tx_has_data) {
		/* The verilog connects consume strobe to has_data, so this is present for
		 * just one cycle.
		 */
		printf("%c", m_core->tb_top->MR->CONSOLE_UART->next_tx_byte);
		if (uart_skt != -1)
			write(uart_skt,
			      &m_core->tb_top->MR->CONSOLE_UART->next_tx_byte, 1);
	}

	//////////////////////////////////////////////////////////////////////
	// UART RX
	int wait = 0;
	// Ther's a data readable; write it if the FIFO's okay with that:
	if (work & IO_WORK_UART &&
	    m_core->tb_top->MR->CONSOLE_UART->rx_has_space) {
		m_core->tb_top->MR->CONSOLE_UART->rxd_new = io_uart_rx_data();
		m_core->tb_top->MR->CONSOLE_UART->bsu_rx_strobe = 1;
	} else {
		m_core->tb_top->MR->CONSOLE_UART->bsu_rx_strobe = 0;
	}

	//////////////////////////////////////////////////////////////////////
	// DBG TX
	if (m_core->tb_top->dbg_tx_has_data) { // Stuff to TX
		/* Verilog connects tx_consume to tx_has_data, so this condition is present for one cycle */
		if (dbg_skt != -1) {
			write(dbg_skt, &m_core->tb_top->dbg_tx_data, 1);
		}
	}

	// DBG RX
	if (work & IO_WORK_DBG &&
	    m_core->tb_top->dbg_rx_has_space) {
		m_core->tb_top->dbg_rx_data = io_dbg_rx_data();
		m_core->tb_top->dbg_rx_produce = 1;
	} else {
		m_core->tb_top->dbg_rx_produce = 0;
	}
}
