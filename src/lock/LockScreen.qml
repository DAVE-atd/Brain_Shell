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
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Services.Pam

// LockScreen — session lock (ext-session-lock) with PAM auth.
//
// hypridle's lock_cmd calls `brain-shell ipc call lock-screen lock`, so
// `loginctl lock-session` (keybind, power menu, idle, before sleep) ends up here.
// `lock-screen preview` shows the same surface in an overlay without locking
// (for tuning the look; Esc closes it).
//
// PAM service: /etc/pam.d/brainshell-lock (NixOS: security.pam.services.brainshell-lock).

Scope {
    id: root

    property bool   locked:  false
    property bool   preview: false
    property string password: ""
    property bool   busy:    false
    property int    failCount: 0          // bumped on every failed attempt (surfaces shake)
    property bool   menuOpen: false

    function lock() {
        if (locked) return
        password = ""; busy = false; menuOpen = false
        locked = true
    }

    function submit() {
        if (preview) { password = ""; return }
        if (busy || password === "") return
        busy = true
        pam.start()
    }

    function power(action) {
        menuOpen = false
        powerProc.command = ["systemctl", action]
        powerProc.running = true
    }

    PamContext {
        id: pam
        config: "brainshell-lock"
        onResponseRequiredChanged: if (responseRequired) respond(root.password)
        onCompleted: function(result) {
            root.busy = false
            root.password = ""
            if (result === PamResult.Success) {
                root.menuOpen = false
                root.locked = false
            } else {
                root.failCount++
            }
        }
        onError: function(err) {
            root.busy = false
            root.password = ""
            root.failCount++
        }
    }

    Process { id: powerProc; running: false }

    WlSessionLock {
        id: sessionLock
        locked: root.locked

        WlSessionLockSurface {
            color: "black"
            LockSurface { anchors.fill: parent; ctx: root }
        }
    }

    // Preview: same visuals, no lock, no auth
    LazyLoader {
        active: root.preview
        PanelWindow {
            screen: Quickshell.screens[0]
            anchors { top: true; bottom: true; left: true; right: true }
            exclusionMode: ExclusionMode.Ignore
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.namespace: "brain-shell-lock-preview"
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
            color: "black"
            LockSurface { anchors.fill: parent; ctx: root }
        }
    }

    IpcHandler {
        target: "lock-screen"
        function lock() { root.lock() }
        function preview() { root.password = ""; root.preview = !root.preview }
        function menu() { root.menuOpen = !root.menuOpen }   // for screenshots
        function type(text: string) { root.password = text } // preview: show dots
    }
}
