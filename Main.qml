/*
 * Bleach SDDM Theme
 * Copyright (C) 2024 Fishson
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

    TextConstants { id: textConstants }

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

    Rectangle {
        id: loginContainer
        anchors.centerIn: parent
        width: 400
        height: 480
        radius: 15
        color: "#80000000"
        border.color: "#40ffffff"
        border.width: 1

        property string currentUserName: userModel.lastUser
        property string currentUserIcon: ""

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 40
            spacing: 20

            Item {
                Layout.alignment: Qt.AlignHCenter
                width: 120
                height: 120

                Rectangle {
                    id: avatarContainer
                    anchors.fill: parent
                    radius: 60
                    color: "#40ffffff"
                    border.color: "#60ffffff"
                    border.width: 2
                    clip: true

                    Image {
                        id: avatar
                        anchors.fill: parent
                        anchors.margins: 2
                        source: {
                            var icon = loginContainer.currentUserIcon
                            if (!icon || icon === "") {
                                return ""
                            }
                            if (icon.indexOf("file://") !== 0 && icon.indexOf("/") === 0) {
                                return "file://" + icon
                            }
                            return icon
                        }
                        fillMode: Image.PreserveAspectCrop
                        visible: status === Image.Ready
                        asynchronous: true
                        cache: false
                        layer.enabled: true
                        layer.effect: OpacityMask {
                            maskSource: Rectangle {
                                width: avatar.width
                                height: avatar.height
                                radius: width / 2
                            }
                        }
                        
                        onStatusChanged: {
                            if (status === Image.Error) {
                                console.log("Failed to load avatar:", source)
                            }
                        }
                    }

                    Text {
                        anchors.centerIn: parent
                        text: "👤"
                        font.pixelSize: 60
                        color: "white"
                        visible: avatar.status !== Image.Ready
                    }
                }
            }

            Text {
                id: usernameText
                Layout.alignment: Qt.AlignHCenter
                text: loginContainer.currentUserName || "User"
                font.pixelSize: 24
                font.bold: true
                color: "white"
            }

            QQC2.ComboBox {
                id: userSelect
                Layout.fillWidth: true
                visible: userModel.count > 1
                model: userModel
                currentIndex: userModel.lastIndex >= 0 ? userModel.lastIndex : 0
                textRole: "name"

                delegate: QQC2.ItemDelegate {
                    width: parent.width
                    text: model.name
                }

                onCurrentIndexChanged: {
                    loginContainer.currentUserName = userModel.data(userSelect.currentIndex, "name")
                    loginContainer.currentUserIcon = userModel.data(userSelect.currentIndex, "icon")
                }
            }

            Item { height: 10 }

            Rectangle {
                id: passwordFieldBox
                Layout.fillWidth: true
                height: 40
                radius: 5
                color: "#40ffffff"
                border.color: passwordField.activeFocus ? "#80ffffff" : "#60ffffff"
                border.width: 1

                TextInput {
                    id: passwordField
                    anchors.fill: parent
                    anchors.margins: 8
                    font.pixelSize: 16
                    color: "white"
                    echoMode: TextInput.Password
                    focus: true
                    clip: true
                    verticalAlignment: TextInput.AlignVCenter

                    onAccepted: loginButton.doLogin()
                }

                Text {
                    id: placeholder
                    anchors.fill: parent
                    anchors.margins: 8
                    text: textConstants.password || "Password"
                    color: "#a0ffffff"
                    font.pixelSize: 16
                    verticalAlignment: Text.AlignVCenter
                    visible: passwordField.text.length === 0 && !passwordField.activeFocus
                }
            }

            Rectangle {
                id: loginButton
                Layout.fillWidth: true
                Layout.preferredHeight: 50
                radius: 5
                color: loginButtonArea.containsMouse ? "#ff7700" : (loginButtonArea.pressed ? "#ff6600" : "#ff8c00")

                function doLogin() {
                    var username = loginContainer.currentUserName
                    var password = passwordField.text
                    var session = sessionSelect.currentIndex
                    
                    if (username !== "" && password !== "") {
                        sddm.login(username, password, session)
                    }
                }

                Text {
                    anchors.centerIn: parent
                    text: textConstants.login || "Login"
                    font.pixelSize: 18
                    font.bold: true
                    color: "white"
                }

                MouseArea {
                    id: loginButtonArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: parent.doLogin()
                }
            }

            Text {
                id: errorMessage
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignHCenter
                text: ""
                color: "#ff4444"
                font.pixelSize: 14
                wrapMode: Text.WordWrap
                horizontalAlignment: Text.AlignHCenter
                visible: text !== ""
            }
        }
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

    Connections {
        target: sddm
        function onLoginFailed() {
            errorMessage.text = textConstants.loginFailed || "Login failed. Please try again."
            passwordField.text = ""
            passwordField.forceActiveFocus()
        }
        
        function onLoginSucceeded() {
            errorMessage.text = ""
        }
    }

    Component.onCompleted: {
        if (userModel.lastIndex >= 0) {
            loginContainer.currentUserName = userModel.data(userModel.lastIndex, "name")
            loginContainer.currentUserIcon = userModel.data(userModel.lastIndex, "icon")
            userSelect.currentIndex = userModel.lastIndex
        }
        passwordField.forceActiveFocus()
    }
}