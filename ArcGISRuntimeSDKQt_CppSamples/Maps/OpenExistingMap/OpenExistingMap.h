// [WriteFile Name=OpenExistingMap, Category=Maps]
// [Legal]
// Copyright 2015 Esri.

// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
// http://www.apache.org/licenses/LICENSE-2.0

// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
// [Legal]

#ifndef OPEN_EXISTING_MAP_H
#define OPEN_EXISTING_MAP_H

namespace Esri
{
    namespace ArcGISRuntime
    {
        class MapQuickView;
    }
}

class QString;

#include <QQuickItem>

class OpenExistingMap : public QQuickItem
{
    Q_OBJECT

public:
    OpenExistingMap(QQuickItem* parent = 0);
    ~OpenExistingMap();

    void componentComplete() Q_DECL_OVERRIDE;
    Q_INVOKABLE void openMap(QString itemId);

private:
    Esri::ArcGISRuntime::MapQuickView* m_mapView;
};

#endif // OPEN_EXISTING_MAP_H

