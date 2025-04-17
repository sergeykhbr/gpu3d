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

class fvector2 {
 public:
    fvector2(float x, float y);
    fvector2(const float *arr);
    fvector2();
    
    // subscript operator v[0], v[1]
    float operator[](int index) const;
    // subscript operator v[0], v[1]
    float &operator[](int index);
    // v1 *= f
    fvector2 &operator*=(const float &rhs);
    // v2 = v1 * f
    fvector2 operator*(const float &rhs) const;
    // v3 = v1 + v2
    fvector2 operator+(const fvector2 &rhs) const;

 protected:
    float v_[2];
};

class fvector3 {
 public:
    fvector3(float x, float y, float z);
    fvector3(const float *arr);
    fvector3();
    
    float *getp() { return v_; }

    // subscript operator v[0], v[1]
    float operator[](int index) const;
    // subscript operator v[0], v[1]
    float &operator[](int index);
    // -v
    fvector3 operator-() const;
    // v1 - v2
    fvector3 operator-(const fvector3 &rhs) const;
    // cross-product: V1 x V2 = -V2 x V1. return is vector
    fvector3 crossProduct(const fvector3 &rhs) const;
    // return value is scalar
    float dotProduct(const fvector3 &rhs) const;
    // norm
    float norm();
    float length() { return sqrt(norm()); }
    // V / length
    fvector3 &normalize();

 protected:
    float v_[3];
};

class fvector4 {
 public:
    fvector4(float x, float y, float z, float w = 1.0f);
    fvector4(const float *arr, float w);
    fvector4();
    
    float *getp() { return v_; }

    // subscript operator v[0], v[1]
    float operator[](int index) const;
    // subscript operator v[0], v[1]
    float &operator[](int index);

 protected:
    float v_[4];
};

class fmatrix4x4 {
 public:
    fmatrix4x4();
    fmatrix4x4(const float *arr);

    float *getp() { return m_; }

    // init diagonal matrix
    void Identity();

    // subscript operator v[0], v[1]
    float operator[](int index) const;
    // subscript operator v[0], v[1]
    float &operator[](int index);
    // multiplication: v2 = M * v1
    fvector3 operator*(const fvector3 &rhs) const;
    // multiplication: v2 = M * v1
    fvector4 operator*(const fvector4 &rhs) const;
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
    ProjectionMatrix(float n,       // nearPlane
                     float f,       // farPlane
                     float fov_y = 60.0f,
                     float ratio = 640.0f/480.0f) : fmatrix4x4() {

        // set perspective viewing frustum
        float tangent = tanf(fov_y/2 * DEG_TO_RAD);         // tangent of half fovY
        float t = n * tangent;                      // top
        float b = -t;                                       // bottom
        float r = t * ratio;                                // right
        float l = -r;                                       // left

        m_[0]  =  2 * n / (r - l);
        m_[2]  =  (r + l) / (r - l);
        m_[5]  =  2 * n / (t - b);
        m_[6]  =  (t + b) / (t - b);
        m_[10] = -(f + n) / (f - n);
        m_[11] = -(2 * f * n) / (f - n);
        m_[14] = -1;
        m_[15] =  0;
    }

};

/*
 Row majority
 0  1  2  3    cos_b*cos_y    sin_a*sin_b*cos_y-cos_a*sin_y   cos_a*sin_b*cos_y+sin_a*sin_y   0
 4  5  6  7    cos_b*sin_y    sin_a*sin_b*sin_y+cos_a*cos_y   cos_a*sin_b*sin_y-sin_a*cos_y   0
 8  9  10 11      -sin_b                sin_a*cos_b                    cos_a*cos_b            0
 12 13 14 15        0                       0                             0                   1
 */
class RotationMatrix : public fmatrix4x4 {
 public:
    RotationMatrix(float deg_x, float deg_y, float deg_z) : fmatrix4x4() {
        float cx = 1.0f, sx = 0.0f;
        float cy = 1.0f, sy = 0.0f;
        float cz = 1.0f, sz = 0.0f;
        Identity();

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
        m_[1] = cy * -sz;  // 1
        m_[2] = sy;        // 2

        m_[4] = -sx * -sy * cz + cx * sz;  // 4
        m_[5] = -sx * -sy * -sz + cx * cz; // 5
        m_[6] = -sx * cy;                  // 6

        m_[8] = cx * -sy * cz + sx * sz;   // 8
        m_[9] = cx * -sy * -sz + sx * cz;  // 9
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
    //  0  1  2  3
    //  4  5  6  7
    //  8  9 10 11
    // 12 13 14 15
    ViewMatrix(const float *arr) : RotationMatrix(0, 0, 0) {
        m_[0] = arr[0];
        m_[4] = arr[1];
        m_[8] = arr[2];
        m_[12] = arr[3];

        m_[1] = arr[4];
        m_[5] = arr[5];
        m_[9] = arr[6];
        m_[13] = arr[7];

        m_[2] = arr[8];
        m_[6] = arr[9];
        m_[10] = arr[10];
        m_[14] = arr[11];

        m_[3] = arr[12];
        m_[7] = arr[13];
        m_[11] = arr[14];
        m_[15] = arr[15];
    }
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
