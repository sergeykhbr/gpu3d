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

PixelShaderPipeline::PixelShaderPipeline(QWidget *parent,
                                        int width, int height,
                                        float distance)
    : QWidget(parent),
    width_(width),
    height_(height),
    distance_(distance) {
    frame_ = new uint[width * height];
    zbuffer_ = new uchar[width * height];
    memset(frame_, 0xFF, width * height * sizeof(uint));
    memset(zbuffer_, 0, width * height);
}

PixelShaderPipeline::~PixelShaderPipeline() {
    delete [] frame_;
}

void PixelShaderPipeline::slotVertexData(float *m, int size) {
    memset(frame_, 0xFF, width_ * height_ * sizeof(uint));
    memset(zbuffer_, 0, width_ * height_);

    FPoint3D v0(width_*m[0*3], height_*m[0*3 + 1], m[0*3 + 2]*90);
    FPoint3D v1(width_*m[1*3], height_*m[1*3 + 1], m[1*3 + 2]*90);
    FPoint3D v2(width_*m[2*3], height_*m[2*3 + 1], m[2*3 + 2]*90);

    if (!isCounterClockWiseTriangle(v0, v1, v2)) {
        FPoint3D t0 = v0;
        v0 = v2;
        v2 = t0;
    }
    rasterizeTriangleNoOptimization(v0, v1, v2);

    emit signalFrameData(reinterpret_cast<uchar *>(frame_));
    emit signalZbufferData(zbuffer_);
}

// There's convention in OpenGL and Direct3D to use triangles declared
// in counter clockwise order.
// If the order clockwise then we look at back side of plane and can
// ignore it
bool PixelShaderPipeline::isCounterClockWiseTriangle(const FPoint3D &v0,
                                                     const FPoint3D &v1,
                                                     const FPoint3D &v2) {
    if (v2.y > v0.y || (v2.y == v0.y && v2.y < v1.y)) {
        return true;
    }
    return false;
}

void PixelShaderPipeline::rasterizeTriangleNoOptimization(const FPoint3D &v0,
                                                          const FPoint3D &v1,
                                                          const FPoint3D &v2) {

    // Compute triangle bounding box
    float area;
    int minX = min3(v0.x, v1.x, v2.x);
    int minY = min3(v0.y, v1.y, v2.y);
    int maxX = max3(v0.x, v1.x, v2.x);
    int maxY = max3(v0.y, v1.y, v2.y);

    // Clip against screen bounds
    minX = max(minX, 0);
    minY = max(minY, 0);
    maxX = min(maxX, width_ - 1);
    maxY = min(maxY, height_ - 1);


    area = orient2d(v1, v2, v0);

    // Rasterize
    Point2D c;
    FPointBaricentric w;
    int pos;
    for (c.y = minY; c.y <= maxY; c.y++) {
        for (c.x = minX; c.x <= maxX; c.x++) {
            if (baricentricPoint(area,
                             v0, v1, v2,
                             c,
                             &w) < 0) {
                continue;
            }
            pos = (height_ - 1 - c.y) * width_ + c.x;
            if (pos >= height_ * width_) {
                continue;
            }
            frame_[pos] = renderPixel(c, w);
            zbuffer_[pos] = getZBuffer(v0.z, v1.z, v2.z, w);
        }
    }
}


// Determine barycentric coordinates
int PixelShaderPipeline::baricentricPoint(float area,
                                          const FPoint3D &v0,
                                          const FPoint3D &v1,
                                          const FPoint3D &v2,
                                          Point2D c,
                                          FPointBaricentric *w) {
    // Counter-clockwise order by default: v1 -> v2 -> v0
    w->l0 = orient2d(v1, v2, FPoint3D(c)) / area;
    w->l1 = orient2d(v2, v0, FPoint3D(c)) / area;
    w->l2 = orient2d(v0, v1, FPoint3D(c)) / area;

    // If p is on or inside all edges, render pixel.
    if (w->l0 >= 0 && w->l1 >= 0 && w->l2 >= 0) {
        // TODO: l0 | l1 | l2 optimization
        return 1;
    }
    return -1;
}

uint PixelShaderPipeline::renderPixel(const Point2D &c,
                                      FPointBaricentric &w) {
    // TODO rule: if one of w coordinates = 0 it means pixel lays on the triangle edge.
    //            we should draw only top-left edges.

    return 0xFF000000
                + (static_cast<uint>(w.l0 * 255) << 16)
                + (static_cast<uint>(w.l1 * 255) << 8)
                + (static_cast<uint>(w.l2 * 255) << 0);
}

uchar PixelShaderPipeline::getZBuffer(float z0, float z1, float z2,
                                      FPointBaricentric &w) {
    float ret = 0;
    if (z1) {
        ret += w.l0 / z1;
    }
    if (z0) {
        ret += w.l1 / z0;
    }
    if (z2) {
        ret += w.l2 / z2;
    }
    // z = -1 near plane
    // z = +1 far plane
    if (ret) {
        ret = 127.0f/(ret + 1.0f);
    }
    return static_cast<uchar>(ret);
}

float PixelShaderPipeline::orient2d(const FPoint3D a,
                                    const FPoint3D b,
                                    const FPoint3D c) {
    return (b.x - a.x) * (c.y - a.y) - (b.y - a.y) * (c.x - a.x);
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

