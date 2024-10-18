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

 #include "gputypes.h"
#include "PixelShaderPipeline.h"

PixelShaderPipeline::PixelShaderPipeline(QWidget *parent,
                                        int width, int height,
                                        float near, float far)
    : QWidget(parent),
    width_(width),
    height_(height),
    near_(near),
    far_(far) {
    frame_ = new uint[width * height];
    zbuffer_ = new float[width * height];
    memset(frame_, 0xFF, width * height * sizeof(uint));
    memset(zbuffer_, 0, width * height * sizeof(float));
}

PixelShaderPipeline::~PixelShaderPipeline() {
    delete [] frame_;
}

void PixelShaderPipeline::slotVertexData(const float *vert, int vsz,
                                         unsigned *tri, int tsz) {
    float screenrate =  static_cast<float>(width_) / static_cast<float>(height_);
    memset(frame_, 0xFF, width_ * height_ * sizeof(uint));

    for (int i = 0; i < width_ * height_; i++) {
        zbuffer_[i] = 1.0;
    }

    const CoordF *p;
    for (int i = 0; i < vsz; i++) {
        p = &reinterpret_cast<const CoordF *>(vert)[i];
        if (p->x < -screenrate || p->x > screenrate
            || p->y < -1.0f || p->y > 1.0f) {
            continue;
        }
        // Convert to raster space and mark the vertex position on the image with a simple dot
        raster_[i].x = static_cast<int>((p->x + 1) * 0.5 * width_);
        if (raster_[i].x >= width_) {
            raster_[i].x = width_ - 1;
        }
        raster_[i].y = static_cast<int>((1 - (p->y + 1) * 0.5) * height_);
        if (raster_[i].y >= height_) {
            raster_[i].y = height_ - 1;
        }
        frame_[raster_[i].y * width_ + raster_[i].x] = 0xFF0000ff;  // red dot in vertex position
    }

    for (int i = 0; i < tsz; i++) {
        rasterizeTriangleNoOptimization(raster_[tri[3*i]],
                                        raster_[tri[3*i + 1]],
                                        raster_[tri[3*i + 2]],
                                        vert[3*tri[3*i] + 2],
                                        vert[3*tri[3*i + 1] + 2],
                                        vert[3*tri[3*i + 2] + 2]);
    }

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

void PixelShaderPipeline::rasterizeTriangleNoOptimization(const Point2D &v0,
                                                          const Point2D &v1,
                                                          const Point2D &v2,
                                                          float z0,
                                                          float z1,
                                                          float z2) {

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


    area = orient2d(v0, v1, v2);

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
            pos = c.y * width_ + c.x;
            if (pos >= height_ * width_) {
                continue;
            }
            frame_[pos] = renderPixel(c, w);
            float tz = getZBuffer(z0, z1, z2, w) / far_;
            if (tz < zbuffer_[pos]) {
                zbuffer_[pos] = tz;
            }
        }
    }
}


// Determine barycentric coordinates
int PixelShaderPipeline::baricentricPoint(float area,
                                          const Point2D &v0,
                                          const Point2D &v1,
                                          const Point2D &v2,
                                          const Point2D &c,
                                          FPointBaricentric *w) {
    // Counter-clockwise order by default: v1 -> v2 -> v0
    w->l0 = static_cast<float>(orient2d(v1, v2, c)) / area;
    w->l1 = static_cast<float>(orient2d(v2, v0, c)) / area;
    w->l2 = static_cast<float>(orient2d(v0, v1, c)) / area;

    // If p is on or inside all edges, render pixel.
    if (w->l0 >= 0 && w->l1 >= 0 && w->l2 >= 0) {
        // TODO: l0 | l1 | l2 optimization
        return 1;
    }
    return -1;
}

// TODO: check for overflow
int PixelShaderPipeline::orient2d(const Point2D &a,
                                  const Point2D &b,
                                  const Point2D &c) {
    return (c.x - a.x) * (b.y - a.y) - (c.y - a.y) * (b.x - a.x);
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

float PixelShaderPipeline::getZBuffer(float z0, float z1, float z2,
                                      FPointBaricentric &w) {
    float ret;
    ret = w.l0 * z1 + w.l1 * z1 + w.l2 * z2;
    if (ret) {
        ret = 1.0f/ret;
    }
    return ret;
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

