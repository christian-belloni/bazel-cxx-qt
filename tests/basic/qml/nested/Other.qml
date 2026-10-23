import QtQuick

Text {
    id: rootText
    elide: Text.ElideRight
    

    MouseArea {
        id: hoverArea
        anchors.fill: parent
        acceptedButtons: Qt.NoButton
    }
}
