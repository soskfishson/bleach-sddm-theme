import QtQuick 6.0
import QtQuick.Layouts 6.0
import QtQuick.Controls 6.0 as QQC2
import Qt5Compat.GraphicalEffects

import SddmComponents 2.0

Rectangle {
    id: loginRoot
    width: 400
    height: 480
    radius: 15
    color: "#80000000"
    border.color: "#40ffffff"
    border.width: 1

    TextConstants { id: textConstants }

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
                        var icon = loginRoot.currentUserIcon
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
            text: loginRoot.currentUserName || "User" 
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
                loginRoot.currentUserName = userModel.data(userSelect.currentIndex, "name") 
                loginRoot.currentUserIcon = userModel.data(userSelect.currentIndex, "icon") 
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
                var username = loginRoot.currentUserName
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
            loginRoot.currentUserName = userModel.data(userModel.lastIndex, "name") 
            loginRoot.currentUserIcon = userModel.data(userModel.lastIndex, "icon")
            userSelect.currentIndex = userModel.lastIndex
        }
        passwordField.forceActiveFocus()
    }
}