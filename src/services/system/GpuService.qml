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

// Intel iGPU: busy % from rc6 residency, frequency from sysfs rps files.
// NVIDIA dGPU: nvidia-smi when envycontrol mode is not "integrated".
//
// Exposes:
//   igpu.busyPercent  — 0–100 (time not spent in rc6 sleep)
//   igpu.freqPercent  — 0–100 (act_freq / max_freq * 100)
//   igpu.curMhz       — e.g. "650 MHz"
//   igpu.maxMhz       — e.g. "1100 MHz"
//
//   dgpu.active       — false when envycontrol is "integrated"
//   dgpu.usagePercent — 0–100
//   dgpu.usedVram     — e.g. "2048 MB"
//   dgpu.totalVram    — e.g. "4096 MB"

QtObject {
    id: root

    property bool   active:   true
    property string envyMode: "integrated"
    property bool hasNvidia: false

    property var _nvCheckProc: Process {
        command: ["sh", "-c", "command -v nvidia-smi"]
        running: true
        onExited: (code) => { root.hasNvidia = (code === 0) }
    }

    property QtObject igpu: QtObject {
        property real   freqPercent: 0.0
        property real   busyPercent: 0.0
        property string curMhz:     "— MHz"
        property string maxMhz:     "— MHz"
    }

    property QtObject dgpu: QtObject {
        property bool   active:       false
        property real   usagePercent: 0.0
        property string usedVram:     "— MB"
        property string totalVram:    "— MB"
    }

    // ── Intel iGPU ────────────────────────────────────────────────────────────
    // One read per tick: cur freq, max freq, rc6 residency (ms the GPU slept).
    // cur (requested) instead of act: act reads 0 whenever the sample hits rc6.
    // Busy % = share of wall time NOT spent in rc6 since the previous tick.
    property real _actMhz:   0
    property real _maxMhz:   0
    property real _prevRc6:  -1
    property real _prevTime: 0

    property var _igpuProc: Process {
        command: ["sh", "-c",
            "d=$(ls -d /sys/class/drm/card*/gt/gt0 2>/dev/null | head -1); " +
            "[ -n \"$d\" ] && cat $d/rps_cur_freq_mhz $d/rps_max_freq_mhz $d/rc6_residency_ms"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                var v = text.trim().split("\n").map(parseFloat)
                if (v.length < 3 || v.some(isNaN)) return
                var now = Date.now()
                root._actMhz     = v[0]
                root._maxMhz     = v[1]
                root.igpu.curMhz = v[0] + " MHz"
                root.igpu.maxMhz = v[1] + " MHz"
                if (v[1] > 0) root.igpu.freqPercent = Math.round(v[0] / v[1] * 100)
                if (root._prevRc6 >= 0 && now > root._prevTime) {
                    var idle = (v[2] - root._prevRc6) / (now - root._prevTime)
                    root.igpu.busyPercent = Math.max(0, Math.min(100, Math.round((1 - idle) * 100)))
                }
                root._prevRc6  = v[2]
                root._prevTime = now
            }
        }
    }

    // ── NVIDIA dGPU ───────────────────────────────────────────────────────────
    property var _nvProc: Process {
        command: [
            "nvidia-smi",
            "--query-gpu=utilization.gpu,memory.used,memory.total",
            "--format=csv,noheader,nounits"
        ]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                var line  = text.trim()
                if (line === "") return
                var parts = line.split(",").map(function(s) { return s.trim() })
                if (parts.length < 3) return
                root.dgpu.active       = true
                root.dgpu.usagePercent = parseFloat(parts[0]) || 0
                root.dgpu.usedVram     = parts[1] + " MB"
                root.dgpu.totalVram    = parts[2] + " MB"
            }
        }
    }

    // ── Poll timers ───────────────────────────────────────────────────────────
    property var _igpuTimer: Timer {
        interval: 1000
        running:  root.active
        repeat:   true
        onTriggered: {
            _igpuProc.running = false
            _igpuProc.running = true
        }
    }

    property var _nvTimer: Timer {
        interval: 1000
        running:  root.active && root.envyMode !== "integrated" && root.hasNvidia
        repeat:   true
        onTriggered: {
            _nvProc.running = false
            _nvProc.running = true
        }
    }

    // ── dGPU active state follows envyMode ────────────────────────────────────
    onEnvyModeChanged: {
        if (envyMode === "integrated") {
            dgpu.active       = false
            dgpu.usagePercent = 0
            dgpu.usedVram     = "— MB"
            dgpu.totalVram    = "— MB"
        }
    }

    Component.onCompleted: {
        _igpuProc.running = true
        if (envyMode !== "integrated" && root.hasNvidia)
            _nvProc.running = true
    }
}
