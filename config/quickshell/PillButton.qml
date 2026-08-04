import QtQuick
import QtQuick.Layouts

//  rounded action button: glyph + label, hover highlight.
Rectangle {
    id: root
    property string glyph: ""
    property string label: ""
    property bool active: false          // toggled-on state (accent-tinted)
    signal clicked()

    Layout.fillWidth: true
    implicitHeight: 44
    radius: 12
    color: root.active ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.18)
                       : (mouse.containsMouse ? Theme.surface2 : Theme.surface)
    border.width: 1
    border.color: root.active ? Theme.accent : Qt.rgba(1, 1, 1, 0.05)

    RowLayout {
        anchors.centerIn: parent
        spacing: 8
        Text {
            text: root.glyph
            color: Theme.accent
            font.family: "JetBrainsMono Nerd Font"
            font.pixelSize: 16
        }
        Text {
            text: root.label
            color: root.active ? Theme.accent : Theme.fg
            font.family: "JetBrainsMono Nerd Font"
            font.pixelSize: 12
        }
    }
    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
