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

#include "mainwindow.h"
#include <QLabel>
#include <QMessageBox>
#include <QHBoxLayout>
#include <QGridLayout>
#include <QMenuBar>
#include <QToolBar>
#include <QApplication>
#include <QScreen>
#include <qevent.h>

static const float FRUSTRUM_NEAR = 1.0f;
static const float FRUSTRUM_FAR = 100.0f;

MainWindow::MainWindow() :
    QMainWindow(nullptr),
    viewMatrix_(0, 0, -5.0f, 0, 0, 0),
    projectionMatrix_(FRUSTRUM_NEAR,
                      FRUSTRUM_FAR,
                      VIEWPORT_WIDTH,
                      VIEWPORT_HEIGHT,
                      60.0f)
{
    /*QSize appsz = qApp->screens()[0]->size();
    if (appsz.width() <= 1280 && appsz.height() <= 600) {
        showFullScreen();
    } else {
        appsz.setWidth(1280);
        appsz.setHeight(600);
        setFixedSize(appsz);
    }*/
    setWindowIcon(QIcon(":/images/logogpu.png"));
    setWindowTitle(tr("gpufunc"));

    QWidget *mainWidget = new QWidget(this);

    QGridLayout *gridlayout = new QGridLayout(mainWidget);
    mainWidget->setLayout(gridlayout);

    input_ = new InputWidget(mainWidget);
    gridlayout->addWidget(input_, 0, 0);


    vertexPipeline_ = new VertexShaderPipeline(this);
    vertexPipeline_->setViewMatrix(&viewMatrix_);
    vertexPipeline_->setProjectionMatrix(&projectionMatrix_);

    pixelPipeline_ = new PixelShaderPipeline(this,
                                             VIEWPORT_WIDTH,
                                             VIEWPORT_HEIGHT,
                                             FRUSTRUM_FAR - FRUSTRUM_NEAR);

    viewport_ = new ViewportWidget(mainWidget);
    gridlayout->addWidget(viewport_, 0, 1);
    gridlayout->setColumnStretch(0, 3);

    setCentralWidget(mainWidget);

    
    QHBoxLayout *layout2 = new QHBoxLayout(mainWidget);
    gridlayout->addLayout(layout2, 1, 1);

    zbuffer_ = new ZbufferWidget(mainWidget, VIEWPORT_WIDTH, VIEWPORT_HEIGHT);
    layout2->addWidget(zbuffer_);
    layout2->addWidget(new QWidget(mainWidget));


    QStatusBar *statusBar_ = new QStatusBar(this);
    labelStatus_[0] = new QLabel();
    labelStatus_[1] = new QLabel();
    //labelStatus_[0]->setFixedWidth(appsz.width() - 100);
    labelStatus_[1]->setFixedWidth(50);
    setStatusBar(statusBar_);
    statusBar_->addWidget(labelStatus_[0]);
    statusBar_->addWidget(labelStatus_[1]);

    connect(viewport_, &ViewportWidget::signalRequestToUpdated,
            input_, &InputWidget::slotRequestToUpdate);
    connect(input_, &InputWidget::signalVertexData,
            vertexPipeline_, &VertexShaderPipeline::slotVertexData);
    connect(vertexPipeline_, &VertexShaderPipeline::signalVertexData,
            pixelPipeline_, &PixelShaderPipeline::slotVertexData);
    connect(pixelPipeline_, &PixelShaderPipeline::signalFrameData,
            viewport_, &ViewportWidget::slotDraw);
    connect(pixelPipeline_, &PixelShaderPipeline::signalZbufferData,
            zbuffer_, &ZbufferWidget::slotDraw);

    // Output to status bar
}

MainWindow::~MainWindow() {
}

void MainWindow::closeEvent(QCloseEvent *event) {
    // TODO: save state
    event->accept();
}

void MainWindow::slotTextToStatusBar(qint32 idx, const QString &message) {
    labelStatus_[idx]->setText(message);
}

