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

#include "zbuffer.h"
#include <qimage.h>

ZbufferWidget::ZbufferWidget(QWidget *parent, int width, int height)
    : QWidget(parent),
    image_(width, height, QImage::Format_Grayscale8) {
    setFixedSize(width/4, height/4);
}

void ZbufferWidget::slotDraw(const uchar *data) {
    for (int y = 0; y < image_.height(); y++) {
        memcpy(image_.scanLine(y), &data[y * image_.width()], image_.bytesPerLine());
    }
   
    update();
}

void ZbufferWidget::paintEvent(QPaintEvent *event) {
    QPainter p(this);
    QPoint pos(0,0);
    QImage out = image_.scaledToWidth(image_.width() / 4);
    p.drawImage(pos, out);
    p.end();
}

