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
#include "matrix.h"
#include "PixelShaderPipeline.h"

#define DRAW_VERTEX_DOTS

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

void PixelShaderPipeline::slotVertexData(const float *camera, int vsz,
                                         const float *uv, int uvsz,
                                         unsigned *tri, unsigned *uvtri, float *normal, int tsz) {
    float screenrate =  static_cast<float>(width_) / static_cast<float>(height_);
    memset(frame_, 0xFF, width_ * height_ * sizeof(uint));

    for (int i = 0; i < width_ * height_; i++) {
        zbuffer_[i] = 1.0;
    }

    fvector4 cam;
    fvector4 p;
    ProjectionVertexData *proj;
    for (int i = 0; i < vsz; i++) {
        proj = &projection_[i];
        cam = fvector4(camera[3*i], camera[3*i + 1], camera[3*i + 2], 1.0f);
        p = P_ * cam;

        // Z after projection is equal to -Z in camera space, get inversed value
        // to use it in hyperbolic interpolation from projection to camera space:
        proj->xy[0] = p[0] / p[3];
        proj->xy[1] = p[1] / p[3];
        proj->fz = 1.0f / p[2];

        // remap [-1.0; 1.0] to [0:width-1] and the same for height:
        proj->xy[0] = 0.5f * (proj->xy[0] + 1.0f) * width_;
        proj->xy[1] = 0.5f * (1.0f - proj->xy[1]) * height_;

        if (proj->xy[0] < 0 || proj->xy[0] >= width_ 
            || proj->xy[1] < 0 || proj->xy[1] >= height_) {
            proj->visible = false;
            proj->w = 0;
            proj->h = 0;
        } else {
            // Convert to raster space and mark the vertex position on the image with a simple dot
            proj->w = static_cast<int>(proj->xy[0]);
            proj->h = static_cast<int>(proj->xy[1]);
        }

#ifdef DRAW_VERTEX_DOTS
        frame_[proj->h * width_ + proj->w] = 0xFF0000ff;  // red dot in vertex position
#endif
    }

    // Go throug list of triangles
    fvector3 cam0, cam1, cam2;
    ProjectionVertexData *prj0, *prj1, *prj2;
    fvector3 n;
    for (int i = 0; i < tsz; i++) {
        cam0 = fvector3(&camera[3*tri[3*i]]);
        cam1 = fvector3(&camera[3*tri[3*i + 1]]);
        cam2 = fvector3(&camera[3*tri[3*i + 2]]);
        prj0 = &projection_[tri[3*i]];
        prj1 = &projection_[tri[3*i + 1]];
        prj2 = &projection_[tri[3*i + 2]];

        prj0->uv = fvector2(&uv[2*uvtri[3*i]]) * prj0->fz;
        prj1->uv = fvector2(&uv[2*uvtri[3*i + 1]]) * prj1->fz;
        prj2->uv = fvector2(&uv[2*uvtri[3*i + 2]]) * prj2->fz;
        
        n = fvector3(&normal[3*i]);

        rasterizeTriangleNoOptimization(cam0, cam1, cam2,
                                        *prj0, *prj1, *prj2,
                                        n);
    }

    emit signalFrameData(reinterpret_cast<uchar *>(frame_));
    emit signalZbufferData(zbuffer_);
}

void PixelShaderPipeline::rasterizeTriangleNoOptimization(const fvector3 &cam0,
                                                          const fvector3 &cam1,
                                                          const fvector3 &cam2,
                                                          const ProjectionVertexData &prj0,
                                                          const ProjectionVertexData &prj1,
                                                          const ProjectionVertexData &prj2,
                                                          const fvector3 &norm) {

    // Compute triangle bounding box
    float area;
    int minX = min3(prj0.xy[0], prj1.xy[0], prj2.xy[0]);
    int minY = min3(prj0.xy[1], prj1.xy[1], prj2.xy[1]);
    int maxX = max3(prj0.xy[0], prj1.xy[0], prj2.xy[0]);
    int maxY = max3(prj0.xy[1], prj1.xy[1], prj2.xy[1]);

    // Clip against screen bounds
    minX = max(minX, 0);
    minY = max(minY, 0);
    maxX = min(maxX, width_ - 1);
    maxY = min(maxY, height_ - 1);
    if (minX >= width_ || maxX < 0
        || minY >= height_ || maxY < 0) {
        // all vertext out-of-screen
        return;
    }

    area = orient2d(prj0.xy, prj1.xy, prj2.xy);

    // Rasterize
    FPoint2D p;
    FPointBaricentric w;
    int pos;
    for (int y = minY; y <= maxY; y++) {
        for (int x = minX; x <= maxX; x++) {
            if (baricentricPoint(area,
                             prj0.xy, prj1.xy, prj2.xy,
                             fvector2(x + 0.5f, y + 0.5f),
                             &w) < 0) {
                continue;
            }
            pos = y * width_ + x;
            if (pos >= height_ * width_) {
                continue;
            }
            float tz = getZBuffer(prj0.fz, prj1.fz, prj2.fz, w);
            if (tz >= far_ * zbuffer_[pos]) {
                continue;
            }
            zbuffer_[pos] = tz / far_;

#if 1
            // pixel coordinate in a camera space (pt) extrapolated from
            // baricentric coordinate:
            p.x = (cam0[0] / -cam0[2]) * w.l0 + (cam1[0] / -cam1[2]) * w.l1 + (cam2[0] / -cam2[2]) * w.l2;
            p.y = (cam0[1] / -cam0[2]) * w.l0 + (cam1[1] / -cam1[2]) * w.l1 + (cam2[1] / -cam2[2]) * w.l2;
            
            fvector3 pt(p.x * tz,
                        p.y * tz,
                        -tz);

            // extrapolated texture coordinate:
            fvector2 st = prj0.uv * w.l0 + prj1.uv * w.l1 + prj2.uv * w.l2;
            st *= tz;

            fvector3 viewDirection = -pt;
            viewDirection.normalize();

            // shading effect. dotProduct is a measure of similatiry of two vectors:
            float nDotView = std::max(0.0f, norm.dotProduct(viewDirection));
            // checkmate coloring
            const int M = 10;
            float checker = (fmod(st[0] * M, 1.0) > 0.5) ^ (fmod(st[1] * M, 1.0) < 0.5);
            float c = 0.3 * (1 - checker) + 0.7 * checker;
            nDotView *= c;

            // gray is the sum of rgb, so change rgb simutaneously
            frame_[pos] = 0xFF000000
                + (static_cast<uint>(nDotView * 255) << 16)
                + (static_cast<uint>(nDotView * 255) << 8)
                + (static_cast<uint>(nDotView * 255) << 0);


#else
            frame_[pos] = renderPixel(c, w);
#endif
        }
    }
}


// Determine barycentric coordinates
int PixelShaderPipeline::baricentricPoint(float area,
                                          const fvector2 &v0,
                                          const fvector2 &v1,
                                          const fvector2 &v2,
                                          const fvector2 &c,
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
float PixelShaderPipeline::orient2d(const fvector2 &a,
                                    const fvector2 &b,
                                    const fvector2 &c) {
    return (c[0] - a[0]) * (b[1] - a[1]) - (c[1] - a[1]) * (b[0] - a[0]);
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

