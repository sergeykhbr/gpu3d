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

VertexShaderPipeline::VertexShaderPipeline(QWidget *parent)
    : QWidget(parent) {
    memset(output_, 0, sizeof(output_));
}

void VertexShaderPipeline::slotVertexData(const float *m, int size) {
    fmatrix4x4 PV = P_ * V_;
    fvector4 v1;
    for (int i = 0; i < size; i++) {
        v1 = fvector4(m[3*i], m[3*i + 1], m[3*i + 2]);
        v1 = V_ * v1;
        v1 = P_ * v1;

        /** 4D vector back to 3D vector:
        *      | Xndc |   | Xclip/Wclip |
        *      | Yndc | = | Yclip/Wclip |
        *      | Zndc |   | Zclip/Wclip |
        * 
        * Discard any vertices outside of a 2x2x2 cube with extents at (-1, -1, -1)
        * and (1, 1, 1). Near plane mapped to Z=-1 and the far plane mapped to Z=1
        * (relative camera coordinates).
        * 
        * Warning:
        *   Depth in OpenGL pipelines map Z between -1 and 1, whereas Direct3D 0 and 1.
        */
        output_[3*i] = v1.getp()[0] / v1.getp()[3];
        output_[3*i + 1] = v1.getp()[1] / v1.getp()[3];
        output_[3*i + 2] = v1.getp()[2] / v1.getp()[3];
    }
    emit signalVertexData(output_, size);
}


