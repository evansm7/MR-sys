#!/usr/bin/env python3
#
# Front-end program for DebugPipe, providing peek/poke/file transfer
#
#
# 29 Nov 2020 ME
#
# Copyright 2020 Matt Evans
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

import sys
import struct
from debugpipe import DebugPipe
import getopt


################################################################################

def     padUpToWord(data):
    l = len(data) & 3
    if l > 0:
        return data + bytearray([0 for x in range(4-l)])
    else:
        return data

def     quick_test(dp):
    str = padUpToWord('This is an amazing string!')
    print(str)
    dp.write(0, str)

    rstr = dp.read(0, len(str))

    if str == rstr:
        print('Success')
    else:
        print('String mismatch: "%s" vs "%s"' % (str, rstr))


def     write_file(dp, addr, name):
    with open(name, "rb") as infile:
          fdata = infile.read()
    addr = int(addr, 0)
    waddr = addr & ~3;
    if (addr & 3) != 0:
        print("WARNING: Rounding given address 0x%x down to 0x%x" % (addr, waddr))

    l = len(fdata)
    if (l & 3) != 0:
        print("WARNING: Zero-padding data to extend to 4-byte alignment (size %d)" \
              % (l))
        fdata = fdata + bytearray([0 for x in range(4-(l & 3))])
    dp.write(waddr, fdata, verbose=True)


def     read_file(dp, addr, length, name):
    addr = int(addr, 0)
    raddr = addr & ~3;
    if (addr & 3) != 0:
        print("WARNING: Rounding given address 0x%x down to 0x%x" % (addr, raddr))

    length = int(length, 0)
    if (length & 3) != 0:
        print("WARNING: Truncating length %d to 4-byte alignment" \
              % (length))
        length &= length & ~3
    wdata = dp.read(raddr, length, verbose=True)

    with open(name, "wb") as outfile:
          outfile.write(wdata)


def     read_word(dp, addr, big_endian=False):
    addr = int(addr, 0)
    raddr = addr & ~3;
    if (addr & 3) != 0:
        print("WARNING: Rounding given address 0x%x down to 0x%x" % (addr, raddr))
    i = dp.read32(raddr, big_endian=big_endian)
    print("[%08x] => %08x" % (raddr, i))


def     write_word(dp, addr, val, big_endian=False):
    addr = int(addr, 0)
    val = int(val, 0)
    waddr = addr & ~3;
    if (addr & 3) != 0:
        print("WARNING: Rounding given address 0x%x down to 0x%x" % (addr, waddr))
    dp.write32(waddr, val, big_endian=big_endian)
    print("[%08x] <= %08x" % (waddr, val))


def     usage(s):
    print("%s [options] <command, args> \n" \
          "\tOptions: \n" \
          "\t\t-s <serial tty>                Connect using serial link via tty\n" \
          "\t\t-t <hostname>                  Connect using TCP socket to host\n" \
          "\t\t-f <url>                       Connect using FTDI url\n" \
          "\t\t-v                             Verbose debug\n" \
          "\t\t-b                             Big-endian read/write word\n" \
          "\tCommands: \n" \
          "\t\ttest                           Quick test\n" \
          "\t\tread <addr> <len> <filename>   Read file from address\n" \
          "\t\twrite <addr> <filename>        Write file to address\n" \
          "\t\trw <addr>                      Read word from address\n" \
          "\t\tww <addr> <word>               Write word to address\n" \
          % (s))

################################################################################


try:
    opts, args = getopt.getopt(sys.argv[1:], "hvbs:t:f:")
except getopt.GetoptError as err:
    usage(sys.argv[0])
    print("Invocation error: " + str(err))
    sys.exit(1)

verbose = False
conn = None
conn_arg = ""
big_endian = False

for o, a in opts:
    if o == "-h":
        usage(sys.argv[0])
        sys.exit(1)
    elif o == "-v":
        verbose = True
    elif o == "-b":
        big_endian = True
    elif o == "-s" or o == "-t" or o == "-f":
        if conn is not None:
            usage(sys.argv[0])
            print("Multiple connections specified");
            sys.exit(1)
        conn = o
        conn_arg = a


dp = None
if conn is None:
    usage(sys.argv[0])
    print("Need one of -s or -t!");
    sys.exit(1)
elif conn == "-s":
    dp = DebugPipe(tty=conn_arg, debug=verbose)
elif conn == "-t":
    dp = DebugPipe(host=conn_arg, debug=verbose)
elif conn == "-f":
    dp = DebugPipe(url=conn_arg, debug=verbose)


# Parse commands:
na = len(args)
if na == 1 and args[0] == "test":
    quick_test(dp)
elif na == 4 and args[0] == "read":
    read_file(dp, args[1], args[2], args[3])
elif na == 3 and args[0] == "write":
    write_file(dp, args[1], args[2])
elif na == 2 and args[0] == "rw":
    read_word(dp, args[1], big_endian)
elif na == 3 and args[0] == "ww":
    write_word(dp, args[1], args[2], big_endian)
else:
    usage(sys.argv[0])
    sys.exit(1)

dp.disconnect()
