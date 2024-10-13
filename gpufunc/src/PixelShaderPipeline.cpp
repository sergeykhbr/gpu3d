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

#include "PixelShaderPipeline.h"

PixelShaderPipeline::PixelShaderPipeline(QWidget *parent, int width, int height)
    : QWidget(parent),
    width_(width),
    height_(height) {
    frame_ = new uint[width * height];
    zbuffer_ = new uchar[width * height];
    memset(frame_, 0xFF, width * height * sizeof(uint));
    memset(zbuffer_, 0, width * height);
}

PixelShaderPipeline::~PixelShaderPipeline() {
    delete [] frame_;
}

void PixelShaderPipeline::slotVertexData(float *m, int size) {
    Point2D v1 = {static_cast<int>(width_ * m[0*3]), static_cast<int>(height_ * m[0*3 + 1])};
    Point2D v2 = {static_cast<int>(width_ * m[1*3]), static_cast<int>(height_ * m[1*3 + 1])};
    Point2D v3 = {static_cast<int>(width_ * m[2*3]), static_cast<int>(height_ * m[2*3 + 1])};
    
    memset(frame_, 0xFF, width_ * height_ * sizeof(uint));
    memset(zbuffer_, 0, width_ * height_);

    // Basic rasterization:
    //   https://fgiesen.wordpress.com/2013/02/08/triangle-rasterization-in-practice/
    drawTri(v1, v2, v3);

    emit signalFrameData(reinterpret_cast<uchar *>(frame_));
    emit signalZbufferData(zbuffer_);
}

void PixelShaderPipeline::drawTri(const Point2D &v0, const Point2D &v1, const Point2D &v2) {
    // Compute triangle bounding box
    int minX = min3(v0.x, v1.x, v2.x);
    int minY = min3(v0.y, v1.y, v2.y);
    int maxX = max3(v0.x, v1.x, v2.x);
    int maxY = max3(v0.y, v1.y, v2.y);

    // Clip against screen bounds
    minX = max(minX, 0);
    minY = max(minY, 0);
    maxX = min(maxX, width_ - 1);
    maxY = min(maxY, height_ - 1);

    // Rasterize
    Point2D p;
    for (p.y = minY; p.y <= maxY; p.y++) {
        for (p.x = minX; p.x <= maxX; p.x++) {
#if 1
if (p.x == 200 && p.y == 165) {
    bool st = true;
}
#endif
            // Determine barycentric coordinates
            int w0 = orient2d(v1, v2, p);
            int w1 = orient2d(v2, v0, p);
            int w2 = orient2d(v0, v1, p);

            // If p is on or inside all edges, render pixel.
            if (w0 >= 0 && w1 >= 0 && w2 >= 0) {
                renderPixel(p, w0, w1, w2);
                zbuffer_[p.y * width_ + p.x] = 127;
            }
        }
    }   
}

void PixelShaderPipeline::renderPixel(const Point2D &p, int w0, int w1, int w2) {
    //frame_[(height_ - p.y - 1) * width_ + p.x] = 0xFF112233;
    frame_[p.y * width_ + p.x] = 0xFF112233;
}

float PixelShaderPipeline::orient2d(const Point2D& a, const Point2D& b, const Point2D& c) {
    return (b.x-a.x)*(c.y-a.y) - (b.y-a.y)*(c.x-a.x);
}

int PixelShaderPipeline::min3(float v1, float v2, float v3) {
    int ret = static_cast<int>(v1);
    if (static_cast<int>(v2) < ret) {
        ret = static_cast<int>(v2);
    }
    if (static_cast<int>(v3) < ret) {
        ret = static_cast<int>(v3);
    }
    return ret;
}

int PixelShaderPipeline::max3(float v1, float v2, float v3) {
    int ret = static_cast<int>(v1);
    if (static_cast<int>(v2) > ret) {
        ret = static_cast<int>(v2);
    }
    if (static_cast<int>(v3) > ret) {
        ret = static_cast<int>(v3);
    }
    return ret;
}

int PixelShaderPipeline::min(int v1, int v2) {
    return (v1 < v2) ? v1 : v2;
}

int PixelShaderPipeline::max(int v1, int v2) {
    return (v1 > v2) ? v1 : v2;
}

