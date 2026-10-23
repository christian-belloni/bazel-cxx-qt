import QtQuick
import QtQuick.Controls
import QtQuick.Window
import basic

import ui
import components

ApplicationWindow {
    id: root
    height: 480
    title: qsTr("Hello World")
    visible: true
    width: 640

    Button {
        anchors.centerIn: parent
        text: "Hello World!"
        onClicked: Backend.say_hello()
    }
    Other {
      text: "<b>Hello</b> <i>World!</i>"
    }
}
