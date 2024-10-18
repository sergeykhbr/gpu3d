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

void ZbufferWidget::slotDraw(const float *data) {
    uchar *line = new uchar[image_.width()];
    float tz;
    for (int y = 0; y < image_.height(); y++) {
        for (int x = 0; x < image_.width(); x++) {
            tz = data[y*image_.width() + x];
            if (tz < 0) {
                tz = 0;
            }
            if (tz > 1.0f) {
                tz = 1.0f;
            }
            line[x] = static_cast<uchar>(255.0f*tz);
        }
        memcpy(image_.scanLine(y), line, image_.bytesPerLine());
    }
   
    update();
    delete [] line;
}

void ZbufferWidget::paintEvent(QPaintEvent *event) {
    QPainter p(this);
    QPoint pos(0,0);
    QImage out = image_.scaledToWidth(image_.width() / 4);
    p.drawImage(pos, out);
    p.end();
}

