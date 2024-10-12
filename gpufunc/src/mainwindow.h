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

#include <QMainWindow>
#include <QLabel>
#include <QStatusBar>
#include "input.h"
#include "viewport.h"

class MainWindow : public QMainWindow
{
    Q_OBJECT

 public:
    explicit MainWindow();
    virtual ~MainWindow();

 protected:
    virtual void closeEvent(QCloseEvent *event) override;

 private slots:
    void slotTextToStatusBar(qint32 idx, const QString &message);

 private:
    InputWidget *input_;
    ViewportWidget *viewport_;
    QLabel *labelStatus_[2];
};
