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
import QtQuick.Shapes
import "../services"
import "../"

// ClamAV drop-down (right notch, like battery): real-time protection switch,
// shield with status, system scan and the latest detections.

Item {
    id: root

    property real localScale: 1.0
    function s(v) { return Math.round(v * localScale) }

    readonly property int popupWidth:  s(420)
    readonly property int popupHeight: Math.round(Theme.notchHeight * localScale) + content.implicitHeight + s(24)

    Keys.onEscapePressed: SurfaceState.close()
    onOpacityChanged: if (opacity === 1) forceActiveFocus()

    readonly property var cs: ClamavService
    readonly property color protColor: !cs.enabled ? Theme.subtext
                                     : (cs.unseen || cs.scanState === "infected") ? Theme.error
                                     : Theme.active

    // Clock for "x min ago" and the scan timer
    property real now: Date.now()
    Timer { interval: 1000; repeat: true; running: root.visible; triggeredOnStart: true; onTriggered: root.now = Date.now() }

    function ago(ms) {
        if (!ms) return "—"
        var d = Math.max(0, (now - ms) / 1000)
        if (d < 60)    return "just now"
        if (d < 3600)  return Math.floor(d / 60) + " min ago"
        if (d < 86400) return Math.floor(d / 3600) + " h ago"
        return Math.floor(d / 86400) + " d ago"
    }
    function clock(ms) {
        var t = Math.max(0, Math.floor(ms / 1000))
        var h = Math.floor(t / 3600), m = Math.floor((t % 3600) / 60), sec = t % 60
        var mm = (m < 10 && h > 0 ? "0" : "") + m, ss = (sec < 10 ? "0" : "") + sec
        return h > 0 ? h + ":" + mm + ":" + ss : mm + ":" + ss
    }

    readonly property string statusText: {
        if (cs.busy)     return cs.enabled ? "Switching on…" : "Switching off…"
        if (!cs.enabled) return "Real-time protection is off"
        if (cs.unseen)   return "Threat detected"
        if (cs.scanning) return "Scanning your files…"
        return cs.monitoring ? "Watching ~/Downloads" : "Starting…"
    }

    MouseArea { anchors.fill: parent; z: -1; onClicked: Popups.clamavPinned = true }

    Column {
        id: content
        anchors { left: parent.left; right: parent.right; top: parent.top; margins: s(12) }
        spacing: s(10)

        // ── Header + switch ───────────────────────────────────────────────────
        Item {
            width: parent.width; height: s(34)
            Column {
                anchors.verticalCenter: parent.verticalCenter
                Text { text: "ClamAV"; color: Theme.text; font.pixelSize: s(15); font.weight: Font.Bold }
                Text {
                    text: root.statusText
                    color: Qt.rgba(root.protColor.r, root.protColor.g, root.protColor.b, 0.85)
                    font.pixelSize: s(10)
                }
            }
            Switch {
                anchors { right: parent.right; verticalCenter: parent.verticalCenter }
                checked: cs.enabled
                onToggled: { Popups.clamavPinned = true; cs.setEnabled(!cs.enabled) }
            }
        }

        // ── Hero: shield + stats ──────────────────────────────────────────────
        Rectangle {
            width: parent.width; height: s(150)
            radius: s(Theme.cornerRadius)
            color: Theme.card
            border.color: Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.06)
            clip: true

            Item {
                id: emblem
                width: s(126); height: width
                anchors { left: parent.left; leftMargin: s(14); verticalCenter: parent.verticalCenter }

                // Soft glow in the status colour, pulsing while active
                Shape {
                    anchors.fill: parent
                    preferredRendererType: Shape.CurveRenderer
                    opacity: cs.enabled ? glow.v : 0.25
                    ShapePath {
                        strokeColor: "transparent"
                        fillGradient: RadialGradient {
                            centerX: emblem.width / 2; centerY: emblem.height / 2
                            focalX: centerX; focalY: centerY
                            centerRadius: emblem.width / 2
                            GradientStop { position: 0.0; color: Qt.rgba(root.protColor.r, root.protColor.g, root.protColor.b, 0.28) }
                            GradientStop { position: 1.0; color: "transparent" }
                        }
                        PathAngleArc { centerX: emblem.width / 2; centerY: emblem.height / 2; radiusX: emblem.width / 2; radiusY: radiusX; startAngle: 0; sweepAngle: 360 }
                    }
                }
                QtObject {
                    id: glow
                    property real v: 0.6
                    property var anim: SequentialAnimation {
                        running: cs.enabled && root.visible; loops: Animation.Infinite
                        NumberAnimation { target: glow; property: "v"; to: 1.0;  duration: 1800; easing.type: Easing.InOutSine }
                        NumberAnimation { target: glow; property: "v"; to: 0.5; duration: 1800; easing.type: Easing.InOutSine }
                    }
                }

                // Thin ring; a radar sweep runs around it during a scan
                Rectangle {
                    anchors.fill: parent; anchors.margins: s(10)
                    radius: width / 2
                    color: "transparent"
                    border.width: s(2)
                    border.color: Qt.rgba(root.protColor.r, root.protColor.g, root.protColor.b, cs.enabled ? 0.35 : 0.15)
                }
                Shape {
                    id: sweep
                    anchors.fill: parent; anchors.margins: s(10)
                    preferredRendererType: Shape.CurveRenderer
                    visible: cs.scanning
                    RotationAnimation on rotation { running: cs.scanning && root.visible; loops: Animation.Infinite; from: 0; to: 360; duration: 1600 }
                    ShapePath {
                        strokeColor: root.protColor; strokeWidth: s(3); capStyle: ShapePath.RoundCap
                        fillColor: "transparent"
                        PathAngleArc { centerX: sweep.width / 2; centerY: sweep.height / 2; radiusX: sweep.width / 2 - s(1); radiusY: radiusX; startAngle: -90; sweepAngle: 70 }
                    }
                }

                Text {
                    anchors.centerIn: parent
                    text: !cs.enabled ? "󰦞" : (cs.unseen || cs.scanState === "infected") ? "󰻌" : cs.scanning ? "󰶚" : "󰕥"
                    color: root.protColor
                    font.pixelSize: s(46)
                    Behavior on color { ColorAnimation { duration: Anim.normal } }
                }
            }

            Column {
                anchors { left: emblem.right; leftMargin: s(14); right: parent.right; rightMargin: s(14); verticalCenter: parent.verticalCenter }
                spacing: s(9)
                Stat { icon: "󰉍"; label: "Real-time"; value: !cs.enabled ? "Off" : cs.monitoring ? "~/Downloads" : "Starting…" }
                Stat { icon: "󰪩"; label: "Signatures"; value: cs.sigVersion !== "" ? "daily " + cs.sigVersion : "—" }
                Stat { icon: "󰚰"; label: "Updated"; value: root.ago(cs.sigDate) }
                Stat {
                    icon: "󰅐"; label: "Last scan"
                    value: cs.scanning ? "running" : !cs.scanEnded ? "never (this session)"
                         : root.ago(cs.scanEnded) + (cs.scanState === "infected" ? " · threats" : cs.scanState === "clean" ? " · clean" : "")
                }
            }
        }

        // ── System scan ───────────────────────────────────────────────────────
        Label { text: "SYSTEM SCAN" }

        Rectangle {
            width: parent.width; height: s(84)
            radius: s(Theme.cornerRadius)
            color: Theme.card

            Column {
                anchors { left: parent.left; leftMargin: s(14); right: scanBtn.left; rightMargin: s(12); verticalCenter: parent.verticalCenter }
                spacing: s(4)
                Text {
                    width: parent.width; elide: Text.ElideRight
                    font.pixelSize: s(12); font.weight: Font.Medium; color: Theme.text
                    text: cs.scanning ? "Scanning · " + root.clock(root.now - cs.scanStarted)
                        : cs.scanState === "infected" ? cs.scanFound.length + " threat" + (cs.scanFound.length > 1 ? "s" : "") + " found"
                        : cs.scanState === "clean" ? "No threats found · " + root.clock(cs.scanEnded - cs.scanStarted)
                        : cs.scanState === "cancelled" ? "Scan cancelled"
                        : cs.scanState === "error" ? "Scan failed"
                        : "Home, /share and /data"
                }
                Text {
                    width: parent.width; elide: Text.ElideRight
                    font.pixelSize: s(10); color: Theme.subtext
                    text: cs.scanning ? (cs.scanFound.length > 0 ? cs.scanFound.length + " found so far" : "/home · /share · /data")
                        : cs.scanErrors > 0 && cs.scanState !== "" ? cs.scanErrors + " files could not be read"
                        : cs.enabled ? "Fast, multi-threaded via clamd" : "clamd is off: slower single scan"
                }
                // Indeterminate progress while scanning
                Item {
                    width: parent.width; height: s(4)
                    visible: cs.scanning
                    clip: true
                    Rectangle { anchors.fill: parent; radius: height / 2; color: Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.08) }
                    Rectangle {
                        id: bar
                        width: parent.width * 0.35; height: parent.height; radius: height / 2
                        gradient: Gradient {
                            orientation: Gradient.Horizontal
                            GradientStop { position: 0; color: "transparent" }
                            GradientStop { position: 1; color: root.protColor }
                        }
                        NumberAnimation on x {
                            running: cs.scanning && root.visible; loops: Animation.Infinite
                            from: -bar.width; to: bar.parent.width; duration: 1400; easing.type: Easing.InOutQuad
                        }
                    }
                }
            }

            Rectangle {
                id: scanBtn
                anchors { right: parent.right; rightMargin: s(14); verticalCenter: parent.verticalCenter }
                width: s(118); height: s(40); radius: height / 2
                color: cs.scanning ? (scanHov.hovered ? Theme.cardHover : Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.06)) : "transparent"
                gradient: cs.scanning ? null : grad
                Gradient {
                    id: grad
                    orientation: Gradient.Horizontal
                    GradientStop { position: 0; color: Qt.darker(Theme.active, 1.6) }
                    GradientStop { position: 1; color: Theme.active }
                }
                scale: scanHov.pressed ? 0.96 : 1
                Behavior on scale { NumberAnimation { duration: Anim.fast } }
                Row {
                    anchors.centerIn: parent; spacing: s(7)
                    Text {
                        text: cs.scanning ? "󰜺" : "󱉶"
                        font.pixelSize: s(15); anchors.verticalCenter: parent.verticalCenter
                        color: cs.scanning ? Theme.text : Theme.background
                    }
                    Text {
                        text: cs.scanning ? "Cancel" : "Scan now"
                        font.pixelSize: s(12); font.weight: Font.Bold; anchors.verticalCenter: parent.verticalCenter
                        color: cs.scanning ? Theme.text : Theme.background
                    }
                }
                HoverHandler { id: scanHov; cursorShape: Qt.PointingHandCursor; property bool pressed: scanMa.pressed }
                MouseArea {
                    id: scanMa
                    anchors.fill: parent
                    onClicked: { Popups.clamavPinned = true; cs.scanning ? cs.cancelScan() : cs.startScan() }
                }
            }
        }

        // ── Detections ────────────────────────────────────────────────────────
        Label { text: "DETECTIONS" }

        Rectangle {
            width: parent.width
            height: cs.detections.length === 0 ? s(52) : detList.implicitHeight + s(12)
            radius: s(Theme.cornerRadius)
            color: Theme.card

            Row {
                visible: cs.detections.length === 0
                anchors.centerIn: parent; spacing: s(8)
                Text { text: "󰄬"; font.pixelSize: s(14); color: Theme.active; anchors.verticalCenter: parent.verticalCenter }
                Text { text: "No threats detected"; font.pixelSize: s(11); color: Theme.subtext; anchors.verticalCenter: parent.verticalCenter }
            }

            Column {
                id: detList
                visible: cs.detections.length > 0
                anchors { left: parent.left; right: parent.right; top: parent.top; margins: s(6) }
                Repeater {
                    model: cs.detections.slice(0, 4)
                    delegate: Item {
                        required property var modelData
                        width: detList.width; height: s(44)
                        Rectangle {
                            id: dot
                            width: s(28); height: width; radius: width / 2
                            anchors { left: parent.left; leftMargin: s(6); verticalCenter: parent.verticalCenter }
                            color: Qt.rgba(Theme.error.r, Theme.error.g, Theme.error.b, 0.15)
                            Text { anchors.centerIn: parent; text: "󱎶"; font.pixelSize: s(14); color: Theme.error }
                        }
                        Column {
                            anchors { left: dot.right; leftMargin: s(10); right: when.left; rightMargin: s(8); verticalCenter: parent.verticalCenter }
                            Text { width: parent.width; elide: Text.ElideRight; text: modelData.name; font.pixelSize: s(12); font.weight: Font.Medium; color: Theme.text }
                            Text { width: parent.width; elide: Text.ElideMiddle; text: modelData.path; font.pixelSize: s(10); color: Theme.subtext }
                        }
                        Column {
                            id: when
                            anchors { right: parent.right; rightMargin: s(6); verticalCenter: parent.verticalCenter }
                            Text { anchors.right: parent.right; text: root.ago(modelData.time); font.pixelSize: s(10); color: Theme.subtext }
                            Text { anchors.right: parent.right; text: modelData.source; font.pixelSize: s(9); color: Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.3) }
                        }
                    }
                }
            }
        }
    }

    // ── Components ────────────────────────────────────────────────────────────
    component Label: Text {
        font.pixelSize: root.s(9); font.weight: Font.Bold; font.letterSpacing: 1.2
        color: Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.3)
    }

    component Stat: Row {
        property string icon
        property string label
        property string value
        spacing: root.s(8)
        Text {
            anchors.verticalCenter: parent.verticalCenter
            width: root.s(16)
            text: parent.icon; font.pixelSize: root.s(13)
            color: Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.45)
        }
        Column {
            Text { text: parent.parent.label; font.pixelSize: root.s(9); color: Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.45) }
            Text { text: parent.parent.value; font.pixelSize: root.s(12); font.weight: Font.Medium; color: Theme.text }
        }
    }

    component Switch: Rectangle {
        id: sw
        property bool checked: false
        signal toggled()
        width: root.s(44); height: root.s(24); radius: height / 2
        color: checked ? (swHov.hovered ? Qt.lighter(Theme.active, 1.1) : Theme.active)
                       : Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, swHov.hovered ? 0.15 : 0.1)
        border.color: checked ? Qt.darker(Theme.active, 1.2) : Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.2)
        border.width: 1
        opacity: cs.busy ? 0.6 : 1
        Behavior on color { ColorAnimation { duration: Anim.fast } }
        Rectangle {
            width: root.s(18); height: width; radius: width / 2
            anchors.verticalCenter: parent.verticalCenter
            x: sw.checked ? sw.width - width - root.s(3) : root.s(3)
            color: "white"
            Behavior on x { NumberAnimation { duration: Anim.fast; easing.type: Easing.OutBack } }
        }
        HoverHandler { id: swHov; cursorShape: Qt.PointingHandCursor }
        MouseArea { anchors.fill: parent; enabled: !cs.busy; onClicked: sw.toggled() }
    }
}
