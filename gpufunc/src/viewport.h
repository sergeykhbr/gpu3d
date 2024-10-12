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
#include <QtGui/QPainter>
#include <QtGui/qevent.h>

class ViewportWidget : public QWidget {
    Q_OBJECT

 public:
    explicit ViewportWidget(QWidget *parent = nullptr);

 public slots:
    void slotDraw(const QByteArray &data);

 protected:
    void resizeEvent(QResizeEvent *ev);
    void paintEvent(QPaintEvent *ev);

 private:

    QPixmap pixmap_;
};


