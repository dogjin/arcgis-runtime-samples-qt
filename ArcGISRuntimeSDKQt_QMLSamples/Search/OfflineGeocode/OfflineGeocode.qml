// [WriteFile Name=OfflineGeocode, Category=Search]
// [Legal]
// Copyright 2016 Esri.

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

import QtQuick 2.6
import QtQuick.Controls 1.4
import Esri.ArcGISExtras 1.1
import Esri.ArcGISRuntime 100.0
import QtQuick.Controls.Styles 1.4
import Esri.ArcGISRuntime.Toolkit.Controls 2.0

// TODO: implement real time geocoding somehow...
Rectangle {
    id: rootRectangle
    clip: true

    width: 800
    height: 600

    property real scaleFactor: System.displayScaleFactor
    property url dataPath: System.userHomePath + "/ArcGIS/Runtime/Data"

    property Point pinLocation
    property Point clickedPoint
    property real suggestionHeight: 20
    property bool isReverseGeocode: false
    property bool isPressAndHold: false

    // Map view UI presentation at top
    MapView {
        id: mapView
        anchors.fill: parent

        calloutData {
            title: "Address"
            imageUrl: "qrc:/Samples/Search/OfflineGeocode/RedShinyPin.png"
            location: pinLocation
        }

        Map {

            // create local tiled layer using tile package
            Basemap {
                ArcGISTiledLayer {
                    TileCache {
                        path: dataPath + "/tpk/streetmap_SD.tpk"
                    }
                }
            }

            // set initial viewpoint
            ViewpointCenter {
                Point {
                    x: -13042254.715252
                    y: 3857970.236806
                    spatialReference: SpatialReference {
                        wkid: 3857
                    }
                }
                scale: 2e4
            }
        }

        // add a graphics overlay to the mapview
        GraphicsOverlay {
            id: graphicsOverlay

            // pin graphic that will visually display geocoding results
            Graphic {
                id: pinGraphic
                geometry: pinLocation
                visible: true

                PictureMarkerSymbol {
                    id: pictureMarker
                    height: 19 * scaleFactor
                    url: "qrc:/Samples/Search/OfflineGeocode/red_pin.png"
                    offsetY: height / 2 // tip of the pin will point to the location
                }
            }
        }

        Callout {
            id: callout
            calloutData: parent.calloutData
            screenOffsety: - pictureMarker.height - 10 * scaleFactor // callout will display right on top of pin
        }

        // dismiss suggestions and no results notification on mouse press
        onMousePressed: {
            noResultsRect.visible = false;
            suggestionRect.visible = false;
        }

        // separate clicking the graphic from geocode request
        onMouseClicked: {
            clickedPoint = mouse.mapPoint;
            mapView.identifyGraphicsOverlayWithMaxResults(graphicsOverlay, mouse.x, mouse.y, 5, 1);
        }

        onIdentifyGraphicsOverlayStatusChanged: {
            // if clicked on the pin graphic, display callout.
            if (identifyGraphicsOverlayStatus === Enums.TaskStatusCompleted){
                if (identifyGraphicsOverlayResults.length > 0 && !isPressAndHold)
                    callout.showCallout();
                // if user is dragging the pin, real time geocode
                else if (identifyGraphicsOverlayResults.length > 0 && isPressAndHold)
                    isReverseGeocode = true;
                // otherwise, normal reverse geocode
                else if (locatorTask.geocodeStatus !== Enums.TaskStatusInProgress){
                    isReverseGeocode = true;
                    locatorTask.reverseGeocodeWithParameters(clickedPoint, reverseGeocodeParams);
                }
            }
        }

        // hide suggestion window if viewpoint changes
        onViewpointChanged: {
            suggestionRect.visible = false;
            noResultsRect.visible = false;
        }

        // The following signal handlers are for realtime geocoding
        onMousePressAndHold: {
            if (pinLocation !== null){
                isPressAndHold = true;
                mapView.identifyGraphicsOverlayWithMaxResults(graphicsOverlay, mouse.x, mouse.y, 5, 1);
            }
        }

        onMousePositionChanged: {
            if (isPressAndHold && isReverseGeocode && locatorTask.geocodeStatus !== Enums.TaskStatusInProgress)
                locatorTask.reverseGeocodeWithParameters(mouse.mapPoint, reverseGeocodeParams);
        }

        onMouseReleased: {
            isPressAndHold = false;
            isReverseGeocode = false;
        }
    }

    LocatorTask {
        id: locatorTask
        url: dataPath + "/Locators/SanDiego_StreetAddress.loc"

        suggestions {
            searchText: textField.text
            suggestTimerThreshold: 250
            suggestParameters: SuggestParameters {
                maxResults: 5
            }
        }

        GeocodeParameters {
            id: geocodeParams
            resultAttributeNames: ["Match_addr"]
            minScore: 75
            maxResults: 1
        }

        ReverseGeocodeParameters {
            id: reverseGeocodeParams
            maxDistance: 1000
            maxResults: 1
        }

        onGeocodeStatusChanged: {
            if (geocodeStatus === Enums.TaskStatusInProgress){
                busyIndicator.visible = true;
            }
            else if (geocodeStatus === Enums.TaskStatusCompleted){
                busyIndicator.visible = false;

                if(locatorTask.geocodeResults.length > 0){
                    callout.dismiss();

                    // zoom to geocoded location
                    mapView.setViewpointGeometry(geocodeResults[0].extent)

                    // set pin and callout detail
                    pinLocation = geocodeResults[0].displayLocation;
                    mapView.calloutData.detail = geocodeResults[0].label;

                    // if it was a reverse geocode, also display callout
                    if (isReverseGeocode)
                        callout.showCallout();

                    if (!isPressAndHold)
                        isReverseGeocode = false;
                }

                else {
                    // if no result found, inform user
                    callout.dismiss()
                    noResultsRect.visible = true;
                    pinLocation = null;
                }
            }
        }
    }

    Column {
        anchors {
            fill: parent
            margins: 10 * scaleFactor
        }

        Rectangle {
            width: 300 * scaleFactor
            height: 35 * scaleFactor
            color: "#f7f8fa"

            Row {
                width: parent.width
                height: parent.height

                TextField {
                    id: textField
                    width: parent.width
                    height: parent.height
                    opacity: 0.95
                    placeholderText: "Enter an Address"

                    style: TextFieldStyle {
                        background: Rectangle {
                            color: "#f7f8fa"
                            border {
                                color: "#7B7C7D"
                                width: 1 * scaleFactor
                            }
                            radius: 2
                        }
                    }

                    onAccepted: {
                        suggestionRect.visible = false;
                        if(locatorTask.geocodeStatus !== Enums.TaskStatusInProgress)
                            locatorTask.geocodeWithParameters(text, geocodeParams);
                    }
                }

                Rectangle {
                    anchors {
                        verticalCenter: parent.verticalCenter
                        right: parent.right
                        margins: 5 * scaleFactor
                    }

                    width: 35 * scaleFactor
                    color: "#f7f8fa"
                    radius: 2

                    Image {
                        anchors.centerIn: parent
                        width: parent.width
                        height: parent.width
                        source: suggestionRect.visible === true ? "qrc:/Samples/Search/OfflineGeocode/ic_menu_closeclear_light_d.png" : "qrc:/Samples/Search/OfflineGeocode/ic_menu_collapsedencircled_light_d.png"

                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                suggestionRect.visible === true ? suggestionRect.visible = false : suggestionRect.visible = true
                            }
                        }
                    }
                }

                BusyIndicator {
                    id: suggestBusyIndicator
                    anchors.verticalCenter: parent.verticalCenter
                    height: 25 * scaleFactor
                    visible: suggestionRect.visible === true && locatorTask.suggestions.suggestInProgress === true
                }
            }
        }

        Rectangle {
            id: suggestionRect
            width: textField.width
            height: suggestionHeight * locatorTask.suggestions.count * scaleFactor
            color: "#f7f8fa"
            opacity: 0.85
            visible: false

            ListView {
                id: suggestView
                model: locatorTask.suggestions
                height: parent.height
                delegate: Component {

                    Rectangle {
                        width: textField.width
                        height: suggestionHeight * scaleFactor
                        color: "#f7f8fa"
                        border.color: "darkgray"

                        Text {
                            anchors {
                                verticalCenter: parent.verticalCenter
                                margins: 10 * scaleFactor
                            }
                            text: modelData
                            font {
                                weight: Font.Black
                                pixelSize: 12 * scaleFactor
                            }
                            elide: Text.ElideRight
                            leftPadding: 5 * scaleFactor
                            renderType: Text.NativeRendering
                            color: "black"
                        }

                        // when user clicks suggestion, geocode with the selected address
                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                suggestView.currentIndex = index;
                                suggestionRect.visible = false;
                                if (locatorTask.geocodeStatus !== Enums.TaskStatusInProgress){
                                    textField.text = locatorTask.suggestions.get(suggestView.currentIndex).label
                                    locatorTask.geocodeWithSuggestResult(locatorTask.suggestions.get(suggestView.currentIndex));
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    BusyIndicator {
        id: busyIndicator
        anchors.centerIn: parent
        visible: false
    }

    Rectangle {
        id: noResultsRect
        anchors.centerIn: parent
        height: 50 * scaleFactor
        width: 200 * scaleFactor
        color: "lightgrey"
        visible: false
        radius: 2 * scaleFactor
        opacity: 0.85
        border.color: "black"

        Text {
            anchors.centerIn: parent
            text: "No matching addresses"
            renderType: Text.NativeRendering
            font.pixelSize: 18 * scaleFactor
        }
    }

    // Neatline rectangle
    Rectangle {
        anchors.fill: parent
        color: "transparent"
        border {
            width: 0.5 * scaleFactor
            color: "black"
        }
    }
}
