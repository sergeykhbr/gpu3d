/*
 *  Copyright 2023 Sergey Khabarov, sergeykhbr@gmail.com
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

#include "sv_func.h"
#include "api_core.h"

namespace debugger {

/** Read HEX-file using relaitve RTL simulation project path */
void SV_readmemh(const char *filename, sc_uint<32> *mem) {
    char tpath[4096];
    uint32_t word;
    FILE *f;
    char buf;
    int cnt = 0;
    int addr = 0;
    snprintf(tpath, sizeof(tpath), CMAKE_CURRENT_SOURCE_DIR"/prj/impl/%s", filename);
    f = fopen(tpath, "rb");

    if (!f) {
        printf("Cannot open file %s", filename);
        return;
    }

    while (fread(&buf, 1, 1, f) > 0) {
        if (buf >= '0' && buf <= '9') {
            word = (word << 4) | static_cast<uint8_t>(buf - '0');
            cnt++;
        } else if (buf >= 'a' && buf <= 'f') {
            word = (word << 4) | (10 + static_cast<uint8_t>(buf - 'a'));
            cnt++;
        } else if (buf >= 'A' && buf <= 'F') {
            word = (word << 4) | (10 + static_cast<uint8_t>(buf - 'A'));
            cnt++;
        } else {
            if (cnt) {
                mem[addr++] = word;
            }
            word = 0;
            cnt = 0;
        }
    }

    fclose(f);
}

void SV_display(const char *str) {
    std::cout << str;
}

} // namespace debugger
