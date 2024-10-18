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

class VertexShaderPipeline : public QWidget {
    Q_OBJECT

 public:
    VertexShaderPipeline(QWidget *parent);

    void setViewMatrix(fmatrix4x4 *v) { V_  = *v; }
    void setProjectionMatrix(fmatrix4x4 *p) { P_ = *p; }

 public slots:
    void slotVertexData(const float *vert, int vsz,
                        unsigned *tri, int tsz);

 signals:
    void signalVertexData(const float *vert, int vsz,
                          unsigned *tri, int tsz);

 protected:
    fmatrix4x4 V_;
    fmatrix4x4 P_;

    float output_[4096*4];
};



