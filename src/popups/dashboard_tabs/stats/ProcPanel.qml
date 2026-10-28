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
import "../../../"
import "../../../components"

// Top processes by CPU (ProcService). Bar length = CPU share of one core.

Item {
    id: root

    property real localScale: 1.0
    required property var service

    Column {
        anchors.centerIn: parent
        width:   parent.width - Math.round(16 * localScale)
        spacing: Math.round(3 * localScale)

        Repeater {
            model: root.service.procs

            delegate: Item {
                required property var modelData
                width:  parent.width
                height: Math.round(19 * localScale)

                Rectangle {
                    anchors { left: parent.left; verticalCenter: parent.verticalCenter }
                    height: parent.height
                    radius: Math.round(5 * localScale)
                    width:  Math.max(height, parent.width * Math.min(1, modelData.cpu / 100))
                    color:  Qt.rgba(Theme.active.r, Theme.active.g, Theme.active.b, 0.14)
                    Behavior on width { NumberAnimation { duration: Anim.slow; easing.type: Anim.outCubic } }
                }

                Text {
                    anchors { left: parent.left; leftMargin: Math.round(8 * localScale); verticalCenter: parent.verticalCenter }
                    width: parent.width * 0.55
                    elide: Text.ElideRight
                    text:  modelData.name
                    font.pixelSize: Math.round(11 * localScale)
                    color: Theme.text
                }

                Row {
                    anchors { right: parent.right; rightMargin: Math.round(8 * localScale); verticalCenter: parent.verticalCenter }
                    spacing: Math.round(14 * localScale)
                    Text {
                        width: Math.round(48 * localScale); horizontalAlignment: Text.AlignRight
                        text:  modelData.cpu.toFixed(1) + "%"
                        font.pixelSize: Math.round(10 * localScale); font.family: "JetBrains Mono"
                        color: Theme.active
                    }
                    Text {
                        width: Math.round(56 * localScale); horizontalAlignment: Text.AlignRight
                        text:  modelData.mem.toFixed(1) + "% mem"
                        font.pixelSize: Math.round(10 * localScale); font.family: "JetBrains Mono"
                        color: Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.4)
                    }
                }
            }
        }
    }
}
