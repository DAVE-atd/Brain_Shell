/*
 * Brain Shell
 * Copyright (C) 2026 Venkat Saahit Kamu (Brainitech)
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Affero General Public License as published
 * by the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Affero General Public License for more details.
 *
 * You should have received a copy of the GNU Affero General Public License
 * along with this program.  If not, see <https://www.gnu.org/licenses/>.
 */

import QtQuick
import QtQuick.Effects
import Quickshell
import "../"

// LockSurface — visuals of the lock screen (one per screen).
// Blurred, darkened wallpaper; clock in the upper part; password dots centred;
// power button bottom-left with a suspend / reboot / shut down menu.

Item {
    id: root
    required property var ctx

    readonly property color fg: "#f2f2f5"

    // Fade in on show
    // Fade in once the wallpaper is decoded (no black flash)
    opacity: wall.status === Image.Ready || wall.status === Image.Error ? 1 : 0
    Behavior on opacity { NumberAnimation { duration: 350; easing.type: Easing.OutCubic } }

    // ── Background ────────────────────────────────────────────────────────────
    Image {
        id: wall
        anchors.fill: parent
        source: "file://" + Quickshell.env("HOME") + "/.curr_wall_static.jpg"
        fillMode: Image.PreserveAspectCrop
        sourceSize: Qt.size(root.width, root.height)   // decode at screen size, not 4K
        cache: false
        asynchronous: false
        visible: false
    }
    MultiEffect {
        anchors.fill: parent
        source: wall
        autoPaddingEnabled: false
        blurEnabled: true
        blur: 1.0
        blurMax: 48
        blurMultiplier: 0.6
    }
    // Darken like the reference (an overlay keeps the colours, brightness crushes them to black)
    Rectangle { anchors.fill: parent; color: "#000000"; opacity: 0.28 }

    // ── Clock ─────────────────────────────────────────────────────────────────
    property date now: new Date()
    Timer { interval: 1000; running: true; repeat: true; triggeredOnStart: true; onTriggered: root.now = new Date() }

    Text {
        id: clock
        anchors.horizontalCenter: parent.horizontalCenter
        y: Math.round(parent.height * 0.19)
        text: Qt.formatTime(root.now, "HH:mm")
        color: root.fg
        font.family: "Inter Display"
        font.weight: Font.Bold
        font.pixelSize: Math.round(parent.height * 0.047)
        font.letterSpacing: Math.round(parent.height * 0.007)
        layer.enabled: true
        layer.effect: MultiEffect { shadowEnabled: true; shadowColor: "#80000000"; shadowBlur: 0.6; shadowVerticalOffset: 2 }
    }

    // ── Password ──────────────────────────────────────────────────────────────
    TextInput {
        id: input
        width: 0; height: 0; opacity: 0
        focus: true
        echoMode: TextInput.Password
        text: root.ctx.password
        onTextChanged: if (text !== root.ctx.password) root.ctx.password = text
        enabled: !root.ctx.busy
        Keys.onReturnPressed: root.ctx.submit()
        Keys.onEnterPressed: root.ctx.submit()
        Keys.onEscapePressed: {
            if (root.ctx.menuOpen) root.ctx.menuOpen = false
            else if (root.ctx.password !== "") root.ctx.password = ""
            else if (root.ctx.preview) root.ctx.preview = false
        }
        Component.onCompleted: forceActiveFocus()
    }

    Item {
        id: dotsBox
        anchors.centerIn: parent
        width: dots.width; height: 14

        property bool failed: false
        Connections {
            target: root.ctx
            function onFailCountChanged() { dotsBox.failed = true; shake.restart(); failReset.restart() }
        }
        Timer { id: failReset; interval: 900; onTriggered: dotsBox.failed = false }

        SequentialAnimation {
            id: shake
            loops: 1
            NumberAnimation { target: dots; property: "x"; to: -14; duration: 50 }
            NumberAnimation { target: dots; property: "x"; to:  12; duration: 70 }
            NumberAnimation { target: dots; property: "x"; to:  -8; duration: 70 }
            NumberAnimation { target: dots; property: "x"; to:   4; duration: 60 }
            NumberAnimation { target: dots; property: "x"; to:   0; duration: 50 }
        }

        // Fixed pool of slots: a slot grows/shrinks in width, so adding or deleting a
        // character glides (the row stays centred and slides instead of jumping)
        Row {
            id: dots
            anchors.verticalCenter: parent.verticalCenter
            Repeater {
                model: 32
                delegate: Item {
                    id: slot
                    required property int index
                    readonly property bool shown: index < root.ctx.password.length
                    width: shown ? 23 : 0
                    height: 14
                    Behavior on width { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }

                    Rectangle {
                        anchors.centerIn: parent
                        width: 11; height: 11; radius: 5.5
                        color: dotsBox.failed ? "#f87171" : root.fg
                        Behavior on color { ColorAnimation { duration: 180 } }
                        opacity: slot.shown ? (root.ctx.busy ? pulse.value : 1) : 0
                        scale: slot.shown ? 1 : 0.2
                        Behavior on opacity { NumberAnimation { duration: 180; easing.type: Easing.OutQuad } }
                        Behavior on scale   { NumberAnimation { duration: 260; easing.type: Easing.OutBack; easing.overshoot: 1.6 } }
                    }
                }
            }
        }
        // Failure flash stays visible even though the password was cleared
        Text {
            anchors.centerIn: parent
            visible: dotsBox.failed && root.ctx.password.length === 0
            text: "Wrong password"
            color: "#f87171"
            font.family: "Inter"
            font.pixelSize: 14
        }
    }

    QtObject {
        id: pulse
        property real value: 1
        property var anim: SequentialAnimation {
            running: root.ctx.busy; loops: Animation.Infinite
            NumberAnimation { target: pulse; property: "value"; to: 0.35; duration: 450 }
            NumberAnimation { target: pulse; property: "value"; to: 1.0;  duration: 450 }
        }
    }

    // Clicking anywhere closes the menu and keeps keyboard focus on the input
    MouseArea {
        anchors.fill: parent
        z: -1
        onClicked: { root.ctx.menuOpen = false; input.forceActiveFocus() }
    }

    // ── Power button + menu ───────────────────────────────────────────────────
    Rectangle {
        id: powerBtn
        width: 56; height: 56; radius: 14
        anchors { left: parent.left; bottom: parent.bottom; leftMargin: 12; bottomMargin: 18 }
        color: powerHov.hovered || root.ctx.menuOpen ? Qt.rgba(0.36, 0.41, 0.52, 0.75) : Qt.rgba(0.27, 0.32, 0.41, 0.55)
        Behavior on color { ColorAnimation { duration: 150 } }
        Text {
            anchors.centerIn: parent
            text: "󰐥"
            color: root.fg
            font.pixelSize: 18
        }
        HoverHandler { id: powerHov; cursorShape: Qt.PointingHandCursor }
        MouseArea { anchors.fill: parent; onClicked: { root.ctx.menuOpen = !root.ctx.menuOpen; input.forceActiveFocus() } }
    }

    Rectangle {
        id: menu
        anchors { left: powerBtn.left; bottom: powerBtn.top; bottomMargin: 10 }
        width: 190
        height: menuCol.implicitHeight + 12
        radius: 16
        color: Qt.rgba(0.11, 0.13, 0.17, 0.82)
        border.color: Qt.rgba(1, 1, 1, 0.08)

        opacity: root.ctx.menuOpen ? 1 : 0
        scale: root.ctx.menuOpen ? 1 : 0.92
        transformOrigin: Item.BottomLeft
        visible: opacity > 0
        Behavior on opacity { NumberAnimation { duration: 160 } }
        Behavior on scale   { NumberAnimation { duration: 200; easing.type: Easing.OutBack } }

        Column {
            id: menuCol
            anchors { left: parent.left; right: parent.right; top: parent.top; margins: 6 }
            spacing: 2
            Repeater {
                model: [
                    { icon: "󰤄", label: "Suspend",   action: "suspend"  },
                    { icon: "󰜉", label: "Reboot",    action: "reboot"   },
                    { icon: "󰐥", label: "Shut down", action: "poweroff" }
                ]
                delegate: Rectangle {
                    required property var modelData
                    width: menuCol.width; height: 42; radius: 11
                    color: itemHov.hovered ? Qt.rgba(1, 1, 1, 0.09) : "transparent"
                    Behavior on color { ColorAnimation { duration: 120 } }
                    Row {
                        anchors { left: parent.left; leftMargin: 14; verticalCenter: parent.verticalCenter }
                        spacing: 14
                        Text { text: modelData.icon; color: modelData.action === "poweroff" ? "#f87171" : root.fg; font.pixelSize: 17; anchors.verticalCenter: parent.verticalCenter }
                        Text { text: modelData.label; color: root.fg; font.family: "Inter"; font.pixelSize: 14; anchors.verticalCenter: parent.verticalCenter }
                    }
                    HoverHandler { id: itemHov; cursorShape: Qt.PointingHandCursor }
                    MouseArea { anchors.fill: parent; onClicked: root.ctx.power(modelData.action) }
                }
            }
        }
    }
}
