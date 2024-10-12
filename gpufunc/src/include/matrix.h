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

// GPU use column majority
//   M * v (row majority) == v * M (column majority)
#pragma once

#include <memory.h>
#include <math.h>


static const float DEG_TO_RAD = float(3.14159265358979323846/180.0);

class fmatrix4x4 {
 public:
    fmatrix4x4();

    float *getp() { return m_; }

    // init diagonal matrix
    void Identity();

    // subscript operator v[0], v[1]
    float operator[](int index) const;
    // subscript operator v[0], v[1]
    float &operator[](int index);
    // multiplication: M3 = M1 * M2
    fmatrix4x4 operator*(const fmatrix4x4 &rhs) const;
    // multiplication: M1' = M1 * M2
    fmatrix4x4 &operator*=(const fmatrix4x4& rhs);

 protected:
    float m_[16];
};


/*  Row majority   Col majority          ROW MAJORITY
     0  1  2  3    0  4  8  12      2n/(r-l)     0      (r+l)/(r-l)     0
     4  5  6  7    1  5  9  13        0       2n/(t-b)  (t+b)/(t-b)     0
     8  9  10 11   2  6  10 14        0          0     -(f+n)/(f-n) -2fn/(f-n)
     12 13 14 15   3  7  11 15        0          0          -1          0
 */
class ProjectionMatrix : public fmatrix4x4 {
 public:
    ProjectionMatrix(float nearPlane,
                     float farPlane,
                     int width,
                     int height,
                     float fov_y = 60.0f) : fmatrix4x4() {

        // set perspective viewing frustum
        float tangent = tanf(fov_y/2 * DEG_TO_RAD);         // tangent of half fovY
        float h = nearPlane * tangent;                      // half height of near plane
        float w = h * static_cast<float>(width)/height;     // half width of near plane

        m_[0]  =  2 * nearPlane / (w - (-w));
        m_[8]  =  (w + (-w)) / (w - (-w));                              // 2 row majority
        m_[5]  =  2 * nearPlane / (h - (-h));
        m_[9]  =  (h + (-h)) / (h - (-h));                              // 6 row majority
        m_[10] = -(farPlane + nearPlane) / (farPlane - nearPlane);
        m_[14] = -(2 * farPlane * nearPlane) / (farPlane - nearPlane);  // 11 row majority
        m_[11] = -1;                                                    // 14 row majority
        m_[15] =  0;
    }

};

/*
 Row majority
 0  1  2  3    cos_b*cos_y    sin_a*sin_b*cos_y-cos_a*sin_y   cos_a*sin_b*cos_y+sin_a*sin_y   0
 4  5  6  7    cos_b*sin_y    sin_a*sin_b*sin_y+cos_a*cos_y   cos_a*sin_b*sin_y-sin_a*cos_y   0
 8  9  10 11      -sin_b                sin_a*cos_b                    cos_a*cos_b            0
 12 13 14 15        0                       0                             0                   1

 RotationMatrix in column majority:
 */
class RotationMatrix : public fmatrix4x4 {
 public:
    RotationMatrix(float deg_x, float deg_y, float deg_z) : fmatrix4x4() {
        float cx = 1.0f, sx = 0.0f;
        float cy = 1.0f, sy = 0.0f;
        float cz = 1.0f, sz = 0.0f;
        m_[0] = 1.0f;
        m_[5] = 1.0f;
        m_[10] = 1.0f;
        m_[15] = 1.0f;

        if (deg_x) {
            cx = static_cast<float>(cos(deg_x * DEG_TO_RAD));
            sx = static_cast<float>(sin(deg_x * DEG_TO_RAD));
        }
        if (deg_y) {
            cy = static_cast<float>(cos(deg_y * DEG_TO_RAD));
            sy = static_cast<float>(sin(deg_y * DEG_TO_RAD));
        }
        if (deg_z) {
            cz = static_cast<float>(cos(deg_z * DEG_TO_RAD));
            sz = static_cast<float>(sin(deg_z * DEG_TO_RAD));
        }

        m_[0] = cy * cz;   // 0
        m_[4] = cy * -sz;  // 1
        m_[8] = sy;        // 2

        m_[1] = -sx * -sy * cz + cx * sz;  // 4
        m_[5] = -sx * -sy * -sz + cx * cz; // 5
        m_[9] = -sx * cy;                  // 6

        m_[2] = cx * -sy * cz + sx * sz;   // 8
        m_[6] = cx * -sy * -sz + sx * cz;  // 9
        m_[10] = cx * cy;                  // 10

        m_[15] = 1.0f;
     }
};

// Translate to point
class TranslationMatrix : public fmatrix4x4 {
 public:
    TranslationMatrix(float x, float y, float z) : fmatrix4x4() {
        Identity();
        m_[3] = x;
        m_[7] = y;
        m_[11] = z;
    }
};

// Transform verticies relative viewer point
class ViewMatrix : public RotationMatrix {
 public:
    ViewMatrix(float x,
               float y,
               float z,
               float deg_x,
               float deg_y,
               float deg_z) : RotationMatrix(deg_x, deg_y, deg_z) {
        TranslationMatrix Mov(x, y, z);
        *this *= Mov;   
    }
};
