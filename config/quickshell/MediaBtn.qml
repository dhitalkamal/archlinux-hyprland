import QtQuick

//  compact icon button for the now-playing transport controls.
Rectangle {
    id: root
    property string glyph: ""
    signal clicked()

    implicitWidth: 30
    implicitHeight: 30
    radius: 8
    color: mouse.containsMouse ? Theme.surface2 : "transparent"

    Text {
        anchors.centerIn: parent
        text: root.glyph
        color: mouse.containsMouse ? Theme.accent : Theme.fg
        font.family: "JetBrainsMono Nerd Font"
        font.pixelSize: 15
    }
    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
