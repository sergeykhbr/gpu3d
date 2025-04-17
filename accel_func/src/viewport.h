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
#include <QtGui/QPixmap>
#include <QtGui/QImage>
#include <QtGui/QPainter>
#include <QtGui/qevent.h>
#include <QWheelEvent>

static const int VIEWPORT_WIDTH = 640;
static const int VIEWPORT_HEIGHT = 480;

class ViewportWidget : public QWidget {
    Q_OBJECT

 public:
    explicit ViewportWidget(QWidget *parent);

 public slots:
    void slotDraw(const uchar *data);

 signals:
    void signalRequestToUpdated();
    void signalZoom(float zoom);

 protected:
    void paintEvent(QPaintEvent *ev);
    void wheelEvent(QWheelEvent* ev) override;
    void mousePressEvent(QMouseEvent *ev);
    void mouseMoveEvent(QMouseEvent *ev);
    void mouseReleaseEvent(QMouseEvent *ev);
    void keyPressEvent(QKeyEvent *event);

 private:
    static const int VIEWPORT_SIZE = VIEWPORT_WIDTH * VIEWPORT_HEIGHT;
    union FrameBufferType {
        uchar u8[VIEWPORT_SIZE * sizeof(uint)];
        uint u32[VIEWPORT_SIZE];
    } framebuf_;

    QPixmap pixmap_;
    QImage image_;
};


