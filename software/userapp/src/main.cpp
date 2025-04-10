/*
 *  Copyright 2025 Sergey Khabarov, sergeykhbr@gmail.com
 *
 *  Licensed under the Apache License, Version 2.0 (the "License");
 *  you may not use this file except in compliance with the License.
 *  You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 *  Unless required by applicable law or agreed to in writing, software
 *  distributed under the License is distributed on an "AS IS" BASIS,
 *  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 *  See the License for the specific language governing permissions and
 *  limitations under the License.
 */

#include <sys/types.h>
#include <sys/stat.h>
#include <sys/mman.h>   // mmap()
#include <fcntl.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>     // strerror()
#include <errno.h>
#include <unistd.h>
#include "apptypes.h"

int main(int argc, char *argv[])
{
    FrameBufferType *fb;
    char wbuf[16];
    char rbuf[16];
    int fd = open("/dev/khbr_accel", O_RDWR);
    int sz;

    if (!fd) {
        printf("Cannot open device /dev/khbr_accel\n");
        return -1;
    }


    ((uint32_t *)wbuf)[0] = 0xcafef00d;
    ((uint32_t *)wbuf)[1] = 0xdeadbeef;
    ((uint64_t *)wbuf)[1] = 0xaaaabbbbccccddddull;
    write(fd, &wbuf[0], 4);
    write(fd, &wbuf[4], 4);
    write(fd, &wbuf[8], 8);

    sz = read(fd, &rbuf[0], 4);
    if (sz != 4) {
        fprintf(stderr, "read failed %s(%d)\n", strerror(errno), errno);
    }
    sz = read(fd, &rbuf[4], 4);
    sz = read(fd, &rbuf[8], 8);
    printf("read() rbuf[0]=%08x\n", ((uint32_t *)rbuf)[0]);
    printf("read() rbuf[1]=%08x\n", ((uint32_t *)rbuf)[1]);
    printf("read() rbuf[3]=%08x\n", ((uint32_t *)rbuf)[2]);
    printf("read() rbuf[4]=%08x\n", ((uint32_t *)rbuf)[3]);

    fb = (FrameBufferType *)mmap(NULL,                     // addr
                                 1024,  // length
                                 PROT_READ | PROT_WRITE,   // prot
                                 MAP_SHARED,               // flags
                                 fd,                       // fd
                                 0);                       // offset
    if (fb == MAP_FAILED) {
        printf("Failed mmap(): %d\n", fb);
        close(fd);
        return -1;
    }

    /**
      Basic read/write tests.
     */

    fb->ui64[0] = 0xddccbbaa44332211ull;
    fb->ui64[1] = 0x123456789abcdef0ull;
    if (fb->ui32[0] != 0x44332211) {
        printf("Wrong fb->ui32[0]=%08x\n", fb->ui32[0]);
    }
    if (fb->ui32[1] != 0xddccbbaa) {
        printf("Wrong fb->ui32[1]=%08x\n", fb->ui32[1]);
    }
    if (fb->ui64[1] != 0x123456789abcdef0ull) {
        printf("Wrong fb->ui64[1]=%016llx\n", fb->ui64[1]);
    }
    printf("mmap() tests finished\n");
    munmap(fb, sizeof(FrameBufferType));

    close(fd);
    return 0;
}