#!/usr/bin/env python3
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

import struct
import sys
import socket
import serial

class DebugPipe:
    'Wraps a debug connection via serial or TCP, providing read/write actions'

    # Constants
    MAX_XFER_SIZE = (255*4)  # Must be /4
    CMD_READ = 2
    CMD_WRITE = 1
    CMD_WRITE_ACK = 3

    # Internal classes
    class DebugConduitTCP:
        'Conduit for a TCP connection'
        def __init__(self):
            self.s = None

        # Maybe just connect in constructor?
        def connect(self, host, port, verbose=False):
            self.s = s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
            if verbose:
                print("Connecting to %s:%d" % (host, port))
            try:
                s.connect((host, port))
            except Exception as e:
                print(e)
                return False
            return True

        def disconnect(self):
            self.s.close()

        def read(self, length):
            return self.s.recv(length, socket.MSG_WAITALL)

        def write(self, bytes):
            self.s.sendall(bytes)

    class DebugConduitSerial:
        'Conduit for a serial connection'
        def __init__(self):
            self.s = None

        def connect(self, tty):
            try:
                self.s = serial.Serial(tty, 115200)
            except Exception as e:
                print(e)
                return False
            return True

        def disconnect(self):
            self.s.close()

        def read(self, length):
            return self.s.read(length)

        def write(self, bytes):
            self.s.write(bytes)

    class DebugConduitFTDI:
        'Conduit for an FTDI connection'
        # This is better than serial for, e.g. a FT232H in
        # '245 mode because it controls the read latency timer,
        # which will give better performance on write-to-read
        # turnaround (or small reads).
        # (Except... it seems slower for reads than serial :( )
        def __init__(self):
            self.s = None

        def connect(self, url):
            try:
                from pyftdi.ftdi import Ftdi
            except ImportError:
                raise ImportError("PyFTDI module not installed")

            self.s = Ftdi()
            try:
                self.s.open_from_url(url)
            except Exception as e:
                print(e)
                return False
            self.s.set_dynamic_latency(lmin=12, lmax=255, threshold=10)
#            self.s.set_latency_timer(12)
            return True

        def disconnect(self):
            self.s.close()

        def read(self, length):
            return self.s.read_data(length)

        def write(self, bytes):
            self.s.write_data(bytes)

    def __init__(self, tty=None, host=None, port=2001, url=None, debug=False):
        self.conduit = None
        self.debug = debug
        if tty is not None:
            c = self.DebugConduitSerial()
            c.connect(tty)
        elif host is not None:
            c = self.DebugConduitTCP()
            if not c.connect(host, port):
                raise Exception("Connection failed")
                c = None
        elif url is not None:
            c = self.DebugConduitFTDI()
            c.connect(url)
        else:
            raise "Must construct with either tty or host"
        self.conduit = c

    def read(self, address, length, verbose=False):
        assert self.conduit, "Missing conduit"
        # Word-addressed, align if necessary
        assert ((address & 3) == 0 and ((length & 3) == 0)), \
                "Address (0x%x) & length (0x%x) must be word-aligned!" % (address, length)

        # We can read 255 words max, but we limit each request to MAX_XFER_SIZE.
        # So, repeat a few times until we've covered length:
        data = bytes()

        if verbose:
            # Try to print with some evenness, e.g. roughly 10 lines per transfer
            print_rate = length/10
            print_next = 0
        done = 0
        total = length

        while length > 0:
            l = self.MAX_XFER_SIZE if length > self.MAX_XFER_SIZE else length
            whdr = struct.pack('<BBI', self.CMD_READ, int(l / 4), address)
            if self.debug:
                print("R:Wdata: " + str(list(whdr)))
            self.conduit.write(whdr)

            rdata = self.conduit.read(l)
            if self.debug:
                print("R:Rdata: %s (%d)" % (str(list(rdata)), len(rdata)))

            if verbose and done > print_next:
                print("Read: %.f%% (%d/%d)" % ((100.0 * done/total), done, total))
                print_next = done + print_rate
            data += rdata
            address += l
            length -= l
            done += l

        return data

    def read32(self, address, big_endian=False):
        assert ((address & 3) == 0), \
                "Address (0x%x) must be word-aligned!" % (address)
        d = self.read(address, 4)
        (i,) = struct.unpack('>I' if big_endian else '<I', d)
        return i

    def write(self, address, data, verbose=False, sync=False):
        assert self.conduit, "Missing conduit"
        length = len(data)
        data = bytes(data)
        assert ((address & 3) == 0 and ((length & 3) == 0)), \
                "Address (0x%x) & length (0x%x) must be word-aligned!" % (address, length)

        if verbose:
            # Try to print with some evenness, e.g. roughly 10 lines per transfer
            print_rate = length/10
            print_next = 0
        done = 0

        # Similar to read, break into MAX_XFER_SIZE transfers:
        while len(data) > 0:
            l = self.MAX_XFER_SIZE if len(data) > self.MAX_XFER_SIZE else len(data)
            if len(data) <= l:
                # This is the last chunk
                cmd = self.CMD_WRITE_ACK
                sync = True
            else:
                # The sync parameter forces all writes in a transfer to be sync,
                # or just the last one.
                cmd = self.CMD_WRITE_ACK if sync else self.CMD_WRITE
            whdr = struct.pack('<BBI', cmd, int(l / 4), address)
            if self.debug:
                print("W:Hdr: " + str(list(whdr)))
            self.conduit.write(whdr)

            dslice = data[:l]
            if self.debug:
                print("W:Wdata: %s (%d)" % (str(list(dslice)), l))
            self.conduit.write(dslice)
            if sync:
                # Wait for ACK:
                rdata = self.conduit.read(1)
                if self.debug:
                    print("R:Rdata: %s (%d)" % (str(list(rdata)), len(rdata)))
                assert (int(rdata[0]) == 0xaa), "Weird ACK 0x%x!" % (ord(rdata[0]))

            if verbose and done > print_next:
                print("Write: %.f%%\t(%d/%d)" % ((100.0 * done/length), done, length))
                print_next = done + print_rate
            data = data[l:]
            address += l
            done += l

        if verbose:
            print("Done")

    def write32(self, address, data, big_endian=False):
        assert ((address & 3) == 0), \
                "Address (0x%x) must be word-aligned!" % (address)
        self.write(address, struct.pack('>I' if big_endian else '<I', data))

    def disconnect(self):
        if self.conduit is not None:
            self.conduit.disconnect()

if __name__ == "__main__":
    print("Don't run this directly, import it into another program.")
