# My homebuilt PowerPC-ish RISC system

v1.0 29th August 2022

(I'll revisit this README and make it less braindumpy...)


“MR” is a for-fun computer system for FPGA platforms.  It’s designed to be a thing to sit at, i.e. with video, sound, keyboard/mouse, modern storage, and networking.

I’ve been using this as an enjoyable and silly Linux machine — comparable to an early-1990s workstation.  (For those who weren’t there at the time, that means surprisingly capable with not much resource!)

<FIXME: Insert cool picture of the MR system in action!>


## MR-sys, MR-hw, mic-hw, MR-fw

This repository is the top level that uses components from a couple of other adjacent repositories:

   * _MR-hw_:  The CPU (a 5-stage RISC PowerPC-like CPU)
   * _mic-hw_:  System interconnect, memory controllers, system peripherals (e.g. IRQ controller, SPI, SD, video, audio, serial)

That’s the hardware; then, there’s corresponding firmware (_MR-fw_) and OS (Linux) repositories to run on the thing.


## SoC shape

The FPGA build top level is specific to the board/platform being built for, and interfaces between specific pinouts and the more generic `top_mr` system top level.  `top_mr` is instantiation-time parametrisable, so the FPGA top-level can enable features pinned out/supported by a given platform.

My development platform is the obsolete and dumpster-dived ARM LT-XC5VLX330 Virtex-5 LogicTile, together with some adapter boards to pin everything out.  Though you certainly don’t want to use this platform build (I’d be surprised if anyone still has this LT kicking about), it represents a “full” configuration of the SoC:

   * One MR 32-bit RISC CPU with caches, MMU 🖥
   * A 4x4 MIC interconnect crossbar with a 4x1 nested on top
   * An APB bridge (all peripherals are MMIO via APB, and some have a DMA port back to MIC)
   * One or two LCDCs (my demo machine has an internal display with an optional external DVI output) 📺👾📽
   * Remote memory system R/W (via FT232 parallel interface)
    * Download dev kernel images quickly!
   * I2S audio 🔈
   * SPI for external WiFi (I’m using a Microchip WILC3000), or an ENC28J60 emergency Ethernet interface 📡
   * UARTs for console (and eventually BT) 
   * PS/2 keyboard & mouse interfaces ⌨️
   * SD host controller 💾
   * Controllers for 2x banks of 64-bit ZBT SRAM (32MB total)
   * A 64KB bank of BlockRAM at the top of the address space, initialised at build time with init/boot firmware

This repository places platform-specific top-levels/build dirs in `platform/`.

To try to head off the “nerrr where’s OFW/AXI/60x/etc.”:  Everything in this project has been intentionally wheel-reinvented and written from scratch as an enjoyable act of leisure, including interfaces, so re-use elsewhere may need a bit of wrapping/skinning.


## Repo layout/arranging the stars

MR-sys doesn’t yet use submodules (or manifest-based tools like `repo`), so you (currently) need to arrange checkouts of (HEAD of) the other components as follows:

```
/path/MR-sys/
/path/MR-sys/mic-hw/
/path/MR-sys/MR-hw/
/path/MR-sys/ram_init.hex
```
`ram_init.hex` is the initial contents of the boot RAM at the top of the physical address space, containing the bootloader.  In my system, it's generated (using `mk_hex`) from the `bl.bin` build output of the `MR-fw` project.


# Platforms/building

## FPGA build

FIXME: I’m working on supporting platforms that ANYONE else has, starting with the Digilent Arty-100.  Watch this space.

Unfortunately, each platform/board might have a different vendor-specific toolchain, but the intention is building a bitstream is a matter of:

```$ cd …/MR-sys/platform/YER_BOARD/
$ make
```

The custom `ltxc5` platform needs Xilinx’s ISE tools (14.7), whereas newer Xilinx platforms will use Vivado, and ECP5 platforms will use Yosys.


## Simulation with Verilator

As an exercise to learn how Verilator works/can be used, the Verilator harness has some useful features beyond running-and-tracing:

   * Checkpoint save/restore
   * Architected state import from MR-ISS
    * (Boot fast in MR-ISS, save state, import)
   * TCP sockets for debug pipe (`r_debug`) and UART I/O
   * MR-ISS co-simulation
    * Build MR-ISS `libiss.a`, consumed by the Verilated build when `CHECKER=1`
    * This checks the architected state after (most) instructions are completed
   * Syscall/branch tracing
   * Via SIGUSR1/SIGUSR2, dump register state/dump simulator checkpoint

`make` will build `verilator/obj_dir/Vtb_top`, which simulates the whole system:

~~~
Syntax:
	./verilator/obj_dir/Vtb_top [options]

Options:
	-t <VCD filename>
	-T <trace from cycle N>
	-s <int32 DIP value>
	-i <initial string to send to console>
	-l <cycle count limit>
	-p <initial PC override>
	-S <state save filename>
	-x 	Save state at exit
	-R <restore file>
	-A <restore arch state file>
	-X <uninitialised random seed>
~~~


# Obligatory Linux boot log

~~~
*** Booting (UART) ***

Bootloader version 0.1, built 14:50:15 13/06/22
Boot RAM at 0xfff00000, size 0x00010000 
GPIO inputs: 0000000c
- Running on HW

RAM at 0x0: bacecace 
RAM OK
Audio synth playing...done.
TFP410 found at 70, revision 00.
- TFP410 write test OK
- TFP410 CTL_2 = 06
lcdc_init(0): initial regs:
LCDC regs:
	ID = 0x44430001
	FB_BASE = 0x00000000
	XPOS = 61, YPOS = 263
	WIDTH = 640, XMUL = 1, HEIGHT = 480, YMUL = 1
	-ve VSYNC, width = 3, front porch = 1, back porch = 26
	-ve HSYNC, width = 64, front porch = 16, back porch = 120
	DWPL = 39, BPPlog2 = 3
lcdc_setmode:  WARNING: No PLL fn for pixclk 25175000
Setting screen mode 1 (640x480-60).
lcdc_setmode:  WARNING: No PLL fn for pixclk 25175000
LCDC regs:
	ID = 0x44430001
	FB_BASE = 0x01fa5000
	XPOS = 514, YPOS = 348
	WIDTH = 640, XMUL = 0, HEIGHT = 480, YMUL = 0
	-ve VSYNC, width = 2, front porch = 10, back porch = 33
	-ve HSYNC, width = 96, front porch = 16, back porch = 48
	DWPL = 79, BPPlog2 = 3
Waiting for host download
Got 0x00700000, executing:
---- Going to (kernel) userspace (sp 0x01ffffb4, pc 0x00700000): ----
--------------------------------------------------------------------------------


zImage starting: loaded at 0x00700000 (sp: 0x00d6bfa0)
No valid compressed data found, assume uncompressed data
Allocating 0x665010 bytes for kernel...
0x64b00c bytes of uncompressed data copied

Linux/PowerPC load: console=ttyMR0 earlyprintk earlycon debug root=/dev/mmcblk0p1 rootwait
Finalizing device tree... flat tree at 0xd6c8c0
printk: bootconsole [udbg0] enabled
ioremap() called early from of_setup_earlycon+0xa4/0x260. Use early_ioremap() instead
earlycon: mruart_a0 at MMIO 0x82000000 (options '')
printk: bootconsole [mruart_a0] enabled
Total memory = 30MB; using 64kB for hash table
Linux version 5.10.0-00048-ga2c26294462a-dirty (matt@ry) (powerpc-linux-gnu-gcc (Ubuntu 8.4.0-3ubuntu1) 8.4.0, GNU ld (GNU Binutils for Ubuntu) 2.34) #290 Fri Jun 24 19:22:45 BST 2022
Using MR machine description
-----------------------------------------------------
phys_mem_size     = 0x1ed4000
dcache_bsize      = 0x20
icache_bsize      = 0x20
cpu_features      = 0x0000000004000000
  possible        = 0x00000000277de148
  always          = 0x0000000000000000
cpu_user_features = 0x84000000 0x00000000
mmu_features      = 0x00000001
Hash_size         = 0x10000
Hash_mask         = 0x3ff
-----------------------------------------------------
MR Platform
Top of RAM: 0x1ed4000, Total RAM: 0x1ed4000
Memory hole size: 0MB
Zone ranges:
  Normal   [mem 0x0000000000000000-0x0000000001ed3fff]
Movable zone start for each node
Early memory node ranges
  node   0: [mem 0x0000000000000000-0x0000000001ed3fff]
Initmem setup node 0 [mem 0x0000000000000000-0x0000000001ed3fff]
On node 0 totalpages: 7892
  Normal zone: 62 pages used for memmap
  Normal zone: 0 pages reserved
  Normal zone: 7892 pages, LIFO batch:0
pcpu-alloc: s0 r0 d32768 u32768 alloc=1*32768
pcpu-alloc: [0] 0 
Built 1 zonelists, mobility grouping on.  Total pages: 7830
Kernel command line: console=ttyMR0 earlyprintk earlycon debug root=/dev/mmcblk0p1 rootwait
Dentry cache hash table entries: 4096 (order: 2, 16384 bytes, linear)
Inode-cache hash table entries: 2048 (order: 1, 8192 bytes, linear)
mem auto-init: stack:off, heap alloc:off, heap free:off
Memory: 24596K/31568K available (4180K kernel code, 276K rwdata, 1120K rodata, 872K init, 100K bss, 6972K reserved, 0K cma-reserved)
Kernel virtual memory layout:
  * 0xffbdf000..0xfffff000  : fixmap
  * 0xc2000000..0xffbdf000  : vmalloc & ioremap
SLUB: HWalign=32, Order=0-3, MinObjects=0, CPUs=1, Nodes=1
NR_IRQS: 32, nr_irqs: 32, preallocated irqs: 16
irq-xilinx: /soc/interrupt-controller@82070000: num_irq=32, edge=0xfffffff0
time_init: decrementer frequency = 30.000000 MHz
time_init: processor frequency   = 60.000000 MHz
clocksource: timebase: mask: 0xffffffffffffffff max_cycles: 0xdd67c8a60, max_idle_ns: 881590406601 ns
clocksource: timebase mult[10aaaaab] shift[23] registered
clockevent: decrementer mult[7ae147b] shift[32] cpu[0]
Console: colour dummy device 80x25
pid_max: default: 32768 minimum: 301
Mount-cache hash table entries: 1024 (order: 0, 4096 bytes, linear)
Mountpoint-cache hash table entries: 1024 (order: 0, 4096 bytes, linear)
devtmpfs: initialized
random: get_random_u32 called from bucket_table_alloc.isra.28+0xf8/0x128 with crng_init=0
clocksource: jiffies: mask: 0xffffffff max_cycles: 0xffffffff, max_idle_ns: 19112604462750000 ns
futex hash table entries: 256 (order: -1, 3072 bytes, linear)
NET: Registered protocol family 16
DMA: preallocated 128 KiB GFP_KERNEL pool for atomic allocations
clocksource: Switched to clocksource timebase
simple-framebuffer 1fa5000.framebuffer: framebuffer at 0x1fa5000, 0x4b000 bytes, mapped to 0x(ptrval)
simple-framebuffer 1fa5000.framebuffer: format=8grey, mode=640x480x8, linelength=640
Console: switching to colour frame buffer device 80x30
simple-framebuffer 1fa5000.framebuffer: fb0: simplefb registered!
NET: Registered protocol family 2
tcp_listen_portaddr_hash hash table entries: 512 (order: 0, 4096 bytes, linear)
TCP established hash table entries: 1024 (order: 0, 4096 bytes, linear)
TCP bind hash table entries: 1024 (order: 0, 4096 bytes, linear)
TCP: Hash tables configured (established 1024 bind 1024)
UDP hash table entries: 256 (order: 0, 4096 bytes, linear)
UDP-Lite hash table entries: 256 (order: 0, 4096 bytes, linear)
NET: Registered protocol family 1
Initialise system trusted keyrings
workingset: timestamp_bits=30 max_order=13 bucket_order=0
Key type asymmetric registered
Asymmetric key parser 'x509' registered
io scheduler mq-deadline registered
Serial: 8250/16550 driver, 4 ports, IRQ sharing enabled
82000000.serial: ttyMR0 at MMIO 0x82000000 (irq = 16, base_baud = 0) is a mruart
printk: console [ttyMR0] enabled
printk: console [ttyMR0] enabled
printk: bootconsole [udbg0] disabled
printk: bootconsole [udbg0] disabled
printk: bootconsole [mruart_a0] disabled
printk: bootconsole [mruart_a0] disabled
brd: module loaded
loop: module loaded
SBD device driver, major=254
spi-mr 82090000.spi: MR SPI bus driver
enc28j60 spi0.0: Ethernet driver 1.02 loaded
enc28j60 spi0.0: chip not found
enc28j60: probe of spi0.0 failed with error -5
Broadcom 43xx driver loaded [ Features: NLS ]
mrps2 82010000.mrps2: mr-ps2: Port 0 at MMIO 0x82010000, IRQ 17
mrps2 82020000.mrps2: mr-ps2: Port 1 at MMIO 0x82020000, IRQ 18
mousedev: PS/2 mouse device common for all mice
mr-sd 820b0000.sd: mr-sd regs at c210b000, irq 19
mr-sd 820b0000.sd: mr-sd: probe complete
ledtrig-cpu: registered to indicate activity on CPUs
Initializing XFRM netlink socket
NET: Registered protocol family 17
drmem: No dynamic reconfiguration memory found
Loading compiled-in X.509 certificates
cfg80211: Loading compiled-in X.509 certificates for regulatory database
cfg80211: Loaded X.509 cert 'sforshee: 00b28ddf47aef9cea7'
platform regulatory.0: Direct firmware load for regulatory.db failed with error -2
cfg80211: failed to load regulatory.db
mmc0: new SDHC card at address aaaa
mmcblk0: mmc0:aaaa SC32G 29.7 GiB 
 mmcblk0: p1 p2
input: AT Raw Set 2 keyboard as /devices/platform/soc/82020000.mrps2/serio1/input/input1
input: ImExPS/2 Generic Explorer Mouse as /devices/platform/soc/82010000.mrps2/serio0/input/input2
EXT4-fs (mmcblk0p1): mounted filesystem without journal. Opts: (null)
VFS: Mounted root (ext4 filesystem) readonly on device 179:1.
devtmpfs: mounted
Freeing unused kernel memory: 872K
Kernel memory protection not selected by kernel config.
Run /sbin/init as init process
  with arguments:
    /sbin/init
    earlyprintk
  with environment:
    HOME=/
    TERM=linux
random: fast init done
EXT4-fs (mmcblk0p1): re-mounted. Opts: (null)
Starting syslogd: OK
Starting klogd: OK
Running sysctl: OK
Starting system message bus: random: dbus-uuidgen: uninitialized urandom read (12 bytes read)
random: dbus-uuidgen: uninitialized urandom read (8 bytes read)
random: dbus-daemon: uninitialized urandom read (12 bytes read)
done
Starting network: OK
Starting dropbear sshd: OK

Welcome to Buildroot
ppcboard login: root
# 
# ls /bin
[1;36march[m           [1;36mdomainname[m     [1;36mls[m             [1;36mps[m             [1;36muname[m
[1;36mash[m            [1;36mdumpkmap[m       [1;32mlsattr[m         [1;36mpwd[m            [1;32muncompress[m
[1;36mbase32[m         [1;36mecho[m           [1;32mmk_cmds[m        [1;36mresume[m         [1;36musleep[m
[1;36mbase64[m         [1;32megrep[m          [1;36mmkdir[m          [1;36mrm[m             [1;36mvi[m
[1;32mbash[m           [1;36mfalse[m          [1;36mmknod[m          [1;36mrmdir[m          [1;36mwatch[m
[1;32mbusybox[m        [1;36mfdflush[m        [1;36mmktemp[m         [1;36mrun-parts[m      [1;36mypdomainname[m
[1;36mcat[m            [1;32mfgrep[m          [1;36mmore[m           [1;32msed[m            [1;32mzcat[m
[1;32mchattr[m         [1;36mgetopt[m         [1;36mmount[m          [1;36msetarch[m        [1;32mzcmp[m
[1;36mchgrp[m          [1;32mgrep[m           [1;36mmountpoint[m     [1;36msetpriv[m        [1;32mzdiff[m
[1;36mchmod[m          [1;32mgunzip[m         [1;36mmt[m             [1;36msetserial[m      [1;32mzegrep[m
[1;36mchown[m          [1;32mgzexe[m          [1;36mmv[m             [1;36msh[m             [1;32mzfgrep[m
[1;32mcompile_et[m     [1;32mgzip[m           [1;32mnetstat[m        [1;36msleep[m          [1;32mzforce[m
[1;36mcp[m             [1;32mhostname[m       [1;36mnice[m           [1;36mstty[m           [1;32mzgrep[m
[1;32mcpio[m           [1;36mkill[m           [1;36mnisdomainname[m  [1;36msu[m             [1;32mzless[m
[1;36mdate[m           [1;36mlink[m           [1;36mnuke[m           [1;36msync[m           [1;32mzmore[m
[1;36mdd[m             [1;36mlinux32[m        [1;36mpidof[m          [1;32mtar[m            [1;32mznew[m
[1;36mdf[m             [1;36mlinux64[m        [1;36mping[m           [1;36mtouch[m
[1;36mdmesg[m          [1;36mln[m             [1;36mpipe_progress[m  [1;36mtrue[m
[1;36mdnsdomainname[m  [1;36mlogin[m          [1;36mprintenv[m       [1;36mumount[m
# 
# python
Python 3.10.5 (main, Aug 16 2022, 11:39:44) [GCC 11.3.0] on linux
Type "help", "copyright", "credits" or "license" for more information.
>>> 138/220
0.6272727272727273
>>> 
>>> for i in range(5):
... 	print("Ohai! %d" %(  (i))
... 
Ohai! 0
Ohai! 1
Ohai! 2
Ohai! 3
Ohai! 4
>>> q 
# 
# 
# neo# neofetch [J
[?25l[?7l[38;5;8m[1m        #####
[38;5;8m[1m       #######
[38;5;8m[1m       ##[37m[0m[1mO[38;5;8m[1m#[37m[0m[1mO[38;5;8m[1m##
[38;5;8m[1m       #[0m[33m[1m#####[38;5;8m[1m#
[38;5;8m[1m     ##[37m[0m[1m##[0m[33m[1m###[37m[0m[1m##[38;5;8m[1m##
[38;5;8m[1m    #[37m[0m[1m##########[38;5;8m[1m##
[38;5;8m[1m   #[37m[0m[1m############[38;5;8m[1m##
[38;5;8m[1m   #[37m[0m[1m############[38;5;8m[1m###
[0m[33m[1m  ##[38;5;8m[1m#[37m[0m[1m###########[38;5;8m[1m##[0m[33m[1m#
[0m[33m[1m######[38;5;8m[1m#[37m[0m[1m#######[38;5;8m[1m#[0m[33m[1m######
[0m[33m[1m#######[38;5;8m[1m#[37m[0m[1m#####[38;5;8m[1m#[0m[33m[1m#######
[0m[33m[1m  #####[38;5;8m[1m#######[0m[33m[1m#####[0m
[12A[9999999D[24C[0m[1m[37m[1mroot[0m@[37m[1mppcboard[0m 
[24C[0m-------------[0m 
[24C[0m[1mOS[0m[0m:[0m Buildroot 2022.08-rc1 ppc[0m 
[24C[0m[1mHost[0m[0m:[0m 1[0m 
[24C[0m[1mKernel[0m[0m:[0m 5.10.0-00048-ga2c26294462a-dirty[0m 
[24C[0m[1mUptime[0m[0m:[0m 21 mins[0m 
[24C[0m[1mShell[0m[0m:[0m sh[0m 
[24C[0m[1mTerminal[0m[0m:[0m /dev/console[0m 
[24C[0m[1mCPU[0m[0m:[0m 604MR (1) @ 60MHz[0m 
[24C[0m[1mMemory[0m[0m:[0m 7MiB / 24MiB[0m 

[24C[30m[40m   [31m[41m   [32m[42m   [33m[43m   [34m[44m   [35m[45m   [36m[46m   [37m[47m   [m
[24C[38;5;8m[48;5;8m   [38;5;9m[48;5;9m   [38;5;10m[48;5;10m   [38;5;11m[48;5;11m   [38;5;12m[48;5;12m   [38;5;13m[48;5;13m   [38;5;14m[48;5;14m   [38;5;15m[48;5;15m   [m


# swapon /dev/mmcblk0p2
Adding 662012k swap on /dev/mmcblk0p2.  Priority:-2 extents:1 across:662012k SS
# free -m
              total        used        free      shared  buff/cache   available
Mem:             25           5           8           0          12          18
Swap:           646           0         646
# cat /proc/cpuinfo
processor	: 0
cpu		: 604MR
clock		: 60.000000MHz
revision	: 0.1 (pvr bb0a 0001)
bogomips	: 60.00

timebase	: 30000000
platform	: MR
model		: 1
vendor		: MATT
machine		: MATTRISC
Memory		: 30 MB
# 
# mkdir code
# cd code
# nano hey.s
(...stuff...)
# cat hey.s
.globl _start

_start:
	lis	8, str_hey@ha
	addi	8, 8, str_hey@l
	mr	3, 8
	bl	my_strlen
	
	mr	5, 3
	li	3, 1
	mr	4, 8
	li	0, 4
	sc

	li	0, 234
	sc

my_strlen:
	mr	4, 3
	li	3, 0
1:
	lbz	5, 0(4)
	cmpwi	5, 0
	beq	2f
	addi	4, 4, 1
	addi	3, 3, 1
	b	1b
2:
	blr

str_hey:
	.asciz "Hello world!\n"
	.align

# as hey.s -o hey.o && ld hey.o -o hey
# ./hey
Hello world!
# 
# df -h
Filesystem                Size      Used Available Use% Mounted on
/dev/root                28.6G      2.2G     24.9G   8% /
devtmpfs                 12.0M         0     12.0M   0% /dev
tmpfs                    12.4M         0     12.4M   0% /dev/shm
tmpfs                    12.4M     20.0K     12.4M   0% /tmp
tmpfs                    12.4M     24.0K     12.4M   0% /run
# lsblk
-sh: lsblk: not found
# ifconfig
lo: flags=73<UP,LOOPBACK,RUNNING>  mtu 65536
        inet 127.0.0.1  netmask 255.0.0.0
        loop  txqueuelen 1000  (Local Loopback)
        RX packets 0  bytes 0 (0.0 B)
        RX errors 0  dropped 0  overruns 0  frame 0
        TX packets 0  bytes 0 (0.0 B)
        TX errors 0  dropped 0 overruns 0  carrier 0  collisions 0

# halt -p
halt: invalid option -- p
BusyBox v1.35.0 (2022-08-16 11:51:56 BST) multi-call binary.

Usage: halt [-d DELAY] [-nfw]

Halt the system

	-d SEC	Delay interval
	-n	Do not sync
	-f	Force (don't go through init)
	-w	Only write a wtmp record
# halt
# Stopping dropbear sshd: OK
Stopping network: OK
Stopping system message bus: done
Stopping klogd: OK
Stopping syslogd: OK
umount: devtmpfs busy - remounted read-only
EXT4-fs (mmcblk0p1): re-mounted. Opts: (null)
The system is going down NOW!
Sent SIGTERM to all processes
Sent SIGKILL to all processes
Requesting system halt
reboot: System halted
System Halted, OK to turn off power
~~~


# Copyright & Licence

Unless otherwise specified in a particular file,

Copyright (c) 2020-2022 Matt Evans

The HDL is licenced under the Solderpad Hardware License v2.1.
You may obtain a copy of the License at
<https://solderpad.org/licenses/SHL-2.1/>.

Other sources are licensed under the Apache License, Version 2.0 (the "License").
You may obtain a copy of the License at
<http://www.apache.org/licenses/LICENSE-2.0>.