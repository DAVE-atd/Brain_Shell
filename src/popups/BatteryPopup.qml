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
import Quickshell.Io
import Quickshell.Services.UPower
import "../components"
import "../"

// Battery drop-down (right notch, like the network popup): a charge ring with
// an orbiting spark while charging, time left, power draw, health and the
// power-profiles-daemon profile.

Item {
    id: root

    property real localScale: 1.0
    readonly property int popupWidth:  Math.round(400 * localScale)
    readonly property int popupHeight: Math.round(372 * localScale)

    Keys.onEscapePressed: SurfaceState.close()
    onOpacityChanged: if (opacity === 1) forceActiveFocus()

    // ── Data ──────────────────────────────────────────────────────────────────
    readonly property var  bat: UPower.displayDevice
    // The real battery (health lives there, not on the aggregate device)
    readonly property var  cell: {
        var list = UPower.devices.values
        for (var i = 0; i < list.length; i++) if (list[i].isLaptopBattery) return list[i]
        return null
    }
    readonly property real pct:      bat.ready ? bat.percentage : 0
    readonly property bool charging: bat.state === UPowerDeviceState.Charging || bat.state === UPowerDeviceState.PendingCharge
    readonly property bool full:     bat.state === UPowerDeviceState.FullyCharged
    readonly property real watts:    Math.abs(bat.changeRate || 0)

    readonly property color levelColor: {
        if (charging || full) return "#a6e3a1"
        if (pct <= 0.10) return Theme.error
        if (pct <= 0.20) return "#fab387"
        if (pct <= 0.30) return "#f9e2af"
        return Theme.active
    }

    function _dur(s) {
        if (!s || s <= 0) return ""
        var h = Math.floor(s / 3600), m = Math.round((s % 3600) / 60)
        if (m === 60) { h++; m = 0 }
        return h > 0 ? h + " h " + m + " min" : m + " min"
    }
    readonly property string statusText: {
        if (!bat.ready)  return "No battery"
        if (full)        return "Fully charged"
        if (charging)    return bat.timeToFull > 0 ? "Full in " + _dur(bat.timeToFull) : "Charging"
        if (bat.state === UPowerDeviceState.PendingCharge) return "Plugged in, not charging"
        return bat.timeToEmpty > 0 ? _dur(bat.timeToEmpty) + " left" : "On battery"
    }

    // Cycle count is not exported by UPower
    property int cycles: -1
    Process {
        id: cycleProc
        command: ["sh", "-c", "cat /sys/class/power_supply/BAT*/cycle_count 2>/dev/null | head -1"]
        stdout: StdioCollector { onStreamFinished: { var n = parseInt(text); root.cycles = isNaN(n) ? -1 : n } }
    }
    onVisibleChanged: if (visible) cycleProc.running = true

    MouseArea { anchors.fill: parent; z: -1; onClicked: Popups.batteryPinned = true }

    Column {
        anchors { fill: parent; margins: Math.round(12 * localScale) }
        spacing: Math.round(10 * localScale)

        // ── Header ────────────────────────────────────────────────────────────
        Item {
            width: parent.width; height: Math.round(34 * localScale)
            Column {
                anchors.verticalCenter: parent.verticalCenter
                Text { text: "Battery"; color: Theme.text; font.pixelSize: Math.round(15 * localScale); font.weight: Font.Bold }
                Text {
                    text: root.statusText
                    color: Qt.rgba(root.levelColor.r, root.levelColor.g, root.levelColor.b, 0.85)
                    font.pixelSize: Math.round(10 * localScale)
                }
            }
        }

        // ── Hero: ring + stats ────────────────────────────────────────────────
        Rectangle {
            width: parent.width; height: Math.round(176 * localScale)
            radius: Math.round(Theme.cornerRadius * localScale)
            color: Theme.card
            border.color: Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.06)
            clip: true

            Item {
                id: ringBox
                width: Math.round(148 * localScale); height: width
                anchors { left: parent.left; leftMargin: Math.round(14 * localScale); verticalCenter: parent.verticalCenter }

                // Soft glow behind the ring, in the level colour
                Shape {
                    anchors.fill: parent
                    preferredRendererType: Shape.CurveRenderer
                    opacity: root.charging ? glowPulse.v : 0.55
                    ShapePath {
                        strokeColor: "transparent"
                        fillGradient: RadialGradient {
                            centerX: ringBox.width / 2; centerY: ringBox.height / 2
                            focalX: centerX; focalY: centerY
                            centerRadius: ringBox.width / 2
                            GradientStop { position: 0.0; color: Qt.rgba(root.levelColor.r, root.levelColor.g, root.levelColor.b, 0.22) }
                            GradientStop { position: 1.0; color: "transparent" }
                        }
                        PathAngleArc { centerX: ringBox.width / 2; centerY: ringBox.height / 2; radiusX: ringBox.width / 2; radiusY: radiusX; startAngle: 0; sweepAngle: 360 }
                    }
                }
                QtObject {
                    id: glowPulse
                    property real v: 0.55
                    property var anim: SequentialAnimation {
                        running: root.charging && root.visible; loops: Animation.Infinite
                        NumberAnimation { target: glowPulse; property: "v"; to: 1.0;  duration: 1400; easing.type: Easing.InOutSine }
                        NumberAnimation { target: glowPulse; property: "v"; to: 0.45; duration: 1400; easing.type: Easing.InOutSine }
                    }
                }

                Ring {
                    id: ring
                    anchors.fill: parent
                    anchors.margins: Math.round(10 * localScale)
                    value: root.pct
                    gap: 70
                    thickness: Math.round(9 * localScale)
                    color: root.levelColor
                    duration: 900
                }

                // Spark travelling along the ring while charging
                Item {
                    anchors.fill: ring
                    visible: root.charging
                    rotation: ring.start + 90
                    RotationAnimation on rotation {
                        running: root.charging && root.visible; loops: Animation.Infinite
                        from: ring.start + 90; to: ring.start + 90 + ring.span * Math.max(0.05, root.pct)
                        duration: 2200; easing.type: Easing.InOutQuad
                    }
                    Rectangle {
                        width: Math.round(7 * localScale); height: width; radius: width / 2
                        x: (parent.width - width) / 2; y: ring.thickness / 2 - height / 2
                        color: "white"; opacity: 0.9
                    }
                }

                Column {
                    anchors.centerIn: parent
                    spacing: Math.round(2 * localScale)
                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: Math.round(root.pct * 100) + "%"
                        color: Theme.text
                        font.pixelSize: Math.round(28 * localScale); font.weight: Font.Bold
                    }
                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: root.full ? "󰂄" : root.charging ? "󱐋" : "󰁹"
                        color: root.levelColor
                        font.pixelSize: Math.round(14 * localScale)
                    }
                }
            }

            Column {
                anchors { left: ringBox.right; leftMargin: Math.round(14 * localScale); right: parent.right; rightMargin: Math.round(14 * localScale); verticalCenter: parent.verticalCenter }
                spacing: Math.round(10 * localScale)

                Stat { icon: "󱐋"; label: root.charging ? "Charging at" : "Power draw"; value: root.watts > 0.05 ? root.watts.toFixed(1) + " W" : "—" }
                Stat {
                    icon: "󰁹"; label: "Energy"
                    value: bat.energyCapacity > 0 ? bat.energy.toFixed(1) + " / " + bat.energyCapacity.toFixed(1) + " Wh" : "—"
                }
                Stat {
                    icon: "󰣐"; label: "Health"
                    value: root.cell && root.cell.healthSupported ? Math.round(root.cell.healthPercentage) + " %" : "—"
                }
                Stat { icon: "󰑓"; label: "Cycles"; value: root.cycles >= 0 ? root.cycles : "—" }
            }
        }

        // ── Power profile ─────────────────────────────────────────────────────
        Text {
            text: "POWER PROFILE"
            font.pixelSize: Math.round(9 * localScale); font.weight: Font.Bold; font.letterSpacing: 1.2
            color: Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.3)
        }

        Rectangle {
            id: seg
            width: parent.width; height: Math.round(58 * localScale)
            radius: Math.round(Theme.cornerRadius * localScale)
            color: Theme.card

            readonly property var options: {
                var o = [
                    { key: PowerProfile.PowerSaver,  icon: "󰌪", label: "Saver" },
                    { key: PowerProfile.Balanced,    icon: "󰾅", label: "Balanced" }
                ]
                if (PowerProfiles.hasPerformanceProfile) o.push({ key: PowerProfile.Performance, icon: "󰓅", label: "Performance" })
                return o
            }
            readonly property int current: {
                for (var i = 0; i < options.length; i++) if (options[i].key === PowerProfiles.profile) return i
                return 1
            }
            readonly property real slot: (width - Math.round(8 * localScale)) / options.length

            // Sliding highlight
            Rectangle {
                x: Math.round(4 * localScale) + seg.current * seg.slot
                y: Math.round(4 * localScale)
                width: seg.slot; height: seg.height - Math.round(8 * localScale)
                radius: Math.round((Theme.cornerRadius - 3) * localScale)
                color: Qt.rgba(Theme.active.r, Theme.active.g, Theme.active.b, 0.18)
                border.color: Qt.rgba(Theme.active.r, Theme.active.g, Theme.active.b, 0.45)
                Behavior on x { NumberAnimation { duration: Anim.slow; easing.type: Easing.OutBack; easing.overshoot: 1.1 } }
            }

            Row {
                x: Math.round(4 * localScale); anchors.verticalCenter: parent.verticalCenter
                Repeater {
                    model: seg.options
                    delegate: Item {
                        required property var modelData
                        required property int index
                        readonly property bool sel: index === seg.current
                        width: seg.slot; height: seg.height - Math.round(8 * localScale)
                        Column {
                            anchors.centerIn: parent
                            spacing: Math.round(2 * localScale)
                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: modelData.icon; font.pixelSize: Math.round(16 * localScale)
                                color: parent.parent.sel ? Theme.active : Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.5)
                                Behavior on color { ColorAnimation { duration: Anim.normal } }
                            }
                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: modelData.label; font.pixelSize: Math.round(10 * localScale); font.weight: Font.Medium
                                color: parent.parent.sel ? Theme.text : Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.5)
                            }
                        }
                        HoverHandler { cursorShape: Qt.PointingHandCursor }
                        MouseArea { anchors.fill: parent; onClicked: { Popups.batteryPinned = true; PowerProfiles.profile = modelData.key } }
                    }
                }
            }
        }

        Text {
            // 0 = none; the enum itself is not exported to QML
            visible: PowerProfiles.profile === PowerProfile.Performance && PowerProfiles.degradationReason !== 0
            text: "Performance is currently limited (heat or lap detection)"
            font.pixelSize: Math.round(10 * localScale)
            color: "#f9e2af"
        }
    }

    component Stat: Row {
        property string icon
        property string label
        property string value
        spacing: Math.round(8 * root.localScale)
        Text {
            anchors.verticalCenter: parent.verticalCenter
            width: Math.round(16 * root.localScale)
            text: parent.icon; font.pixelSize: Math.round(13 * root.localScale)
            color: Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.45)
        }
        Column {
            Text { text: parent.parent.label; font.pixelSize: Math.round(9 * root.localScale); color: Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.45) }
            Text { text: parent.parent.value; font.pixelSize: Math.round(12 * root.localScale); font.weight: Font.Medium; color: Theme.text }
        }
    }
}
