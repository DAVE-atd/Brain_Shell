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
import "../../"
import "../../services"

// SysMonitor — temp / memory / cpu / disk in a capsule (takes the place of
// Workspaces in LeftContent). Values turn yellow/red near their limits.
// Click opens the dashboard System tab.

Rectangle {
    id: root

    property real localScale: 1.0

    ThermalService { id: thermal }
    MemService     { id: mem }
    CpuService     { id: cpu }
    DiskService    { id: disk }

    // Root filesystem (first df entry is "/")
    readonly property int _diskPct: {
        var d = disk.disks
        for (var i = 0; i < d.length; i++) if (d[i].mount === "/") return d[i].usedPct
        return d.length ? d[0].usedPct : 0
    }

    function _level(v, warn, crit) {
        if (v >= crit) return Theme.error
        if (v >= warn) return "#f5c47a"
        return Theme.text
    }

    color:  Theme.wsBackground
    radius: Math.round(Theme.wsRadius * localScale)
    width:  row.implicitWidth + Math.round(Theme.wsPadding * 4 * localScale)
    height: Math.round(Theme.wsDotSize * localScale) + Math.round(Theme.wsPadding * 2 * localScale)

    border.color: hov.hovered ? Qt.rgba(Theme.active.r, Theme.active.g, Theme.active.b, 0.5) : "transparent"
    border.width: Math.max(1, Math.round(1 * localScale))
    Behavior on border.color { ColorAnimation { duration: Anim.normal } }

    Row {
        id: row
        anchors.centerIn: parent
        spacing: Math.round(10 * localScale)

        Stat { icon: "󰔏"; value: thermal.cpuTemp > 0 ? Math.round(thermal.cpuTemp) + "°" : "—"; tint: root._level(thermal.cpuTemp, 80, 90) }
        Stat { icon: "󰍛"; value: mem.usagePercent + "%"; tint: root._level(mem.usagePercent, 80, 92) }
        Stat { icon: "󰻠"; value: cpu.usagePercent + "%"; tint: root._level(cpu.usagePercent, 75, 95) }
        Stat { icon: "󰋊"; value: root._diskPct + "%"; tint: root._level(root._diskPct, 85, 95) }
    }

    HoverHandler { id: hov; cursorShape: Qt.PointingHandCursor }
    MouseArea { anchors.fill: parent; onClicked: IpcManager.dashboardStats.toggle() }

    component Stat: Row {
        property string icon
        property string value
        property color  tint
        spacing: Math.round(4 * root.localScale)
        anchors.verticalCenter: parent.verticalCenter

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: parent.icon
            font.pixelSize: Math.round(13 * root.localScale)
            color: parent.tint === Theme.text ? Theme.active : parent.tint
            Behavior on color { ColorAnimation { duration: Anim.normal } }
        }
        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: parent.value
            // fixed width so the capsule doesn't jitter when digits change
            width: Math.max(implicitWidth, Math.round(26 * root.localScale))
            font.pixelSize: Math.round(11 * root.localScale); font.weight: Font.Medium
            color: parent.tint
            Behavior on color { ColorAnimation { duration: Anim.normal } }
        }
    }
}
