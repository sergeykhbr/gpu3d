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
#include <qimage.h>

ViewportWidget::ViewportWidget(QWidget *parent)
    : QWidget(parent),
    image_(VIEWPORT_WIDTH, VIEWPORT_HEIGHT, QImage::Format_ARGB32) {
    setFixedSize(VIEWPORT_WIDTH, VIEWPORT_HEIGHT);
    memset(framebuf_.u8, 0xFF, sizeof(framebuf_));

    for (int y = 0; y < image_.height(); y++) {
        memcpy(image_.scanLine(y), &framebuf_.u32[y * VIEWPORT_WIDTH], image_.bytesPerLine());
    }
}

void ViewportWidget::slotDraw(const uchar *data) {
    memcpy(framebuf_.u8, data, sizeof(framebuf_.u8));
    for (int y = 0; y < image_.height(); y++) {
        memcpy(image_.scanLine(y), &framebuf_.u32[y * VIEWPORT_WIDTH], image_.bytesPerLine());
    }
   
    update();
}

void ViewportWidget::paintEvent(QPaintEvent *event) {
    
    QPainter p(this);
    QPoint pos(0,0);
    p.drawImage(pos, image_);
    p.end();
}

void ViewportWidget::mousePressEvent(QMouseEvent *ev) {
    setFocus();
    /** There're 2 methods: buttons() and button():
        buttons() is a multiple flag of button()
    */
    /*pressed = event->button();
    if (pressed != Qt::LeftButton && pressed != Qt::MiddleButton) {
        pressed = Qt::NoButton;
        return;
    }

    selectedEpoch = pix2epoch(event->pos());
    pressStart = event->pos();*/
}

void ViewportWidget::mouseMoveEvent(QMouseEvent *ev) {
    if (!ev->buttons()) {
        return;
    }

    /*if (pressed != Qt::NoButton) {
        selectedEpoch = pix2epoch(event->pos());
        pressEnd = event->pos();
        update();
    }*/
}

void ViewportWidget::mouseReleaseEvent(QMouseEvent *ev) {
#if 1
    emit signalRequestToUpdated();
#else
    if (pressed == Qt::MiddleButton) {
        /** Warning: changing of epochStart before epochEnd computed 
         *  will raise an errors 
         */
        int tmpStart = pix2epoch(pressStart);
        int tmpEnd = pix2epoch(pressEnd);
        if (tmpStart < tmpEnd) {
            epochStart = tmpStart;
            epochTotal = tmpEnd - epochStart + 1;
        } else if (tmpStart > tmpEnd) {
            epochStart = tmpEnd;
            epochTotal = tmpStart - epochStart + 1;
        }
    }
    pressed = Qt::NoButton;
#endif
}

void ViewportWidget::keyPressEvent(QKeyEvent *ev) {
}



