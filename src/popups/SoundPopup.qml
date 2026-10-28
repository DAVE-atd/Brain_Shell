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
import Quickshell.Services.Pipewire
import "../components"
import "../services"
import "../"

// Sound drop-down (right notch, like the network popup): a volume ring with a
// circular visualiser around it (drag or scroll the ring), microphone level,
// and tabs for output devices, input devices and per-app volume.
// Content key stays "audio", so the audio IPC targets and pinning keep working.

Item {
    id: root

    property real localScale: 1.0
    readonly property int popupWidth:  Math.round(400 * localScale)
    readonly property int popupHeight: Math.round(610 * localScale)

    Keys.onEscapePressed: SurfaceState.close()
    onOpacityChanged: if (opacity === 1) forceActiveFocus()
    onVisibleChanged: CavaService.soundPopupVisible = visible

    // ── Pipewire ──────────────────────────────────────────────────────────────
    readonly property var sink:   Pipewire.defaultAudioSink
    readonly property var source: Pipewire.defaultAudioSource
    // Orbit's virtual loopback (orbit_pc_* sink + its pw-loopback stream) is plumbing, not a device
    readonly property var _audioNodes: Pipewire.nodes.values.filter(n => n && n.audio !== null && !(n.name || "").startsWith("orbit_"))
    // Active device first
    function _activeFirst(list, active) { return list.slice().sort((a, b) => (b === active) - (a === active)) }
    readonly property var sinks:   _activeFirst(_audioNodes.filter(n => !n.isStream && n.isSink), sink)
    readonly property var sources: _activeFirst(_audioNodes.filter(n => !n.isStream && !n.isSink && !(n.name || "").endsWith(".monitor")), source)
    readonly property var streams: _audioNodes.filter(n => n.isStream && n.isSink)

    PwObjectTracker { objects: root.sinks.concat(root.sources).concat(root.streams) }

    readonly property bool  ready:  !!(sink && sink.ready)
    readonly property real  volume: ready ? sink.audio.volume : 0
    readonly property bool  muted:  ready && sink.audio.muted

    function setVolume(v) { if (ready) { sink.audio.muted = false; sink.audio.volume = Math.max(0, Math.min(1, v)) } }
    function nodeName(n) { return n ? (n.description || n.nickname || n.name || "Unknown") : "" }
    function nodeIcon(n) {
        var s = ((n && (n.name + " " + n.description)) || "").toLowerCase()
        if (/head|airpods|buds|earbud|jabra|wh-|wf-/.test(s)) return "󰋋"
        if (s.indexOf("bluez") >= 0) return "󰂰"
        if (s.indexOf("hdmi") >= 0 || s.indexOf("displayport") >= 0) return "󰡁"
        if (n && !n.isSink) return "󰍬"
        return "󰓃"
    }

    MouseArea { anchors.fill: parent; z: -1; onClicked: Popups.audioPinned = true }

    Column {
        anchors { fill: parent; margins: Math.round(12 * localScale) }
        spacing: Math.round(10 * localScale)

        // ── Header ────────────────────────────────────────────────────────────
        Item {
            width: parent.width; height: Math.round(34 * localScale)
            Column {
                anchors.verticalCenter: parent.verticalCenter
                width: parent.width
                Text { text: "Sound"; color: Theme.text; font.pixelSize: Math.round(15 * localScale); font.weight: Font.Bold }
                Text {
                    width: parent.width; elide: Text.ElideRight
                    text: root.ready ? root.nodeName(root.sink) : "No output"
                    color: Qt.rgba(Theme.active.r, Theme.active.g, Theme.active.b, 0.8)
                    font.pixelSize: Math.round(10 * localScale)
                }
            }
        }

        // ── Hero: volume ring with visualiser ─────────────────────────────────
        Rectangle {
            width: parent.width; height: Math.round(196 * localScale)
            radius: Math.round(Theme.cornerRadius * localScale)
            color: Theme.card
            border.color: Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.06)
            clip: true

            Item {
                id: hero
                width: Math.round(180 * localScale); height: width
                anchors.centerIn: parent

                // Visualiser: 32 cava bars mirrored around the ring
                Repeater {
                    model: 64
                    delegate: Item {
                        required property int index
                        anchors.fill: parent
                        rotation: index * 360 / 64
                        readonly property real level: {
                            var b = CavaService.bars
                            var i = index < 32 ? index : 63 - index
                            return (b && b.length > i ? b[i] : 0) / 100
                        }
                        Rectangle {
                            width: Math.max(2, Math.round(2.5 * root.localScale))
                            radius: width / 2
                            height: Math.round(3 * root.localScale) + parent.level * Math.round(22 * root.localScale)
                            x: (parent.width - width) / 2
                            y: Math.round(26 * root.localScale) - height
                            color: Theme.active
                            opacity: root.muted ? 0.08 : 0.25 + parent.level * 0.6
                            Behavior on height { NumberAnimation { duration: 90 } }
                        }
                    }
                }

                Ring {
                    id: volRing
                    anchors.fill: parent
                    anchors.margins: Math.round(30 * localScale)
                    value: root.volume
                    gap: 70
                    thickness: Math.round(9 * localScale)
                    color: root.muted ? Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.3) : Theme.active
                    duration: dragArea.pressed ? 0 : Anim.slow
                }

                // Drag along the ring or scroll anywhere on it to set the volume
                MouseArea {
                    id: dragArea
                    anchors.fill: volRing
                    cursorShape: Qt.PointingHandCursor
                    function apply(mx, my) {
                        var a = Math.atan2(my - height / 2, mx - width / 2) * 180 / Math.PI   // 0 = 3 o'clock
                        var rel = ((a - volRing.start) % 360 + 360) % 360
                        if (rel > volRing.span) rel = rel > volRing.span + volRing.gap / 2 ? 0 : volRing.span
                        root.setVolume(rel / volRing.span)
                    }
                    onPressed: (m) => { Popups.audioPinned = true; apply(m.x, m.y) }
                    onPositionChanged: (m) => { if (pressed) apply(m.x, m.y) }
                    onWheel: (w) => root.setVolume(root.volume + (w.angleDelta.y > 0 ? 0.05 : -0.05))
                }

                // Centre: mute button + level
                Column {
                    anchors.centerIn: parent
                    spacing: Math.round(2 * localScale)
                    Rectangle {
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: Math.round(40 * localScale); height: width; radius: width / 2
                        color: muteHov.hovered ? Qt.rgba(Theme.active.r, Theme.active.g, Theme.active.b, 0.18) : "transparent"
                        Behavior on color { ColorAnimation { duration: Anim.normal } }
                        Text {
                            anchors.centerIn: parent
                            text: root.muted ? "󰝟" : root.volume > 0.6 ? "󰕾" : root.volume > 0.2 ? "󰖀" : "󰕿"
                            font.pixelSize: Math.round(22 * localScale)
                            color: root.muted ? Theme.error : Theme.text
                        }
                        HoverHandler { id: muteHov; cursorShape: Qt.PointingHandCursor }
                        MouseArea { anchors.fill: parent; onClicked: if (root.ready) root.sink.audio.muted = !root.sink.audio.muted }
                    }
                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: root.muted ? "Muted" : Math.round(root.volume * 100) + "%"
                        font.pixelSize: Math.round(15 * localScale); font.weight: Font.Bold
                        color: Theme.text
                    }
                }
            }
        }

        // ── Microphone ────────────────────────────────────────────────────────
        LevelRow {
            width: parent.width
            node: root.source
            icon: root.source && root.source.ready && root.source.audio.muted ? "󰍭" : "󰍬"
            label: root.source ? root.nodeName(root.source) : "No microphone"
        }

        // ── Tabs: devices / apps ──────────────────────────────────────────────
        TabSwitcher {
            id: tabs
            width: parent.width
            localScale: root.localScale
            orientation: "horizontal"
            currentPage: Popups.audioPage === "mixer" ? "apps" : Popups.audioPage
            model: [
                { key: "output", icon: "󰓃", label: "Output" },
                { key: "input",  icon: "󰍬", label: "Input"  },
                { key: "apps",   icon: "󰀻", label: "Apps"   }
            ]
            onPageChanged: function(key) { Popups.audioPage = key === "apps" ? "mixer" : key }
        }

        Flickable {
            width: parent.width
            height: parent.height - y
            contentHeight: list.height
            clip: true
            boundsBehavior: Flickable.StopAtBounds

            Column {
                id: list
                width: parent.width
                spacing: Math.round(6 * localScale)

                Repeater {
                    model: tabs.currentPage === "output" ? root.sinks : tabs.currentPage === "input" ? root.sources : []
                    delegate: DeviceRow {
                        required property var modelData
                        width: list.width
                        node: modelData
                        selected: tabs.currentPage === "output"
                            ? !!(root.sink && modelData.id === root.sink.id)
                            : !!(root.source && modelData.id === root.source.id)
                    }
                }

                Repeater {
                    model: tabs.currentPage === "apps" ? root.streams : []
                    delegate: LevelRow {
                        required property var modelData
                        width: list.width
                        node: modelData
                        icon: "󰝚"
                        label: (modelData.properties && modelData.properties["application.name"]) || root.nodeName(modelData)
                    }
                }

                Text {
                    visible: tabs.currentPage === "apps" && root.streams.length === 0
                    text: "No app is playing audio"
                    font.pixelSize: Math.round(11 * localScale)
                    color: Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.35)
                    topPadding: Math.round(10 * localScale)
                    anchors.horizontalCenter: parent.horizontalCenter
                }
            }
        }
    }

    // ── Device card: click makes it the default ───────────────────────────────
    component DeviceRow: Rectangle {
        id: dr
        property var  node
        property bool selected
        height: Math.round(44 * root.localScale)
        radius: Math.round(Theme.cornerRadius * root.localScale)
        color: selected ? Qt.rgba(Theme.active.r, Theme.active.g, Theme.active.b, 0.10)
             : drHov.hovered ? Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.05) : "transparent"
        border.color: selected ? Qt.rgba(Theme.active.r, Theme.active.g, Theme.active.b, 0.35) : Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.07)
        Behavior on color { ColorAnimation { duration: Anim.normal } }

        Row {
            anchors { left: parent.left; leftMargin: Math.round(12 * root.localScale); verticalCenter: parent.verticalCenter }
            spacing: Math.round(12 * root.localScale)
            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: root.nodeIcon(dr.node); font.pixelSize: Math.round(17 * root.localScale)
                color: dr.selected ? Theme.active : Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.5)
            }
            Text {
                anchors.verticalCenter: parent.verticalCenter
                width: dr.width - Math.round(80 * root.localScale); elide: Text.ElideRight
                text: root.nodeName(dr.node); font.pixelSize: Math.round(12 * root.localScale)
                color: dr.selected ? Theme.text : Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.7)
            }
        }
        Rectangle {
            anchors { right: parent.right; rightMargin: Math.round(14 * root.localScale); verticalCenter: parent.verticalCenter }
            width: Math.round(8 * root.localScale); height: width; radius: width / 2
            color: dr.selected ? Theme.active : "transparent"
            border.color: dr.selected ? Theme.active : Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.2)
        }
        HoverHandler { id: drHov; cursorShape: Qt.PointingHandCursor }
        MouseArea {
            anchors.fill: parent
            onClicked: {
                Popups.audioPinned = true
                if (dr.node.isSink) Pipewire.preferredDefaultAudioSink = dr.node
                else Pipewire.preferredDefaultAudioSource = dr.node
            }
        }
    }

    // ── Icon (mute) + name + slider for one node ──────────────────────────────
    component LevelRow: Rectangle {
        id: lr
        property var    node
        property string icon
        property string label
        readonly property bool ok: !!(node && node.ready && node.audio)
        readonly property real vol: ok ? node.audio.volume : 0
        readonly property bool mut: ok && node.audio.muted

        height: Math.round(48 * root.localScale)
        radius: Math.round(Theme.cornerRadius * root.localScale)
        color: Theme.card

        Text {
            id: lrIcon
            anchors { left: parent.left; leftMargin: Math.round(12 * root.localScale); verticalCenter: parent.verticalCenter }
            text: lr.icon; font.pixelSize: Math.round(17 * root.localScale)
            color: lr.mut ? Theme.error : Theme.active
            MouseArea { anchors.fill: parent; anchors.margins: -6; cursorShape: Qt.PointingHandCursor; onClicked: if (lr.ok) lr.node.audio.muted = !lr.node.audio.muted }
        }
        Column {
            anchors { left: lrIcon.right; leftMargin: Math.round(12 * root.localScale); right: pctText.left; rightMargin: Math.round(10 * root.localScale); verticalCenter: parent.verticalCenter }
            spacing: Math.round(6 * root.localScale)
            Text {
                width: parent.width; elide: Text.ElideRight
                text: lr.label; font.pixelSize: Math.round(10 * root.localScale)
                color: Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.6)
            }
            // Track + fill; click or drag to set
            Item {
                width: parent.width; height: Math.round(6 * root.localScale)
                Rectangle { anchors.fill: parent; radius: height / 2; color: Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.10) }
                Rectangle {
                    width: parent.width * Math.min(1, lr.vol); height: parent.height; radius: height / 2
                    color: lr.mut ? Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.3) : Theme.active
                    Behavior on width { enabled: !lrDrag.pressed; NumberAnimation { duration: Anim.normal } }
                }
                MouseArea {
                    id: lrDrag
                    anchors.fill: parent; anchors.margins: -8
                    cursorShape: Qt.PointingHandCursor
                    function set(mx) { if (lr.ok) { lr.node.audio.muted = false; lr.node.audio.volume = Math.max(0, Math.min(1, (mx - 8) / (width - 16))) } }
                    onPressed: (m) => { Popups.audioPinned = true; set(m.x) }
                    onPositionChanged: (m) => { if (pressed) set(m.x) }
                    onWheel: (w) => { if (lr.ok) lr.node.audio.volume = Math.max(0, Math.min(1, lr.vol + (w.angleDelta.y > 0 ? 0.05 : -0.05))) }
                }
            }
        }
        Text {
            id: pctText
            anchors { right: parent.right; rightMargin: Math.round(12 * root.localScale); verticalCenter: parent.verticalCenter }
            width: Math.round(34 * root.localScale); horizontalAlignment: Text.AlignRight
            text: lr.ok ? Math.round(lr.vol * 100) + "%" : "—"
            font.pixelSize: Math.round(11 * root.localScale); font.family: "JetBrains Mono"
            color: Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.6)
        }
    }
}
