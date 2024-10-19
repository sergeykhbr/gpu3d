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

#include "VertexShaderPipeline.h"
#include "gputypes.h"

VertexShaderPipeline::VertexShaderPipeline(QWidget *parent)
    : QWidget(parent) {
    memset(output_, 0, sizeof(output_));
}

void VertexShaderPipeline::slotVertexData(const float *vert, int vsz,
                                          const float *uv, int uvsz,
                                          unsigned *tri, unsigned *uvtri, int tsz) {
    // Affine tranformation do not change perspective coordinate w
    fvector3 v1;
    for (int i = 0; i < vsz; i++) {
        v1 = fvector3(&vert[3*i]);
        v1 = V_ * v1;           // World to camera
        output_[3*i] = v1[0];
        output_[3*i + 1] = v1[1];
        output_[3*i + 2] = v1[2];
    }

    // Go through a array of triangles to compute normal as a crossproduct of 
    // two vector: A=v1-v0; B=v2-v0; => n = A * B
    fvector3 p0, p1, p2;
    fvector3 n;
    for (int i = 0; i < tsz; i++) {
        p0 = fvector3(&output_[3*tri[3*i]]);
        p1 = fvector3(&output_[3*tri[3*i + 1]]);
        p2 = fvector3(&output_[3*tri[3*i + 2]]);

        n = (p1 - p0).crossProduct(p2 - p0);
        n.normalize();
        normal_[3*i] = n[0];
        normal_[3*i + 1] = n[1];
        normal_[3*i + 2] = n[2];
    }
    

    emit signalVertexData(output_, vsz,
                          uv, uvsz,
                          tri, uvtri, normal_, tsz);
}


