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
                        int height);
    virtual ~PixelShaderPipeline();

 public slots:
    void slotVertexData(float *m, int size);

 signals:
    void signalFrameData(uchar *frame);
    void signalZbufferData(uchar *zbuffer);

 protected:
    struct FPoint2D {
        float x, y;
    };
    struct Point2D {
        int x, y;
    };
    /**
      Not-optimized basic rasterizer:
        https://fgiesen.wordpress.com/2013/02/08/triangle-rasterization-in-practice/
     */
    void drawTri(const Point2D &v0, const Point2D &v1, const Point2D &v2);
    float orient2d(const Point2D& a, const Point2D& b, const Point2D& c);
    void renderPixel(const Point2D &p, int w0, int w1, int w2);
    int min3(float v1, float v2, float v3);
    int max3(float v1, float v2, float v3);
    int min(int v1, int v2);
    int max(int v1, int v2);

 protected:
    int width_;
    int height_;
    uint *frame_;
    uchar *zbuffer_;
};



