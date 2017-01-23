// Copyright 2015-2016 Esri.

// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
// http://www.apache.org/licenses/LICENSE-2.0

// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

#include <QGuiApplication>
#include <QQuickView>
#include <QDir>
#include <QQmlEngine>
#include <QSurfaceFormat>

int main(int argc, char *argv[])
{
#if defined(Q_OS_LINUX) && !defined(Q_OS_ANDROID)
    // Linux requires 3.2 OpenGL Context
    // in order to instance 3D symbols
    QSurfaceFormat fmt = QSurfaceFormat::defaultFormat();
    fmt.setVersion(3, 2);
    QSurfaceFormat::setDefaultFormat(fmt);
#endif

    QGuiApplication app(argc, argv);
    
#ifdef Q_OS_WIN
    // Force usage of OpenGL ES through ANGLE on Windows
    QCoreApplication::setAttribute(Qt::AA_UseOpenGLES);
#endif

    // Intialize application view
    QQuickView view;
    view.setResizeMode(QQuickView::SizeRootObjectToView);

    // Add the import Path
    view.engine()->addImportPath(QDir(QCoreApplication::applicationDirPath()).filePath("qml"));
    view.engine()->addImportPath(ARCGIS_TOOLKIT_IMPORT_PATH);
    view.engine()->addImportPath(ARCGIS_RUNTIME_IMPORT_PATH);

    // Set the source
    view.setSource(QUrl("qrc:/Samples/DisplayInformation/GraphicsOverlay_DictionaryRenderer_3D/GraphicsOverlay_DictionaryRenderer_3D.qml"));

    view.show();

    return app.exec();
}
