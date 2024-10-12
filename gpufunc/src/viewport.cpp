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

#include "viewport.h"

ViewportWidget::ViewportWidget(QWidget *parent)
    : QWidget(parent) {
    setFixedSize(640, 480);
}

void ViewportWidget::slotDraw(const QByteArray &data) {
}

void ViewportWidget::resizeEvent(QResizeEvent *ev) {
    int w = ev->size().width();
    int h = ev->size().height();
    if (w == 0 || h == 0) {
        return;
    }
    QSize pixmapSingleSize = QSize(w, h);
    pixmap_ = QPixmap(pixmapSingleSize);
    pixmap_.fill(QColor(Qt::black));
}

void ViewportWidget::paintEvent(QPaintEvent *event) {
    //renderAll();

    QPainter p(this);
    QPoint pos(0,0);
    p.drawPixmap(pos, pixmap_);
    p.end();
}

