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

#include "input.h"
#include "examples/cow/cow_vertices.h"
#include "examples/cow/cow_triangles.h"
#include "examples/cow/cow_uv.h"

const float view_coef[16] = { 0.707107, -0.331295, 0.624695, 0,
                             0, 0.883452, 0.468521, 0,
                             -0.707107, -0.331295, 0.624695, 0,
                             -1.63871, -5.747777, -40.400412, 1 };



InputWidget::InputWidget(QWidget *parent)
    : QTableWidget(parent),
    //V_(-10.0, -25.0, -20.0f, 30.0f, 30.0f, 0.0) {
    V_(view_coef) {
    setMinimumSize(100, 100);
    setRowCount(cowNumVertices);
    setColumnCount(4);
    setHorizontalHeaderLabels(QStringList({tr("x"), tr("y"), tr("z"), tr("face")}));

    fvector3 *p = cow_vertices;

    QTableWidgetItem *newItem;
    for (int i = 0; i < rowCount(); i++) {
        newItem = new QTableWidgetItem(QString::asprintf("%.2f", p[i][0]));
        setItem(i, 0, newItem);
        newItem = new QTableWidgetItem(QString::asprintf("%.2f", p[i][1]));
        setItem(i, 1, newItem);
        newItem = new QTableWidgetItem(QString::asprintf("%.2f", p[i][2]));
        setItem(i, 2, newItem);
    }
}

void InputWidget::slotRequestToUpdate() {
    emit signalVertexData(V_.getp(),
                          cow_vertices->getp(), cowNumVertices,
                          &cow_uv[0][0], cowNumUV,
                          cow_triangles, cow_uv_index, cowTrianglesNum);
}

void InputWidget::slotZoom(float zoom) {
    fmatrix4x4 Tr;
    Tr.Identity();
#if 1
    Tr[14] = zoom;
    V_ = V_ * Tr;
#else
    Tr[0] = zoom;
    Tr[5] = zoom;
    Tr[10] = zoom;
    V_ = Tr * V_;
#endif
    slotRequestToUpdate();
}

