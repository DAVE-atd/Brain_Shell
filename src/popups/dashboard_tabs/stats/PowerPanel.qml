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

Item {
    id: root

    property real localScale: 1.0
    required property var ppdService
    required property var envyService

    Column {
        anchors.centerIn: parent
        spacing:          Math.round(16 * localScale)

        Column {
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: Math.round(8 * localScale)

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text:           "Power Profile"
                font.pixelSize: Math.round(11 * localScale)
                font.weight:    Font.Medium
                color:          Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.4)
            }

            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: Math.round(6 * localScale)
                visible: root.ppdService.available

                Repeater {
                    model: root.ppdService.profiles
                    delegate: ProfileButton {
                        required property string modelData
                        localScale: root.localScale
                        label:   ({ "power-saver": "Saver", "balanced": "Balanced", "performance": "Performance" })[modelData] || modelData
                        active:  root.ppdService.profile === modelData
                        enabled: !root.ppdService.busy
                        onClicked: root.ppdService.set(modelData)
                    }
                }
            }

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                visible:        !root.ppdService.available
                text:           "power-profiles-daemon not running"
                font.pixelSize: Math.round(12 * localScale)
                color:          Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.3)
            }
        }

        Rectangle {
            visible: envyService.available
            anchors.horizontalCenter: parent.horizontalCenter
            width:  Math.round(200 * localScale)
            height: 1
            color:  Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.07)
        }

        Column {
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: Math.round(8 * localScale)
            visible: envyService.available

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text:           "GPU Mode"
                font.pixelSize: Math.round(11 * localScale)
                font.weight:    Font.Medium
                color:          Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.4)
            }

            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: Math.round(6 * localScale)

                ProfileButton {
                    localScale: root.localScale
                    label:     "Integrated"
                    active:    root.envyService.currentMode === "integrated"
                    enabled:   !root.envyService.busy
                    onClicked: root.envyService.switchMode("integrated")
                }
                ProfileButton {
                    localScale: root.localScale
                    label:     "Hybrid"
                    active:    root.envyService.currentMode === "hybrid"
                    enabled:   !root.envyService.busy
                    onClicked: root.envyService.switchMode("hybrid")
                }
            }

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text:           "GPU mode switch requires a reboot"
                font.pixelSize: Math.round(10 * localScale)
                color:          Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.25)
            }
        }
    }
}
