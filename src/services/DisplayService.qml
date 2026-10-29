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

pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import "../"

// DisplayService — monitor configuration for the dashboard Display tab.
//
// Reads `hyprctl monitors all -j` (refreshed on monitor hotplug / config reload).
// apply() sets the new layout live with `hyprctl keyword monitor …`, then waits
// for confirm(): without it the previous layout is restored after 10 s.
// Confirmed layouts are written to ~/.config/Brain_Shell/monitors.conf, which
// hyprland.conf sources after its own monitor lines.

QtObject {
    id: root

    // [{ name, description, width, height, refresh, scale, x, y, disabled,
    //    mirrorOf, modes: [{ w, h, rates: [60, 144, …] }] }]
    property var monitors: []
    readonly property var primary: monitors.find(m => m.name.startsWith("eDP")) || monitors[0] || null

    property bool   awaitingConfirm: false
    property int    revertIn: 0
    property var    _prevLines: []
    property var    _newLines: []

    readonly property string confPath: Quickshell.env("HOME") + "/.config/Brain_Shell/monitors.conf"

    function refresh() { if (!_query.running) _query.running = true }

    // Mode label like the reference: 4K, QHD, FHD …
    function modeLabel(w, h) {
        var k = w + "x" + h
        var names = {
            "7680x4320": "8K", "5120x2880": "5K", "3840x2160": "4K", "3440x1440": "UWQHD",
            "3200x1800": "QHD+", "2880x1800": "3K", "2560x1600": "WQXGA", "2560x1440": "QHD",
            "2560x1080": "UWFHD", "1920x1200": "WUXGA", "1920x1080": "FHD", "1680x1050": "WSXGA+",
            "1600x900": "HD+", "1440x900": "WXGA+", "1366x768": "WXGA", "1280x800": "WXGA",
            "1280x1024": "SXGA", "1280x720": "HD", "1024x768": "XGA", "800x600": "SVGA", "640x480": "VGA"
        }
        return names[k] || ""
    }

    function fmtRate(r) { return Math.abs(r - Math.round(r)) < 0.05 ? String(Math.round(r)) : r.toFixed(2) }

    // cfg: { name, width, height, refresh, scale, x, y, disabled, mirrorOf }
    function lineFor(cfg) {
        if (cfg.disabled) return cfg.name + ",disable"
        var mode = cfg.width + "x" + cfg.height + "@" + cfg.refresh.toFixed(2)
        var pos  = cfg.mirrorOf ? "auto" : (Math.round(cfg.x) + "x" + Math.round(cfg.y))
        var l = cfg.name + "," + mode + "," + pos + "," + cfg.scale
        if (cfg.mirrorOf) l += ",mirror," + cfg.mirrorOf
        return l
    }

    // Apply a full layout (one cfg per monitor) live; needs confirm() within 10 s
    function apply(cfgs) {
        if (!awaitingConfirm) _prevLines = monitors.map(m => lineFor(m))
        _newLines = cfgs.map(c => lineFor(c))
        _run(_newLines)
        awaitingConfirm = true
        revertIn = 10
        _revertTimer.restart()
    }

    function confirm() {
        _revertTimer.stop()
        awaitingConfirm = false
        var body = "# Written by Brain_Shell (dashboard → Display). Sourced after hypr/monitors.conf.\n"
                 + _newLines.map(l => "monitor = " + l).join("\n") + "\n"
        _writeProc.command = ["bash", "-c", "mkdir -p \"$(dirname \"$1\")\" && printf '%s' \"$2\" > \"$1\"", "_", confPath, body]
        _writeProc.running = true
    }

    function revert() {
        _revertTimer.stop()
        awaitingConfirm = false
        _run(_prevLines)
    }

    function _run(lines) {
        var batch = lines.map(l => "keyword monitor " + l).join(" ; ")
        _applyProc.command = ["hyprctl", "--batch", batch]
        _applyProc.running = false
        _applyProc.running = true
    }

    function _parse(text) {
        var arr
        try { arr = JSON.parse(text) } catch (e) { return }
        root.monitors = arr.map(function(m) {
            var byRes = {}
            var order = []
            ;(m.availableModes || []).forEach(function(s) {
                var mm = /^(\d+)x(\d+)@([\d.]+)Hz$/.exec(s)
                if (!mm) return
                var k = mm[1] + "x" + mm[2]
                if (!byRes[k]) { byRes[k] = { w: +mm[1], h: +mm[2], rates: [] }; order.push(k) }
                var r = Math.round(parseFloat(mm[3]) * 100) / 100
                if (byRes[k].rates.every(x => Math.abs(x - r) > 0.05)) byRes[k].rates.push(r)
            })
            var modes = order.map(k => byRes[k])
            modes.forEach(md => md.rates.sort((a, b) => a - b))
            modes.sort((a, b) => b.w * b.h - a.w * a.h)
            return {
                name: m.name, description: m.description || "",
                width: m.width, height: m.height,
                refresh: Math.round(m.refreshRate * 100) / 100,
                scale: m.scale, x: m.x, y: m.y,
                disabled: !!m.disabled,
                mirrorOf: (m.mirrorOf && m.mirrorOf !== "none") ? m.mirrorOf : "",
                modes: modes
            }
        })
    }

    property var _query: Process {
        command: ["hyprctl", "monitors", "all", "-j"]
        running: true
        stdout: StdioCollector { onStreamFinished: root._parse(text) }
    }

    property var _applyProc: Process {
        running: false
        onExited: root._refreshTimer.restart()
    }
    property var _writeProc: Process { running: false }

    property var _refreshTimer: Timer { interval: 400; onTriggered: root.refresh() }

    property var _revertTimer: Timer {
        interval: 1000; repeat: true
        onTriggered: {
            root.revertIn--
            if (root.revertIn <= 0) root.revert()
        }
    }

    property var _events: Connections {
        target: Hyprland
        function onRawEvent(event) {
            var n = event.name
            if (n.startsWith("monitoradded") || n.startsWith("monitorremoved") || n === "configreloaded")
                root._refreshTimer.restart()
        }
    }
}
