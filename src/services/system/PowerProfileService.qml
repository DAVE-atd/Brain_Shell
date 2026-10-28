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

// power-profiles-daemon via powerprofilesctl (no root needed).
//
// Exposes:
//   bool   available — powerprofilesctl works
//   string profile   — "power-saver" | "balanced" | "performance"
//   var    profiles  — profiles the hardware supports
//   function set(name)

QtObject {
    id: root

    property bool   active:    true
    property bool   available: false
    property bool   busy:      false
    property string profile:   ""
    property var    profiles:  []

    property var _listProc: Process {
        command: ["powerprofilesctl", "list"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                var list = [], cur = ""
                var lines = text.split("\n")
                for (var i = 0; i < lines.length; i++) {
                    var m = lines[i].match(/^(\*)?\s*([a-z-]+):$/)
                    if (!m) continue
                    list.unshift(m[2])          // ppd lists performance first
                    if (m[1]) cur = m[2]
                }
                root.available = list.length > 0
                root.profiles  = list
                root.profile   = cur
            }
        }
    }

    property var _setProc: Process {
        running: false
        onExited: { root.busy = false; root._poll() }
    }

    function set(name) {
        if (busy || name === profile) return
        busy = true
        profile = name
        _setProc.command = ["powerprofilesctl", "set", name]
        _setProc.running = true
    }

    function _poll() { _listProc.running = false; _listProc.running = true }

    property var _timer: Timer {
        interval: 5000
        running:  root.active
        repeat:   true
        triggeredOnStart: true
        onTriggered: root._poll()
    }
}
