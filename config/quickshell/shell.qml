//  Control Center — custom Quickshell control-center panel.
//  v2: live wifi/bt status, now-playing, click-outside dismiss, open animation.
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

ShellRoot {
    id: root

    // ---- live state ----
    property string wifiSsid: ""
    property string btDev: ""
    property string mediaText: ""
    property bool   mediaPlaying: false
    property bool   caffeineOn: false
    property bool   nightOn: false
    property bool   dndOn: false

    IpcHandler {
        target: "cc"
        function toggle(): void { panel.visible = !panel.visible }
        function show(): void   { panel.visible = true }
        function hide(): void   { panel.visible = false }
    }

    // ---- click-outside scrim (below the card, catches outside clicks) ----
    PanelWindow {
        id: scrim
        visible: panel.visible
        anchors { top: true; bottom: true; left: true; right: true }
        color: "transparent"
        exclusiveZone: 0
        WlrLayershell.layer: WlrLayer.Top
        MouseArea { anchors.fill: parent; onClicked: panel.visible = false }
    }

    // ---- the panel ----
    PanelWindow {
        id: panel
        visible: false
        anchors { top: true; right: true }
        margins { top: 6; right: 6 }
        implicitWidth: 350
        implicitHeight: card.implicitHeight
        color: "transparent"
        exclusiveZone: 0
        WlrLayershell.layer: WlrLayer.Overlay

        onVisibleChanged: {
            if (visible) {
                readVol.running = true; readBri.running = true
                refresh.restart()
                card.opacity = 1; slide.y = 0
            } else {
                card.opacity = 0; slide.y = -10
            }
        }

        Rectangle {
            id: card
            anchors.fill: parent
            radius: 16
            color: Qt.rgba(Theme.bg.r, Theme.bg.g, Theme.bg.b, 0.95)
            border.width: 1
            border.color: Qt.rgba(1, 1, 1, 0.06)
            implicitHeight: col.implicitHeight + 28

            opacity: 0
            transform: Translate { id: slide; y: -10 }
            Behavior on opacity { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }

            ColumnLayout {
                id: col
                anchors.fill: parent
                anchors.margins: 14
                spacing: 12

                // header + live wifi/bt status
                RowLayout {
                    Layout.fillWidth: true
                    Text {
                        text: "Control Center"
                        color: Theme.fg
                        font.pixelSize: 15
                        font.bold: true
                        font.family: "JetBrainsMono Nerd Font"
                        Layout.fillWidth: true
                    }
                    Text {
                        text: (root.wifiSsid ? "󰤨 " + root.wifiSsid : "󰤮")
                              + (root.btDev ? "   󰂱" : "")
                        color: Theme.dim
                        font.pixelSize: 11
                        font.family: "JetBrainsMono Nerd Font"
                    }
                }

                // now-playing (only when a player is active)
                Rectangle {
                    Layout.fillWidth: true
                    visible: root.mediaText.length > 0
                    implicitHeight: 46
                    radius: 12
                    color: Theme.surface
                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 12
                        anchors.rightMargin: 8
                        spacing: 6
                        Text {
                            Layout.fillWidth: true
                            text: root.mediaText
                            color: Theme.fg
                            elide: Text.ElideRight
                            font.pixelSize: 12
                            font.family: "JetBrainsMono Nerd Font"
                        }
                        MediaBtn { glyph: "󰒮"; onClicked: root.player("previous") }
                        MediaBtn { glyph: root.mediaPlaying ? "󰏤" : "󰐊"; onClicked: root.player("play-pause") }
                        MediaBtn { glyph: "󰒭"; onClicked: root.player("next") }
                    }
                }

                SliderRow {
                    id: volRow
                    icon: "󰕾"
                    onUserSet: (v) => Quickshell.execDetached(
                        ["sh", "-c", "wpctl set-volume @DEFAULT_AUDIO_SINK@ " + Math.round(v) + "%"])
                }
                SliderRow {
                    id: briRow
                    icon: "󰃠"
                    onUserSet: (v) => Quickshell.execDetached(
                        ["brightnessctl", "set", Math.round(v) + "%"])
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 10
                    PillButton { glyph: "󰤨"; label: "Wi-Fi";     onClicked: Quickshell.execDetached(["iwgtk"]) }
                    PillButton { glyph: "󰂯"; label: "Bluetooth"; onClicked: Quickshell.execDetached(["blueman-manager"]) }
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 10
                    PillButton {
                        glyph: root.caffeineOn ? "󰅶" : "󰾪"
                        label: "Caffeine"
                        active: root.caffeineOn
                        onClicked: { Quickshell.execDetached(["sh","-c","$HOME/.local/bin/caffeine-toggle"]); statePoll.restart() }
                    }
                    PillButton {
                        glyph: "󰖔"
                        label: "Night Light"
                        active: root.nightOn
                        onClicked: { Quickshell.execDetached(["sh","-c","$HOME/.local/bin/nightlight-toggle"]); statePoll.restart() }
                    }
                }
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 10
                    PillButton {
                        glyph: "󰂛"
                        label: "Do Not Disturb"
                        active: root.dndOn
                        onClicked: { Quickshell.execDetached(["swaync-client","-d"]); statePoll.restart() }
                    }
                    PillButton {
                        glyph: "󰄀"
                        label: "Screenshot"
                        onClicked: { panel.visible = false; Quickshell.execDetached(["sh","-c","sleep 0.3; grim -g \"$(slurp)\" - | swappy -f -"]) }
                    }
                }
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 10
                    PillButton { glyph: "󰌾"; label: "Lock";  onClicked: { panel.visible = false; Quickshell.execDetached(["hyprlock"]) } }
                    PillButton { glyph: "⏻"; label: "Power"; onClicked: { panel.visible = false; Quickshell.execDetached(["wlogout", "-b", "5", "-p", "layer-shell"]) } }
                }
            }
        }
    }

    function player(cmd) {
        Quickshell.execDetached(["playerctl", cmd])
        pollTimer.restart()   // refresh play/pause glyph shortly after
    }

    // ---- readers ----
    Process {
        id: readVol
        command: ["sh", "-c", "wpctl get-volume @DEFAULT_AUDIO_SINK@ | awk '{print $2*100}'"]
        stdout: StdioCollector { onStreamFinished: volRow.value = parseFloat(this.text) }
    }
    Process {
        id: readBri
        command: ["sh", "-c", "brightnessctl -m | cut -d, -f4 | tr -d '%'"]
        stdout: StdioCollector { onStreamFinished: briRow.value = parseFloat(this.text) }
    }
    Process {
        id: readWifi
        command: ["sh", "-c", "for d in /sys/class/net/wl*; do dev=${d##*/}; break; done; iwctl station \"$dev\" show 2>/dev/null | sed -n 's/.*Connected network[[:space:]]\\+\\(.*[^ ]\\)[[:space:]]*$/\\1/p'"]
        stdout: StdioCollector { onStreamFinished: root.wifiSsid = this.text.trim() }
    }
    Process {
        id: readBt
        command: ["sh", "-c", "bluetoothctl devices Connected 2>/dev/null | sed 's/^Device [0-9A-Fa-f:]* //' | paste -sd', ' -"]
        stdout: StdioCollector { onStreamFinished: root.btDev = this.text.trim() }
    }
    Process {
        id: readCaffeine
        command: ["sh", "-c", "test -f \"$XDG_RUNTIME_DIR/caffeine.on\" && echo on || echo off"]
        stdout: StdioCollector { onStreamFinished: root.caffeineOn = (this.text.trim() === "on") }
    }
    Process {
        id: readNight
        command: ["sh", "-c", "test -f \"$XDG_RUNTIME_DIR/nightlight.on\" && echo on || echo off"]
        stdout: StdioCollector { onStreamFinished: root.nightOn = (this.text.trim() === "on") }
    }
    Process {
        id: readDnd
        command: ["sh", "-c", "swaync-client -D 2>/dev/null"]
        stdout: StdioCollector { onStreamFinished: root.dndOn = (this.text.trim() === "true") }
    }
    Process {
        id: readMedia
        command: ["sh", "-c", "playerctl -f '{{status}}|{{artist}} — {{title}}' metadata 2>/dev/null"]
        stdout: StdioCollector {
            onStreamFinished: {
                var t = this.text.trim()
                if (!t) { root.mediaText = ""; root.mediaPlaying = false }
                else {
                    var i = t.indexOf("|")
                    root.mediaPlaying = t.substring(0, i) === "Playing"
                    root.mediaText = t.substring(i + 1)
                }
            }
        }
    }

    // periodic refresh while the panel is open
    Timer {
        id: refresh
        interval: 3000; repeat: true; running: panel.visible; triggeredOnStart: true
        onTriggered: { readWifi.running = true; readBt.running = true; readMedia.running = true; readCaffeine.running = true; readNight.running = true; readDnd.running = true }
    }
    // short one-shot after a media button press
    Timer { id: pollTimer; interval: 350; onTriggered: readMedia.running = true }
    // short one-shot after toggling a quick-setting (caffeine / night / dnd)
    Timer { id: statePoll; interval: 350; onTriggered: { readCaffeine.running = true; readNight.running = true; readDnd.running = true } }
}
