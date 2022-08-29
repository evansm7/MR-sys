/* Create Verilog $readmemh-style hex from binary
 *
 * A bit like the python one but not slow for large files...
 *
 * ME 23/12/20
 *
 * Copyright 2020 Matt Evans
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

#include <inttypes.h>
#include <stdio.h>
#include <fcntl.h>
#include <stdlib.h>
#include <sys/stat.h>
#include <sys/types.h>
#include <sys/uio.h>
#include <unistd.h>


int main(int argc, char *argv[])
{
	char *infile, *outfile;
	int ifd;
	uint32_t *indata;
	struct stat sb;
	size_t in_size;
	FILE *ofile;

	if (argc != 3) {
		printf("Syntax:  %s <infile> <outfile>\n", argv[0]);
		return 1;
	}

	outfile = argv[2];

	// Load input data:
	ifd = open(argv[1], O_RDONLY);
	if (ifd < 0) {
		perror("Input file:");
		return 1;
	}

	fstat(ifd, &sb);
	in_size = sb.st_size;

	// Allocate a size rounded up to 8B:
	in_size = (in_size + 7) & ~7;
	indata = malloc(in_size);
	if (!indata) {
		perror("Can't malloc for input file");
		return 1;
	}
	// Last dword might not be fully occupied with data from the file:
	indata[(in_size/4)-1] = 0;
	indata[(in_size/4)-2] = 0;

	if (read(ifd, indata, sb.st_size) != sb.st_size) {
		printf("Short read on input file!");
		return 1;
	}
	close(ifd);

	// Open output file:
	ofile = fopen(argv[2], "w");
	if (!ofile) {
		perror("Output file:");
		return 1;
	}

	// Finally, output data as a series of 32b words, two per line (high then low):
	for (size_t i = 0; i < in_size/4; i += 2) {
		fprintf(ofile, "%08x%08x\n", indata[i+1], indata[i+0]);
	}
	fclose(ofile);

	return 0;
}
