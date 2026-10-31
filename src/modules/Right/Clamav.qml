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
import "../../services"
import "../../"

// ClamAV shield in the bar. Click (or hover, like battery) opens the drop-down.
Item {
    id: root
    property real localScale: 1.0

    implicitWidth:  icon.implicitWidth + Math.round(6 * localScale)
    implicitHeight: icon.implicitHeight
    visible: ClamavService.available

    HoverHandler {
        id: hov
        onHoveredChanged: Popups.clamavTriggerHovered = hovered
    }

    Text {
        id: icon
        anchors.centerIn: parent
        text: !ClamavService.enabled ? "󰦞"           // shield-off
            : ClamavService.unseen   ? "󰻌"           // shield-alert
            : ClamavService.scanning ? "󰶚"           // shield-search
            : "󰕥"                                    // shield-check
        color: hov.hovered ? Theme.active : Theme.text
        opacity: ClamavService.enabled ? 1 : 0.55
        font.pixelSize: Math.round(17 * localScale)
        Behavior on color { ColorAnimation { duration: Anim.color } }

        // Breathe while a system scan runs
        SequentialAnimation on scale {
            running: ClamavService.scanning; loops: Animation.Infinite
            onRunningChanged: if (!running) icon.scale = 1
            NumberAnimation { to: 1.15; duration: 700; easing.type: Easing.InOutSine }
            NumberAnimation { to: 1.0;  duration: 700; easing.type: Easing.InOutSine }
        }
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            if (!Popups.clamavOpen) {
                Popups.closeAll()
                SurfaceState.open("right", "clamav")
                Popups.clamavPinned = true
            } else {
                SurfaceState.close()
            }
        }
    }
}
