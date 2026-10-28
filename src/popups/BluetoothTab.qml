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
import qs.Common
import "../"
import "../vendor/orbitBluetooth/components/scene"

// Bluetooth tab: Orbit Bluetooth's orbit view (vendor/orbitBluetooth, MIT,
// © lung595). Devices float around this machine; drag one to the centre to
// connect, pull it away to disconnect, click it for battery/volume/details.
// Its background services run in OrbitHost (ShellHost). The previous
// list-style tab is kept as BluetoothTabClassic.qml.

Item {
    id: root

    property real localScale: 1.0

    NightColors { id: night }

    Rectangle {
        anchors.fill: parent
        anchors.topMargin: Math.round(6 * root.localScale)
        radius: Theme.cornerRadius
        color: night.sky
        clip: true

        OrbitScene {
            anchors.fill: parent
            cornerRadius: Theme.cornerRadius
            foldVolume: true
            // Only animate and scan while the network popup shows this tab
            active: root.visible && SurfaceState.activeContent === "network"
        }
    }
}
