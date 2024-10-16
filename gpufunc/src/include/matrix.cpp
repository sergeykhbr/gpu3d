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

fvector3::fvector3(float x, float y, float z) {
    v_[0] = x;
    v_[1] = y;
    v_[2] = z;
}

fvector3::fvector3() : fvector3(0, 0, 0) {
}

// subscript operator v[0], v[1]
float fvector3::operator[](int index) const {
    return v_[index];
}

// subscript operator v[0], v[1]
float &fvector3::operator[](int index) {
    return v_[index];
}


fvector4::fvector4(float x, float y, float z, float w) {
    v_[0] = x;
    v_[1] = y;
    v_[2] = z;
    v_[3] = w;
}

fvector4::fvector4() : fvector4(0, 0, 0, 1.0f) {
}

// subscript operator v[0], v[1]
float fvector4::operator[](int index) const {
    return v_[index];
}

// subscript operator v[0], v[1]
float &fvector4::operator[](int index) {
    return v_[index];
}




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

// multiplication: v2 = M * v1
fvector3 fmatrix4x4::operator*(const fvector3 &rhs) const {
    fvector3 ret;
    float t1[3];
#if 1
    t1[0] = m_[0]*rhs[0] + m_[1]*rhs[1] + m_[2]*rhs[2] + m_[3];
    t1[1] = m_[4]*rhs[0] + m_[5]*rhs[1] + m_[5]*rhs[2] + m_[7];
    t1[2] = m_[8]*rhs[0] + m_[9]*rhs[1] + m_[10]*rhs[2] + m_[11];
#else
    t1[0] = m_[0]*rhs[0] + m_[4]*rhs[1] + m_[8]*rhs[2] + m_[12];
    t1[1] = m_[1]*rhs[0] + m_[5]*rhs[1] + m_[9]*rhs[2] + m_[13];
    t1[2] = m_[2]*rhs[0] + m_[6]*rhs[1] + m_[10]*rhs[2] + m_[14];
#endif
    memcpy(ret.getp(), t1, sizeof(t1));
    return ret;
}

// multiplication: v2 = M * v1
fvector4 fmatrix4x4::operator*(const fvector4 &rhs) const {
    fvector4 ret;
    float t1[4];
#if 1
    t1[0] = m_[0]*rhs[0] + m_[1]*rhs[1] + m_[2]*rhs[2] + m_[3]*rhs[3];
    t1[1] = m_[4]*rhs[0] + m_[5]*rhs[1] + m_[6]*rhs[2] + m_[7]*rhs[3];
    t1[2] = m_[8]*rhs[0] + m_[9]*rhs[1] + m_[10]*rhs[2] + m_[11]*rhs[3];
    t1[3] = m_[12]*rhs[0] + m_[13]*rhs[1] + m_[14]*rhs[2] + m_[15]*rhs[3];
#else
    t1[0] = m_[0]*rhs[0] + m_[4]*rhs[1] + m_[8]*rhs[2] + m_[12]*rhs[3];
    t1[1] = m_[1]*rhs[0] + m_[5]*rhs[1] + m_[9]*rhs[2] + m_[13]*rhs[3];
    t1[2] = m_[2]*rhs[0] + m_[6]*rhs[1] + m_[10]*rhs[2] + m_[14]*rhs[3];
    t1[3] = m_[3]*rhs[0] + m_[7]*rhs[1] + m_[11]*rhs[2] + m_[15]*rhs[3];
#endif
    memcpy(ret.getp(), t1, sizeof(t1));
    return ret;
}


// multiplication: M3 = M1 * M2
//  0  1  2  3     0  1  2  3
//  4  5  6  7     4  5  6  7
//  8  9  10 11    8  9 10 11
//  12 13 14 15   12 13 14 15
fmatrix4x4 fmatrix4x4::operator*(const fmatrix4x4 &rhs) const {
    fmatrix4x4 ret;
    float t1[16];
#if 1
    t1[0] = m_[0]*rhs[0]  + m_[1]*rhs[4]  + m_[2]*rhs[8]  + m_[3]*rhs[12];
    t1[1] = m_[0]*rhs[1]  + m_[1]*rhs[5]  + m_[2]*rhs[9]  + m_[3]*rhs[13];
    t1[2] = m_[0]*rhs[2]  + m_[1]*rhs[6]  + m_[2]*rhs[10] + m_[3]*rhs[14];
    t1[3] = m_[0]*rhs[3]  + m_[1]*rhs[7]  + m_[2]*rhs[11] + m_[3]*rhs[15];

    t1[4] = m_[4]*rhs[0]  + m_[5]*rhs[4]  + m_[6]*rhs[8]  + m_[7]*rhs[12];
    t1[5] = m_[4]*rhs[1]  + m_[5]*rhs[5]  + m_[6]*rhs[9]  + m_[7]*rhs[13];
    t1[6] = m_[4]*rhs[2]  + m_[5]*rhs[6]  + m_[6]*rhs[10] + m_[7]*rhs[14];
    t1[7] = m_[4]*rhs[3]  + m_[5]*rhs[7]  + m_[6]*rhs[11] + m_[7]*rhs[15];

    t1[8] = m_[8]*rhs[0]  + m_[9]*rhs[4]  + m_[10]*rhs[8]  + m_[11]*rhs[12];
    t1[9] = m_[8]*rhs[1]  + m_[9]*rhs[5]  + m_[10]*rhs[9]  + m_[11]*rhs[13];
    t1[10] = m_[8]*rhs[2]  + m_[9]*rhs[6]  + m_[10]*rhs[10] + m_[11]*rhs[14];
    t1[11] = m_[8]*rhs[3]  + m_[9]*rhs[7]  + m_[10]*rhs[11] + m_[11]*rhs[15];

    t1[12] = m_[12]*rhs[0]  + m_[13]*rhs[4]  + m_[14]*rhs[8]  + m_[15]*rhs[12];
    t1[13] = m_[12]*rhs[1]  + m_[13]*rhs[5]  + m_[14]*rhs[9]  + m_[15]*rhs[13];
    t1[14] = m_[12]*rhs[2]  + m_[13]*rhs[6]  + m_[14]*rhs[10] + m_[15]*rhs[14];
    t1[15] = m_[12]*rhs[3]  + m_[13]*rhs[7]  + m_[14]*rhs[11] + m_[15]*rhs[15];
#else
    t1[0] = m_[0]*rhs[0]  + m_[4]*rhs[1]  + m_[8]*rhs[2]  + m_[12]*rhs[3];
    t1[1] = m_[0]*rhs[4]  + m_[4]*rhs[5]  + m_[8]*rhs[6]  + m_[12]*rhs[7];
    t1[2] = m_[0]*rhs[8]  + m_[4]*rhs[9]  + m_[8]*rhs[10] + m_[12]*rhs[11];
    t1[3] = m_[0]*rhs[12] + m_[4]*rhs[13] + m_[8]*rhs[14] + m_[12]*rhs[15];

    t1[4] = m_[1]*rhs[0] + m_[5]*rhs[1] + m_[9]*rhs[2] + m_[13]*rhs[3];
    t1[5] = m_[1]*rhs[4] + m_[5]*rhs[5] + m_[9]*rhs[6] + m_[13]*rhs[7];
    t1[6] = m_[1]*rhs[8] + m_[5]*rhs[9] + m_[9]*rhs[10] + m_[13]*rhs[11];
    t1[7] = m_[1]*rhs[12] + m_[5]*rhs[13] + m_[9]*rhs[14] + m_[13]*rhs[15];

    t1[8] = m_[2]*rhs[0] + m_[6]*rhs[1] + m_[10]*rhs[2] + m_[14]*rhs[3];
    t1[9] = m_[2]*rhs[4] + m_[6]*rhs[5] + m_[10]*rhs[6] + m_[14]*rhs[7];
    t1[10] = m_[2]*rhs[8] + m_[6]*rhs[9] + m_[10]*rhs[10] + m_[14]*rhs[11];
    t1[11] = m_[2]*rhs[12] + m_[6]*rhs[13] + m_[10]*rhs[14] + m_[14]*rhs[15];

    t1[12] = m_[3]*rhs[0] + m_[7]*rhs[1] + m_[11]*rhs[2] + m_[15]*rhs[3];
    t1[13] = m_[3]*rhs[4] + m_[7]*rhs[5] + m_[11]*rhs[6] + m_[15]*rhs[7];
    t1[14] = m_[3]*rhs[8] + m_[7]*rhs[9] + m_[11]*rhs[10] + m_[15]*rhs[11];
    t1[15] = m_[3]*rhs[12] + m_[7]*rhs[13] + m_[11]*rhs[14] + m_[15]*rhs[15];
#endif
    memcpy(ret.getp(), t1, sizeof(t1));
    return ret;
}

// multiplication: M1' = M1 * M2
fmatrix4x4 &fmatrix4x4::operator*=(const fmatrix4x4& rhs) {
    *this = *this * rhs;
    return *this;
}
