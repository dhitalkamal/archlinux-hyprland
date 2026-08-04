import QtQuick
import QtQuick.Layouts

//  icon + draggable track + percent. Emits userSet(v) only on drag.
RowLayout {
    id: root
    property string icon: ""
    property real value: 50
    signal userSet(real v)

    Layout.fillWidth: true
    spacing: 10

    Text {
        text: root.icon
        color: Theme.accent
        font.family: "JetBrainsMono Nerd Font"
        font.pixelSize: 16
        Layout.preferredWidth: 20
        horizontalAlignment: Text.AlignHCenter
    }

    Rectangle {
        id: track
        Layout.fillWidth: true
        implicitHeight: 8
        radius: 4
        color: Theme.surface2

        Rectangle {                       // filled portion
            width: parent.width * (root.value / 100)
            height: parent.height
            radius: 4
            color: Theme.accent
        }
        Rectangle {                       // handle
            width: 16; height: 16; radius: 8
            color: Theme.fg
            border.width: 2
            border.color: Theme.accent
            y: (parent.height - height) / 2
            x: Math.max(0, Math.min(parent.width - width,
                        parent.width * (root.value / 100) - width / 2))
        }
        MouseArea {
            anchors.fill: parent
            onPressed: (m) => root.setFromPx(m.x)
            onPositionChanged: (m) => root.setFromPx(m.x)
        }
    }

    Text {
        text: Math.round(root.value) + "%"
        color: Theme.dim
        font.family: "JetBrainsMono Nerd Font"
        font.pixelSize: 12
        Layout.preferredWidth: 40
        horizontalAlignment: Text.AlignRight
    }

    function setFromPx(px) {
        var v = Math.max(0, Math.min(100, px / track.width * 100))
        root.value = v
        root.userSet(v)
    }
}
