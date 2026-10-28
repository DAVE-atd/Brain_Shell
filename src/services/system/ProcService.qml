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

// Top processes by CPU. Uses two top iterations (the first one only
// averages since process start), every 3s.
//
// Exposes:
//   var procs — [{ name, cpu, mem }] sorted by cpu, max `count` entries

QtObject {
    id: root

    property bool active: true
    property int  count:  4
    property var  procs:  []

    property var _proc: Process {
        command: ["sh", "-c",
            "LC_ALL=C top -b -n2 -d0.5 -o %CPU -w 512 | awk '/^ *PID/{n++; next} n==2' | head -" + root.count]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                var out = []
                var lines = text.trim().split("\n")
                for (var i = 0; i < lines.length; i++) {
                    // PID USER PR NI VIRT RES SHR S %CPU %MEM TIME+ COMMAND
                    var f = lines[i].trim().split(/\s+/)
                    if (f.length < 12) continue
                    var name = f.slice(11).join(" ")
                        .replace(/^\./, "").replace(/-wr(a(p(p(e(d)?)?)?)?)?$/, "")  // top cuts names at 15 chars
                    out.push({ name: name, cpu: parseFloat(f[8]) || 0, mem: parseFloat(f[9]) || 0 })
                }
                root.procs = out
            }
        }
    }

    property var _timer: Timer {
        interval: 3000
        running:  root.active
        repeat:   true
        triggeredOnStart: true
        onTriggered: { if (!_proc.running) _proc.running = true }
    }
}
