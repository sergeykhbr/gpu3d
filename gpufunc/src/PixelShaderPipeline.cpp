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
    FPoint2D v1 = {width_ * m[0*3], height_ * m[0*3 + 1]};
    FPoint2D v2 = {width_ * m[1*3], height_ * m[1*3 + 1]};
    FPoint2D v3 = {width_ * m[2*3], height_ * m[2*3 + 1]};
    
    memset(frame_, 0xFF, width_ * height_ * sizeof(uint));
    memset(zbuffer_, 0, width_ * height_);

    // Basic rasterization:
    //   https://fgiesen.wordpress.com/2013/02/08/triangle-rasterization-in-practice/
    drawTri(v1, v2, v3);

    emit signalFrameData(reinterpret_cast<uchar *>(frame_));
    emit signalZbufferData(zbuffer_);
}

void PixelShaderPipeline::drawTri(const FPoint2D &v0, const FPoint2D &v1, const FPoint2D &v2) {
    float area;
    FPointBaricentric w;
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
    FPoint2D p;
    for (p.y = minY; p.y <= maxY; p.y += 1.0f) {
        for (p.x = minX; p.x <= maxX; p.x += 1.0f) {
            // Determine barycentric coordinates
            // There's convention in OpenGL and Direct3D to use triangles declared
            // in counter clockwise order:
            if (v2.y > v0.y || (v2.y == v0.y && v2.y < v1.y)) {
                // Counter-clockwise order by default: v1 -> v2 -> v0
                area = orient2d(v1, v2, v0);
                w.w0 = orient2d(v1, v2, p);
                w.w1 = orient2d(v2, v0, p);
                w.w2 = orient2d(v0, v1, p);
            } else {
                // Automatic fix to counter-clockwise order: v1 -> v0 -> v2
                area = orient2d(v1, v0, v2);
                w.w0 = orient2d(v1, v0, p);
                w.w1 = orient2d(v0, v2, p);
                w.w2 = orient2d(v2, v1, p);
            }

            // If p is on or inside all edges, render pixel.
            if (w.w0 >= 0 && w.w1 >= 0 && w.w2 >= 0) {
                w.w0 /= area;
                w.w1 /= area;
                w.w2 /= area;
                renderPixel(p, w);
                zbuffer_[static_cast<int>(p.y * width_ + p.x)] = 127;
            }
        }
    }   
}

void PixelShaderPipeline::renderPixel(const FPoint2D &p, FPointBaricentric &w) {
    int pos = static_cast<int>((height_ - 1 - p.y) * width_ + p.x);
    // TODO rule: if one of w coordinates = 0 it means pixel lays on the triangle edge.
    //            we should draw only top-left edges.

    if (pos < (height_ * width_)) {
        frame_[pos] = 0xFF000000
                    + (static_cast<uint>(w.w0 * 255) << 16)
                    + (static_cast<uint>(w.w1 * 255) << 8)
                    + (static_cast<uint>(w.w2 * 255) << 0);
    }
}

float PixelShaderPipeline::orient2d(const FPoint2D& a, const FPoint2D& b, const FPoint2D& c) {
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

