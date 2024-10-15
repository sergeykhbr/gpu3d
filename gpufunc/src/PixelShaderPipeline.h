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

class PixelShaderPipeline : public QWidget {
    Q_OBJECT

 public:
    PixelShaderPipeline(QWidget *parent,
                        int width,
                        int height,
                        float distance_);
    virtual ~PixelShaderPipeline();

 public slots:
    void slotVertexData(float *m, int size);

 signals:
    void signalFrameData(uchar *frame);
    void signalZbufferData(uchar *zbuffer);

 protected:
    struct Point2D {
        int x, y;
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

    bool isCounterClockWiseTriangle(const FPoint3D &v0,
                                    const FPoint3D &v1,
                                    const FPoint3D &v2);
    /**
      Not-optimized basic rasterizer:
        https://fgiesen.wordpress.com/2013/02/08/triangle-rasterization-in-practice/
     */
    void rasterizeTriangleNoOptimization(const FPoint3D &v0,
                                         const FPoint3D &v1,
                                         const FPoint3D &v2);
    // return >= 0 if inside of trianlge or on the edge
    int baricentricPoint(float area,
                         const FPoint3D &v0,
                         const FPoint3D &v1,
                         const FPoint3D &v2,
                         Point2D c,
                         FPointBaricentric *w);
    void drawTri(const FPoint3D &v0, const FPoint3D &v1, const FPoint3D &v2);
    float orient2d(const FPoint3D a, const FPoint3D b, const FPoint3D c);
    uint renderPixel(const Point2D &c, FPointBaricentric &w);
    uchar getZBuffer(float z0, float z1, float z2, FPointBaricentric &w);
    int min3(float v1, float v2, float v3);
    int max3(float v1, float v2, float v3);
    int min(int v1, int v2);
    int max(int v1, int v2);

 protected:
    int width_;
    int height_;
    float distance_;
    uint *frame_;
    uchar *zbuffer_;
};



