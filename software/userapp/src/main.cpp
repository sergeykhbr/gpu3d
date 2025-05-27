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
    char wbuf[16];
    char rbuf[16];
    int fdev = open("/dev/khbr_accel", O_RDWR);
    FrameBufferType *fbuf;
    int sz;
    int errcnt;
    int TotalCnt = 1000;

    if (!fdev) {
        printf("Cannot open device /dev/khbr_accel\n");
        return -1;
    }
#if 1
    errcnt = 0;
    printf("Start PCIE read/write torture %d tests.\n", TotalCnt);
    for (int i = 0; i < TotalCnt; i++) {
        lseek(fdev, 0, SEEK_SET);
        ((uint32_t *)wbuf)[0] = 0xcafef00d + i;
        ((uint32_t *)wbuf)[1] = 0xdeadbeef + i;
        ((uint64_t *)wbuf)[1] = 0xaaaabbbbccccddddull + i;
        sz = write(fdev, &wbuf[0], 4);
        if (sz != 4) {
            fprintf(stderr, "write[0] failed %s(%d)\n", strerror(errno), errno);
            break;
        }

        sz = write(fdev, &wbuf[4], 12);
        if (sz != 12) {
            fprintf(stderr, "write[4] failed %s(%d)\n", strerror(errno), errno);
            break;
        }

        lseek(fdev, 0, SEEK_SET);
        sz = read(fdev, &rbuf[0], 4);
        if (sz != 4) {
            fprintf(stderr, "read[0] failed %s(%d)\n", strerror(errno), errno);
            break;
        } else if (((uint32_t *)rbuf)[0] != (0xcafef00d + i)) {
            printf("error read() rbuf[0]=%08x\n", ((uint32_t *)rbuf)[0]);
            errcnt++;
        }

        sz = read(fdev, &rbuf[4], 12);
        if (sz != 12) {
            fprintf(stderr, "read[4] failed %s(%d)\n", strerror(errno), errno);
            break;
        } else if (((uint32_t *)rbuf)[1] != (0xdeadbeef + i)) {
            printf("error read() rbuf[1]=%08x\n", ((uint32_t *)rbuf)[1]);
            errcnt++;
        }

        if (((uint64_t *)rbuf)[1] != (0xaaaabbbbccccddddull + i)) {
            printf("error read() rbuf[3]=%08x\n", ((uint32_t *)rbuf)[2]);
            printf("error read() rbuf[4]=%08x\n", ((uint32_t *)rbuf)[3]);
            errcnt++;
        }

        if ((i % (TotalCnt / 10)) == (TotalCnt / 10 - 1)) {
            printf("%i testes passed. Error: %d\n", i + 1, errcnt);
        }
    }
#endif

    printf("Start PCIE mmap tests.\n");
    fbuf = (FrameBufferType *)mmap(NULL,                     // addr
                                 2*1024*1024,  // length
                                 PROT_READ | PROT_WRITE,   // prot
                                 MAP_SHARED,               // flags
                                 fdev,                     // fd
                                 0);                       // offset
    if (fbuf == MAP_FAILED) {
        printf("Failed mmap(): %d\n", fbuf);
        close(fdev);
        return -1;
    } else {
        printf("mmap() success\n");
    }

#if 1
    /**
      Basic read/write tests.
     */
    int offset = 0x1000;
    fbuf->ui32[offset + 0] = 0x44332211;
    fbuf->ui32[offset + 1] = 0xddccbbaa;
    fbuf->ui64[offset/2 + 1] = 0xccccccccddddddddull;

    if (fbuf->ui32[offset + 0] != 0x44332211) {
        printf("Wrong fb->ui32[0]=%08x\n", fbuf->ui32[offset + 0]);
    }
    if (fbuf->ui32[offset + 1] != 0xddccbbaa) {
        printf("Wrong fb->ui32[1]=%08x\n", fbuf->ui32[offset + 1]);
    }
    if (fbuf->ui64[offset/2 + 1] != 0xccccccccddddddddull) {
        printf("Wrong fb->ui64[1]=%016llx\n", fbuf->ui64[offset/2 + 1]);
    }
    for (int i = 0; i < 8; i++) {
        printf("fb->ui32[%d]=%08x\n", i, fbuf->ui32[offset + i]);
    }
    for (int i = 0; i < 4; i++) {
        printf("fb->ui64[%d]=%016lx\n", i, fbuf->ui64[offset/2 + i]);
    }
 
    printf("mmap(): check memcpy\n");
    char tbuf[1024];
    for (int i = 0; i < 1024; i++) {
        tbuf[i] = (char)(i);
    }
    memcpy(&fbuf->i8[offset], tbuf, 1024);
    for (int i = 0; i < 1024/8; i++) {
        printf("fb->ui64[%d]=%016lx\n", i, fbuf->ui64[offset/8 + i]);
    }

#endif
    printf("mmap() tests finished\n");
    munmap(fbuf, FRAME_BUFFER_SIZE);
    close(fdev);
    return 0;
}