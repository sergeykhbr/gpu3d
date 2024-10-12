/*
 *  Copyright 2024 Sergey Khabarov, sergeykhbr@gmail.com
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
#include "matrix.h"

fmatrix4x4::fmatrix4x4() {
    memset(m_, 0, sizeof(m_));
}

void fmatrix4x4::Identity() {
    memset(m_, 0, sizeof(m_)); 
    m_[0] = 1.0f;
    m_[5] = 1.0f;
    m_[10] = 1.0f;
    m_[15] = 1.0f; 
}

// subscript operator v[0], v[1]
float fmatrix4x4::operator[](int index) const {
    return m_[index];
}

// subscript operator v[0], v[1]
float &fmatrix4x4::operator[](int index) {
    return m_[index];
}


// multiplication: M3 = M1 * M2
fmatrix4x4 fmatrix4x4::operator*(const fmatrix4x4 &rhs) const {
    fmatrix4x4 ret;
    float *A = ret.getp();
    float t1[16];
    t1[0] = A[0]*rhs[0]  + A[4]*rhs[1]  + A[8]*rhs[2]  + A[12]*rhs[3];
    t1[1] = A[0]*rhs[4]  + A[4]*rhs[5]  + A[8]*rhs[6]  + A[12]*rhs[7];
    t1[2] = A[0]*rhs[8]  + A[4]*rhs[9]  + A[8]*rhs[10] + A[12]*rhs[11];
    t1[3] = A[0]*rhs[12] + A[4]*rhs[13] + A[8]*rhs[14] + A[12]*rhs[15];

    t1[4] = A[1]*rhs[0] + A[5]*rhs[1] + A[9]*rhs[2] + A[13]*rhs[3];
    t1[5] = A[1]*rhs[4] + A[5]*rhs[5] + A[9]*rhs[6] + A[13]*rhs[7];
    t1[6] = A[1]*rhs[8] + A[5]*rhs[9] + A[9]*rhs[10] + A[13]*rhs[11];
    t1[7] = A[1]*rhs[12] + A[5]*rhs[13] + A[9]*rhs[14] + A[13]*rhs[15];

    t1[8] = A[2]*rhs[0] + A[6]*rhs[1] + A[10]*rhs[2] + A[14]*rhs[3];
    t1[9] = A[2]*rhs[4] + A[6]*rhs[5] + A[10]*rhs[6] + A[14]*rhs[7];
    t1[10] = A[2]*rhs[8] + A[6]*rhs[9] + A[10]*rhs[10] + A[14]*rhs[11];
    t1[11] = A[2]*rhs[12] + A[6]*rhs[13] + A[10]*rhs[14] + A[14]*rhs[15];

    t1[12] = A[3]*rhs[0] + A[7]*rhs[1] + A[11]*rhs[2] + A[15]*rhs[3];
    t1[13] = A[3]*rhs[4] + A[7]*rhs[5] + A[11]*rhs[6] + A[15]*rhs[7];
    t1[14] = A[3]*rhs[8] + A[7]*rhs[9] + A[11]*rhs[10] + A[15]*rhs[11];
    t1[15] = A[3]*rhs[12] + A[7]*rhs[13] + A[11]*rhs[14] + A[15]*rhs[15];
    memcpy(ret.getp(), t1, sizeof(m_));
    return ret;
}

// multiplication: M1' = M1 * M2
fmatrix4x4 &fmatrix4x4::operator*=(const fmatrix4x4& rhs) {
    *this = *this * rhs;
    return *this;
}
