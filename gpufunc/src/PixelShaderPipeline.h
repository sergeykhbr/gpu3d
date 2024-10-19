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

#pragma once

#include <QtWidgets/QWidget>
#include <QtGui/qevent.h>
#include <matrix.h>

class PixelShaderPipeline : public QWidget {
    Q_OBJECT

 public:
    PixelShaderPipeline(QWidget *parent,
                        int width,
                        int height,
                        float near,
                        float far);
    virtual ~PixelShaderPipeline();

    void setProjectionMatrix(fmatrix4x4 *p) { P_ = *p; }

 public slots:
    void slotVertexData(const float *camera, int vsz,
                        const float *uv, int uvsz,
                        unsigned *tri,
                        unsigned *uvtri,
                        float *normal,
                        int tsz);

 signals:
    void signalFrameData(uchar *frame);
    void signalZbufferData(float *zbuffer);

 protected:
    struct ProjectionVertexData {
        fvector2 xy;        // float pixel coordinate (todo: name it better)
        fvector2 uv;        // uv_vector * (1/z)
        float fz;
        bool visible;
        int w, h;
    };
    struct Point2D {
        int x, y;
    };
    struct FPoint2D {
        float x, y;
        FPoint2D() : x(0), y(0) {}
        FPoint2D(float v1, float v2) : x(v1), y(v2) {}
        FPoint2D(const float *adr) : x(adr[0]), y(adr[1]) {}
    };
    struct FPoint3D {
        float x, y, z;
        explicit FPoint3D(const Point2D &p) {
            x = static_cast<int>(p.x);
            y = static_cast<int>(p.y);
            z = 0;
        }
        FPoint3D(float p1, float p2, float p3) : x(p1), y(p2), z(p3) {}
    };
    struct FPointBaricentric {
        float l0, l1, l2;
    };

   /**
      Not-optimized basic rasterizer:
        https://fgiesen.wordpress.com/2013/02/08/triangle-rasterization-in-practice/
     */
    void rasterizeTriangleNoOptimization(const fvector3 &cam0,
                                        const fvector3 &cam1,
                                        const fvector3 &cam2,
                                        const ProjectionVertexData &prj0,
                                        const ProjectionVertexData &prj1,
                                        const ProjectionVertexData &prj2,
                                        const fvector3 &norm);
    // return >= 0 if inside of trianlge or on the edge
    int baricentricPoint(float area,
                         const fvector2 &v0,
                         const fvector2 &v1,
                         const fvector2 &v2,
                         const fvector2 &c,
                         FPointBaricentric *w);
    void drawTri(const FPoint3D &v0, const FPoint3D &v1, const FPoint3D &v2);
    float orient2d(const fvector2 &a, const fvector2 &b, const fvector2 &c);
    uint renderPixel(const Point2D &c, FPointBaricentric &w);
    float getZBuffer(float z0, float z1, float z2, FPointBaricentric &w);
    int min3(float v1, float v2, float v3);
    int max3(float v1, float v2, float v3);
    int min(int v1, int v2);
    int max(int v1, int v2);

 protected:
    int width_;
    int height_;
    float near_;
    float far_;
    fmatrix4x4 P_;
    ProjectionVertexData projection_[8*1024];
    uint *frame_;
    float *zbuffer_;
};



