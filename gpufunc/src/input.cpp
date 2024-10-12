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

InputWidget::InputWidget(QWidget *parent)
    : QTableWidget(parent) {
    setMinimumSize(100, 100);
    setRowCount(3);
    setColumnCount(4);
    setHorizontalHeaderLabels(QStringList({tr("x"), tr("y"), tr("z"), tr("face")}));

    coord_[0] = CoordF(0, 0, 0);
    coord_[1] = CoordF(0, 0, 1);
    coord_[2] = CoordF(1, 1, 1);

    QTableWidgetItem *newItem;
    for (int i = 0; i < columnCount(); i++) {
        newItem = new QTableWidgetItem(QString::asprintf("%.2f", coord_[i].x));
        setItem(i, 0, newItem);
        newItem = new QTableWidgetItem(QString::asprintf("%.2f", coord_[i].y));
        setItem(i, 1, newItem);
        newItem = new QTableWidgetItem(QString::asprintf("%.2f", coord_[i].z));
        setItem(i, 2, newItem);
    }
}

void InputWidget::getVertex(float **m, int *size) {
    *m = &coord_->x;
    *size = rowCount();
}
