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
import Quickshell.Io

// Reads the first battery in /sys/class/power_supply every 2s.
// power_now is missing on some laptops, then current_now × voltage_now is used.
//
// Exposes:
//   bool   available — a battery was found
//   real   watts     — charge/discharge power in W
//   int    capacity  — 0–100
//   string status    — "Charging" | "Discharging" | "Full" | "Not charging"
//   string wattsStr  — e.g. "8.4 W"

QtObject {
    id: root

    property bool   active:    true
    property bool   available: false
    property real   watts:     0
    property int    capacity:  0
    property string status:    ""
    property string wattsStr:  "— W"

    property var _proc: Process {
        command: ["sh", "-c",
            "b=$(ls -d /sys/class/power_supply/BAT* 2>/dev/null | head -1); [ -n \"$b\" ] || exit 1; " +
            "echo \"$(cat $b/status)|$(cat $b/capacity)|$(cat $b/power_now 2>/dev/null)|" +
            "$(cat $b/current_now 2>/dev/null)|$(cat $b/voltage_now 2>/dev/null)\""]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                var p = text.trim().split("|")
                if (p.length < 5) return
                var uw = p[2] !== "" ? parseFloat(p[2])
                       : parseFloat(p[3]) * parseFloat(p[4]) / 1e6
                root.available = true
                root.status    = p[0]
                root.capacity  = parseInt(p[1]) || 0
                root.watts     = isNaN(uw) ? 0 : Math.abs(uw) / 1e6
                root.wattsStr  = root.watts.toFixed(1) + " W"
            }
        }
    }

    property var _timer: Timer {
        interval: 2000
        running:  root.active
        repeat:   true
        triggeredOnStart: true
        onTriggered: { _proc.running = false; _proc.running = true }
    }
}
