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
import "../"
import "../services"

// TailscaleTab — tailnet status, exit node picker and peer list.
// State lives in TailscaleService; clicking a peer copies its IP.

Item {
    id: root

    property real localScale: 1.0

    readonly property var ts: TailscaleService
    readonly property color _dim:   Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.32)
    readonly property color _faint: Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.07)

    function _osIcon(os) {
        switch (os) {
            case "linux":   return "󰌽"
            case "windows": return "󰍲"
            case "macOS":   return "󰀵"
            case "android": return "󰀲"
            case "iOS":     return "󰀷"
            default:        return "󰒋"
        }
    }

    function _ago(iso) {
        if (!iso || iso.indexOf("0001") === 0) return ""
        var s = (Date.now() - new Date(iso).getTime()) / 1000
        if (s < 3600)   return Math.max(1, Math.round(s / 60)) + " min ago"
        if (s < 86400)  return Math.round(s / 3600) + " h ago"
        return Math.round(s / 86400) + " d ago"
    }

    Component.onCompleted: { ts.fastPoll = true; ts.refresh() }
    Component.onDestruction: ts.fastPoll = false

    Column {
        anchors.fill: parent; spacing: 0

        // ── Header ────────────────────────────────────────────────────────────
        Item {
            width: parent.width; height: Math.round(40 * localScale)

            Column {
                anchors { left: parent.left; leftMargin: Math.round(2 * localScale); verticalCenter: parent.verticalCenter }
                spacing: Math.round(1 * localScale)
                Text {
                    text: "Tailscale"; font.pixelSize: Math.round(15 * localScale); font.weight: Font.Bold; color: Theme.text
                }
                Text {
                    text: !ts.available ? "tailscaled not reachable"
                        : ts.busy ? ts.busyLabel
                        : ts.running ? ts.tailnet + "  ·  " + ts.onlineCount + " online"
                        : ts.backendState
                    font.pixelSize: Math.round(10 * localScale)
                    color: ts.running ? Qt.rgba(Theme.active.r, Theme.active.g, Theme.active.b, 0.7) : root._dim
                }
            }

            // Power switch
            Rectangle {
                id: sw
                anchors { right: parent.right; verticalCenter: parent.verticalCenter }
                width: Math.round(44 * localScale); height: Math.round(24 * localScale); radius: height / 2
                opacity: ts.available ? 1 : 0.4
                color: ts.running ? Theme.active : Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.12)
                Behavior on color { ColorAnimation { duration: Anim.color } }

                Rectangle {
                    width: parent.height - Math.round(6 * localScale); height: width; radius: width / 2
                    anchors.verticalCenter: parent.verticalCenter
                    x: ts.running ? parent.width - width - Math.round(3 * localScale) : Math.round(3 * localScale)
                    color: ts.running ? Theme.background : Theme.text
                    Behavior on x { NumberAnimation { duration: Anim.normal; easing.type: Anim.outCubic } }

                    SequentialAnimation on opacity {
                        running: ts.busy; loops: Animation.Infinite
                        NumberAnimation { to: 0.3; duration: Anim.slower }
                        NumberAnimation { to: 1.0; duration: Anim.slower }
                    }
                }

                HoverHandler { cursorShape: Qt.PointingHandCursor }
                MouseArea { anchors.fill: parent; enabled: ts.available && !ts.busy; onClicked: ts.toggle() }
            }
        }

        Rectangle { width: parent.width; height: 1; color: root._faint }
        Item      { width: parent.width; height: Math.round(8 * localScale) }

        Flickable {
            width: parent.width; height: parent.height - Math.round(49 * localScale)
            contentWidth: width; contentHeight: col.height
            clip: true; boundsBehavior: Flickable.StopAtBounds

            Column {
                id: col; width: parent.width; spacing: Math.round(6 * localScale)

                // ── This device ───────────────────────────────────────────────
                Rectangle {
                    width: parent.width; height: Math.round(54 * localScale)
                    radius: Math.round(Theme.cornerRadius * localScale)
                    color: ts.running ? Qt.rgba(Theme.active.r, Theme.active.g, Theme.active.b, 0.08) : "transparent"
                    border.color: ts.running ? Qt.rgba(Theme.active.r, Theme.active.g, Theme.active.b, 0.22) : root._faint
                    border.width: Math.max(1, Math.round(1 * localScale))
                    Behavior on color { ColorAnimation { duration: Anim.normal } }

                    Row {
                        anchors { left: parent.left; leftMargin: Math.round(12 * localScale); verticalCenter: parent.verticalCenter }
                        spacing: Math.round(12 * localScale)
                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: "󰖂"; font.pixelSize: Math.round(20 * localScale)
                            color: ts.running ? Theme.active : root._dim
                        }
                        Column {
                            anchors.verticalCenter: parent.verticalCenter; spacing: Math.round(4 * localScale)
                            Text { text: ts.selfName || "—"; font.pixelSize: Math.round(13 * localScale); font.weight: Font.Medium; color: Theme.text }
                            Text {
                                text: ts.running ? ts.selfIp : "Disconnected"
                                font.pixelSize: Math.round(10 * localScale); font.family: "JetBrains Mono"
                                color: ts.running ? Theme.active : root._dim
                            }
                        }
                    }

                    CopyHint {
                        anchors { right: parent.right; rightMargin: Math.round(12 * localScale); verticalCenter: parent.verticalCenter }
                        visible: ts.running; value: ts.selfIp
                    }
                }

                // ── Exit node ─────────────────────────────────────────────────
                SectionLabel { text: "EXIT NODE"; visible: ts.running && ts.exitNodes.length > 0 }

                Flow {
                    width: parent.width; spacing: Math.round(6 * localScale)
                    visible: ts.running && ts.exitNodes.length > 0

                    ExitChip { label: "None"; icon: "󰅖"; selected: ts.exitNode === ""; ip: ""; enabledChip: true }
                    Repeater {
                        model: ts.exitNodes
                        delegate: ExitChip {
                            required property var modelData
                            label: modelData.name; icon: "󰈀"; ip: modelData.ip
                            selected: modelData.exitNode; enabledChip: modelData.online
                        }
                    }
                }

                // ── Peers ─────────────────────────────────────────────────────
                SectionLabel { text: "DEVICES"; visible: ts.running && ts.peers.length > 0 }

                Repeater {
                    model: ts.running ? ts.peers : []
                    delegate: PeerRow {
                        required property var modelData
                        width: col.width; peer: modelData
                    }
                }

                // ── Empty / stopped state ─────────────────────────────────────
                Item {
                    width: parent.width; height: Math.round(160 * localScale)
                    visible: !ts.running
                    Column {
                        anchors.centerIn: parent; spacing: Math.round(10 * localScale)
                        Text { anchors.horizontalCenter: parent.horizontalCenter; text: "󰖂"; font.pixelSize: Math.round(36 * localScale); color: root._faint }
                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: !ts.available ? "Tailscale is not running"
                                : ts.backendState === "NeedsLogin" ? "Log in with: tailscale up"
                                : "Tailscale is off"
                            font.pixelSize: Math.round(13 * localScale)
                            color: Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.2)
                        }
                    }
                }

                Item { width: parent.width; height: Math.round(8 * localScale) }
            }
        }
    }

    // ── Components ────────────────────────────────────────────────────────────
    component SectionLabel: Text {
        topPadding: Math.round(6 * localScale)
        font.pixelSize: Math.round(9 * localScale); font.weight: Font.Bold; font.letterSpacing: 1.2
        color: Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.25)
    }

    // Small "copy" glyph that briefly turns into a check after copying `value`
    component CopyHint: Text {
        id: ch
        property string value: ""
        property bool done: false
        text: done ? "󰄬" : "󰆏"
        font.pixelSize: Math.round(14 * localScale)
        color: done ? Theme.active : chH.hovered ? Theme.text : root._dim
        Behavior on color { ColorAnimation { duration: Anim.normal } }
        Timer { id: chT; interval: 1200; onTriggered: ch.done = false }
        HoverHandler { id: chH; cursorShape: Qt.PointingHandCursor }
        MouseArea {
            anchors.fill: parent; anchors.margins: -Math.round(6 * localScale)
            onClicked: { ts.copy(ch.value); ch.done = true; chT.restart() }
        }
    }

    component ExitChip: Rectangle {
        id: chip
        property string label
        property string icon
        property string ip
        property bool selected
        property bool enabledChip
        height: Math.round(28 * localScale); radius: height / 2
        width: chipRow.implicitWidth + Math.round(20 * localScale)
        opacity: enabledChip ? 1 : 0.4
        color: selected ? Qt.rgba(Theme.active.r, Theme.active.g, Theme.active.b, 0.18)
             : cH.hovered ? Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.08)
             : Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.04)
        border.color: selected ? Qt.rgba(Theme.active.r, Theme.active.g, Theme.active.b, 0.40) : Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.10)
        border.width: Math.max(1, Math.round(1 * localScale))
        Behavior on color        { ColorAnimation { duration: Anim.color } }
        Behavior on border.color { ColorAnimation { duration: Anim.color } }

        Row {
            id: chipRow; anchors.centerIn: parent; spacing: Math.round(6 * localScale)
            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: chip.icon; font.pixelSize: Math.round(12 * localScale)
                color: chip.selected ? Theme.active : root._dim
            }
            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: chip.label; font.pixelSize: Math.round(11 * localScale); font.weight: Font.Medium
                color: chip.selected ? Theme.active : Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.6)
            }
        }

        HoverHandler { id: cH; cursorShape: Qt.PointingHandCursor }
        MouseArea {
            anchors.fill: parent
            enabled: chip.enabledChip && !chip.selected && !ts.busy
            onClicked: ts.setExitNode(chip.ip, chip.label)
        }
    }

    component PeerRow: Item {
        id: pRow
        required property var peer
        height: Math.round(44 * localScale)

        Rectangle {
            anchors.fill: parent; radius: Math.round(Theme.cornerRadius * localScale)
            color: pH.hovered ? Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.04) : "transparent"
            border.color: root._faint; border.width: Math.max(1, Math.round(1 * localScale))
            Behavior on color { ColorAnimation { duration: Anim.normal } }
        }

        Row {
            anchors { left: parent.left; leftMargin: Math.round(12 * localScale); verticalCenter: parent.verticalCenter }
            spacing: Math.round(12 * localScale)

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: root._osIcon(pRow.peer.os); font.pixelSize: Math.round(16 * localScale)
                color: pRow.peer.online ? Theme.text : root._dim
            }
            Column {
                anchors.verticalCenter: parent.verticalCenter; spacing: Math.round(2 * localScale)
                Text {
                    text: pRow.peer.name + (pRow.peer.exitNode ? "  · exit node" : "")
                    font.pixelSize: Math.round(12 * localScale)
                    color: pRow.peer.online ? Theme.text : Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.5)
                    width: Math.round(260 * localScale); elide: Text.ElideRight
                }
                Text {
                    text: pRow.peer.ip + (pRow.peer.online ? "" : "  ·  " + root._ago(pRow.peer.lastSeen))
                    font.pixelSize: Math.round(9 * localScale); font.family: "JetBrains Mono"
                    color: root._dim
                }
            }
        }

        Row {
            anchors { right: parent.right; rightMargin: Math.round(12 * localScale); verticalCenter: parent.verticalCenter }
            spacing: Math.round(12 * localScale)
            CopyHint { anchors.verticalCenter: parent.verticalCenter; value: pRow.peer.ip; opacity: pH.hovered ? 1 : 0
                Behavior on opacity { NumberAnimation { duration: Anim.normal } } }
            Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                width: Math.round(8 * localScale); height: width; radius: width / 2
                color: pRow.peer.online ? Theme.active : Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.18)
            }
        }

        HoverHandler { id: pH }
    }
}
