pragma Singleton
import Quickshell
import QtQuick

//  Shared palette. Baked to the current wallpaper accent for now;
//  wall-theme will regenerate this file on every wallpaper change.
Singleton {
    property color accent:   "#de8a73"
    property color bg:       "#171717"
    property color surface:  "#252525"
    property color surface2: "#363636"
    property color fg:       "#efebeb"
    property color dim:      "#bfb0b0"
}
