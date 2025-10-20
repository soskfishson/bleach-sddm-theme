/*
 * Bleach SDDM Theme
 * Copyright (C) 2025 Fishson
 * 
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 * 
 * Portions of this code are derived from KDE Breeze SDDM Theme:
 * Copyright (C) 2016 David Edmundson <davidedmundson@kde.org>
 * Licensed under LGPL-2.0-or-later
 * 
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU General Public License for more details.
 */
import QtQuick 6.0
import QtQuick.Layouts 6.0
import QtQuick.Controls 6.0 as QQC2
import Qt5Compat.GraphicalEffects

import SddmComponents 2.0

Rectangle {
    id: root
    width: 1920
    height: 1080 
    color: "#101010"

    Image {
        id: backgroundImage
        anchors.fill: parent
        source: config.background || "background.jpg"
        fillMode: Image.PreserveAspectCrop
        opacity: 0.3 
    }

    Rectangle {
        anchors.fill: parent
        color: "black"
        opacity: 0.3
    }

    Rectangle {
        id: topBar
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        height: 60
        color: "#20000000"

        RowLayout {
            anchors.fill: parent
            anchors.margins: 10
            spacing: 10

            QQC2.ComboBox {
                id: sessionSelect
                Layout.preferredWidth: 200
                model: sessionModel
                currentIndex: sessionModel.lastIndex
                textRole: "name"

                delegate: QQC2.ItemDelegate {
                    width: parent.width
                    text: model.name
                }
            }

            Item { Layout.fillWidth: true }

            Row {
                spacing: 10

                Rectangle {
                    width: 40
                    height: 40
                    radius: 5
                    color: suspendArea.containsMouse ? "#60ffffff" : "#40ffffff"
                    visible: sddm.canSuspend
                    Text { anchors.centerIn: parent; text: "⏾"; font.pixelSize: 20; color: "white" }
                    MouseArea { 
                        id: suspendArea
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: sddm.suspend()
                        cursorShape: Qt.PointingHandCursor
                    }
                }

                Rectangle {
                    width: 40
                    height: 40
                    radius: 5
                    color: rebootArea.containsMouse ? "#60ffffff" : "#40ffffff"
                    visible: sddm.canReboot
                    Text { anchors.centerIn: parent; text: "↻"; font.pixelSize: 20; color: "white" }
                    MouseArea { 
                        id: rebootArea
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: sddm.reboot()
                        cursorShape: Qt.PointingHandCursor
                    }
                }

                Rectangle {
                    width: 40
                    height: 40
                    radius: 5
                    color: shutdownArea.containsMouse ? "#60ff4444" : "#40ffffff"
                    visible: sddm.canPowerOff
                    Text { anchors.centerIn: parent; text: "⏻"; font.pixelSize: 20; color: "white" }
                    MouseArea { 
                        id: shutdownArea
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: sddm.powerOff()
                        cursorShape: Qt.PointingHandCursor
                    }
                }
            }
        }
    }

    Loader {
        id: loginLoader
        anchors.centerIn: parent
        source: "Login.qml"
    }

    Rectangle {
        id: bottomBar
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        height: 40
        color: "#20000000"

        RowLayout {
            anchors.fill: parent
            anchors.margins: 10

            Text {
                text: Qt.formatDateTime(timeSource.currentDateTime, "dddd, MMMM d, yyyy")
                color: "white"
                font.pixelSize: 14
            }

            Item { Layout.fillWidth: true }

            Text {
                text: Qt.formatDateTime(timeSource.currentDateTime, "hh:mm:ss")
                color: "white"
                font.pixelSize: 14
                font.bold: true
            }
        }
    }

    Timer {
        id: timeSource
        property var currentDateTime: new Date()
        interval: 1000
        repeat: true
        running: true
        onTriggered: currentDateTime = new Date()
    }
}