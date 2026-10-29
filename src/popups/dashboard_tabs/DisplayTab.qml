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
import "../../services"
import "../../"

// DisplayTab — dashboard page for monitor settings.
// Left: the connected monitors as drawn screens (click to select).
// Right: resolution presets, refresh-rate slider, scale, and for extra monitors
// position / mirror / enable. Apply sets it live; a bar asks to keep it
// (DisplayService reverts after 10 s otherwise).

Item {
    id: root
    property real localScale: 1.0
    function s(v) { return Math.round(v * localScale) }

    readonly property var mons: DisplayService.monitors
    property string selName: ""
    readonly property var sel: mons.find(m => m.name === selName) || DisplayService.primary
    readonly property bool selIsPrimary: !!(sel && DisplayService.primary && sel.name === DisplayService.primary.name)

    // Unapplied edits per monitor: { w, h, refresh, scale, pos, enabled }
    property var drafts: ({})
    function draftOf(m) {
        if (!m) return null
        return drafts[m.name] || { w: m.width, h: m.height, refresh: m.refresh, scale: m.scale,
                                   pos: m.mirrorOf ? "mirror" : "keep", enabled: !m.disabled }
    }
    function setDraft(key, value) {
        if (!sel) return
        var d = Object.assign({}, draftOf(sel))
        d[key] = value
        if (key === "w" || key === "h") {
            // keep the refresh rate if this resolution has it, else take the highest
            var md = sel.modes.find(x => x.w === d.w && x.h === d.h)
            if (md && md.rates.every(r => Math.abs(r - d.refresh) > 0.05)) d.refresh = md.rates[md.rates.length - 1]
        }
        var all = Object.assign({}, drafts); all[sel.name] = d; drafts = all
    }
    readonly property var d: draftOf(sel)
    readonly property var curMode: sel && d ? sel.modes.find(x => x.w === d.w && x.h === d.h) : null
    readonly property bool dirty: {
        for (var i = 0; i < mons.length; i++) {
            var m = mons[i], x = drafts[m.name]
            if (!x) continue
            if (x.w !== m.width || x.h !== m.height || Math.abs(x.refresh - m.refresh) > 0.05
                || x.scale !== m.scale || x.pos !== (m.mirrorOf ? "mirror" : "keep") || x.enabled === m.disabled) return true
        }
        return false
    }

    function applyAll() {
        var p = DisplayService.primary
        var pd = draftOf(p)
        var pw = Math.round(pd.w / pd.scale), ph = Math.round(pd.h / pd.scale)
        var cfgs = mons.map(function(m) {
            var x = draftOf(m)
            var c = { name: m.name, width: x.w, height: x.h, refresh: x.refresh, scale: x.scale,
                      x: m.x, y: m.y, disabled: !x.enabled, mirrorOf: "" }
            if (m.name !== p.name) {
                var w = Math.round(x.w / x.scale), h = Math.round(x.h / x.scale)
                if (x.pos === "left")  { c.x = p.x - w;  c.y = p.y }
                if (x.pos === "right") { c.x = p.x + pw; c.y = p.y }
                if (x.pos === "above") { c.x = p.x;      c.y = p.y - h }
                if (x.pos === "below") { c.x = p.x;      c.y = p.y + ph }
                if (x.pos === "mirror") c.mirrorOf = p.name
            }
            return c
        })
        DisplayService.apply(cfgs)
        drafts = ({})
    }

    property bool hasGnd: false
    Process {
        command: ["sh", "-c", "command -v gnome-network-displays"]
        running: true
        onExited: function(code) { root.hasGnd = code === 0 }
    }

    // ── Left: monitors ────────────────────────────────────────────────────────
    Item {
        id: stage
        anchors { left: parent.left; top: parent.top; bottom: parent.bottom; leftMargin: s(24); topMargin: s(16); bottomMargin: s(16) }
        width: parent.width * 0.42

        Row {
            anchors.centerIn: parent
            anchors.verticalCenterOffset: -s(10)
            spacing: s(16)
            Repeater {
                model: root.mons
                delegate: Item {
                    required property var modelData
                    readonly property bool isSel: root.sel && modelData.name === root.sel.name
                    readonly property var dd: root.draftOf(modelData)
                    readonly property real screenW: Math.min(stage.width / Math.max(1, root.mons.length) - s(16), s(300))
                    width: screenW; height: screenW * 0.62 + s(44)
                    opacity: dd.enabled ? 1 : 0.45

                    Rectangle {
                        id: scr
                        width: parent.width; height: parent.screenW * 0.62
                        radius: s(10)
                        color: isSel ? Qt.rgba(Theme.active.r, Theme.active.g, Theme.active.b, 0.10) : Theme.card
                        border.width: s(2)
                        border.color: isSel ? Qt.rgba(Theme.active.r, Theme.active.g, Theme.active.b, 0.55) : Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.10)
                        Behavior on color { ColorAnimation { duration: Anim.normal } }
                        Behavior on border.color { ColorAnimation { duration: Anim.normal } }
                        Column {
                            anchors.centerIn: parent
                            spacing: s(6)
                            Text { anchors.horizontalCenter: parent.horizontalCenter; text: "󰍹"; font.pixelSize: s(30); color: isSel ? Theme.active : Theme.subtext }
                            Text { anchors.horizontalCenter: parent.horizontalCenter; text: modelData.name; font.pixelSize: s(15); font.weight: Font.Bold; color: Theme.text }
                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: dd.enabled ? dd.w + "x" + dd.h + " @ " + DisplayService.fmtRate(dd.refresh) + "Hz" : "Disabled"
                                font.pixelSize: s(11); font.family: "JetBrains Mono"
                                color: Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.55)
                            }
                        }
                        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.selName = modelData.name }
                    }
                    // stand
                    Rectangle { anchors { top: scr.bottom; horizontalCenter: scr.horizontalCenter } width: s(14); height: s(22); color: Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.12) }
                    Rectangle { anchors { top: scr.bottom; topMargin: s(22); horizontalCenter: scr.horizontalCenter } width: scr.width * 0.28; height: s(6); radius: s(3); color: Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.12) }
                }
            }
        }

        Text {
            anchors { horizontalCenter: parent.horizontalCenter; bottom: parent.bottom }
            text: root.sel ? root.sel.description : ""
            font.pixelSize: s(10)
            color: Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.35)
            elide: Text.ElideRight; width: parent.width; horizontalAlignment: Text.AlignHCenter
        }
    }

    // ── Right: settings ───────────────────────────────────────────────────────
    Item {
        id: panel
        anchors { left: stage.right; right: parent.right; top: parent.top; bottom: parent.bottom
                  leftMargin: s(28); rightMargin: s(24); topMargin: s(16); bottomMargin: s(16) }

        Column {
            id: col
            width: parent.width
            spacing: s(14)

            // Resolution presets
            Flickable {
                width: parent.width
                height: Math.min(grid.height, s(190))
                contentHeight: grid.height
                clip: true
                boundsBehavior: Flickable.StopAtBounds
                Grid {
                    id: grid
                    width: parent.width
                    columns: 2
                    columnSpacing: s(10); rowSpacing: s(8)
                    Repeater {
                        model: root.sel ? root.sel.modes : []
                        delegate: Rectangle {
                            required property var modelData
                            readonly property bool on: root.d && modelData.w === root.d.w && modelData.h === root.d.h
                            width: (grid.width - grid.columnSpacing) / 2; height: s(40)
                            radius: s(10)
                            color: on ? Qt.rgba(Theme.active.r, Theme.active.g, Theme.active.b, 0.14) : (mh.hovered ? Theme.cardHover : Theme.card)
                            border.width: on ? s(1.5) : 0
                            border.color: Qt.rgba(Theme.active.r, Theme.active.g, Theme.active.b, 0.6)
                            Behavior on color { ColorAnimation { duration: Anim.normal } }
                            Text {
                                anchors { left: parent.left; leftMargin: s(14); verticalCenter: parent.verticalCenter }
                                text: DisplayService.modeLabel(modelData.w, modelData.h) || "—"
                                font.pixelSize: s(13); font.weight: Font.Bold; font.family: "JetBrains Mono"
                                color: parent.on ? Theme.active : Theme.text
                            }
                            Text {
                                anchors { right: parent.right; rightMargin: s(14); verticalCenter: parent.verticalCenter }
                                text: modelData.w + "x" + modelData.h
                                font.pixelSize: s(11); font.family: "JetBrains Mono"
                                color: Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, parent.on ? 0.85 : 0.55)
                            }
                            HoverHandler { id: mh; cursorShape: Qt.PointingHandCursor }
                            MouseArea { anchors.fill: parent; onClicked: { root.setDraft("w", modelData.w); root.setDraft("h", modelData.h) } }
                        }
                    }
                }
            }

            // Refresh rate
            Item {
                id: rateBox
                width: parent.width; height: s(52)
                readonly property var rates: root.curMode ? root.curMode.rates : []
                readonly property int idx: {
                    if (!root.d) return 0
                    for (var i = 0; i < rates.length; i++) if (Math.abs(rates[i] - root.d.refresh) < 0.05) return i
                    return rates.length - 1
                }
                readonly property real frac: rates.length > 1 ? idx / (rates.length - 1) : 1
                Item {
                    id: track
                    width: parent.width; height: s(22)
                    Rectangle { anchors.verticalCenter: parent.verticalCenter; width: parent.width; height: s(10); radius: height / 2; color: Theme.card }
                    Rectangle {
                        anchors.verticalCenter: parent.verticalCenter
                        width: s(10) + (parent.width - s(10)) * rateBox.frac; height: s(10); radius: height / 2
                        color: Theme.active
                        Behavior on width { NumberAnimation { duration: Anim.normal; easing.type: Easing.OutCubic } }
                    }
                    Rectangle {
                        width: s(22); height: width; radius: width / 2
                        x: (parent.width - width) * rateBox.frac
                        color: Theme.text
                        Behavior on x { NumberAnimation { duration: Anim.normal; easing.type: Easing.OutCubic } }
                    }
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        enabled: rateBox.rates.length > 1
                        function pick(mx) {
                            var i = Math.round(Math.max(0, Math.min(1, mx / width)) * (rateBox.rates.length - 1))
                            root.setDraft("refresh", rateBox.rates[i])
                        }
                        onPressed: (m) => pick(m.x)
                        onPositionChanged: (m) => { if (pressed) pick(m.x) }
                    }
                }
                Repeater {
                    model: rateBox.rates
                    delegate: Text {
                        required property var modelData
                        required property int index
                        y: track.height + s(8)
                        x: rateBox.rates.length > 1 ? (rateBox.width - width) * index / (rateBox.rates.length - 1) : rateBox.width - width
                        text: DisplayService.fmtRate(modelData)
                        font.pixelSize: s(11); font.family: "JetBrains Mono"
                        color: index === rateBox.idx ? Theme.active : Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.55)
                    }
                }
            }

            // Scale
            OptionRow {
                label: "Scale"
                options: [1, 1.25, 1.5, 2].map(v => ({ key: v, text: v + "×" }))
                current: root.d ? root.d.scale : 1
                onPicked: (k) => root.setDraft("scale", k)
            }

            // Position / mirror (extra monitors only)
            OptionRow {
                visible: !root.selIsPrimary
                label: "Position"
                options: [
                    { key: "keep",   text: "Keep"   }, { key: "left",  text: "Left"  },
                    { key: "right",  text: "Right"  }, { key: "above", text: "Above" },
                    { key: "below",  text: "Below"  }, { key: "mirror", text: "Mirror" }
                ]
                current: root.d ? root.d.pos : "keep"
                onPicked: (k) => root.setDraft("pos", k)
            }
            OptionRow {
                visible: !root.selIsPrimary
                label: "Output"
                options: [{ key: true, text: "On" }, { key: false, text: "Off" }]
                current: root.d ? root.d.enabled : true
                onPicked: (k) => root.setDraft("enabled", k)
            }
        }

        // Bottom: wireless + apply
        Rectangle {
            visible: root.hasGnd
            anchors { left: parent.left; bottom: parent.bottom }
            width: wlRow.implicitWidth + s(28); height: s(44); radius: height / 2
            color: wlHov.hovered ? Theme.cardHover : Theme.card
            Row {
                id: wlRow
                anchors.centerIn: parent; spacing: s(8)
                Text { text: "󰐻"; font.pixelSize: s(15); color: Theme.active; anchors.verticalCenter: parent.verticalCenter }
                Text { text: "Wireless display"; font.pixelSize: s(12); color: Theme.text; anchors.verticalCenter: parent.verticalCenter }
            }
            HoverHandler { id: wlHov; cursorShape: Qt.PointingHandCursor }
            MouseArea { anchors.fill: parent; onClicked: { Quickshell.execDetached(["gnome-network-displays"]); SurfaceState.close() } }
        }

        Rectangle {
            id: applyBtn
            anchors { right: parent.right; bottom: parent.bottom }
            width: s(150); height: s(44); radius: height / 2
            opacity: root.dirty ? 1 : 0.35
            Behavior on opacity { NumberAnimation { duration: Anim.normal } }
            gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop { position: 0; color: Qt.darker(Theme.active, 1.6) }
                GradientStop { position: 1; color: Theme.active }
            }
            Row {
                anchors.centerIn: parent; spacing: s(8)
                Text { text: "󰄬"; font.pixelSize: s(15); color: Theme.background; anchors.verticalCenter: parent.verticalCenter }
                Text { text: "Apply"; font.pixelSize: s(13); font.weight: Font.Bold; color: Theme.background; anchors.verticalCenter: parent.verticalCenter }
            }
            HoverHandler { cursorShape: root.dirty ? Qt.PointingHandCursor : Qt.ArrowCursor }
            MouseArea { anchors.fill: parent; enabled: root.dirty; onClicked: root.applyAll() }
        }
    }

    // ── Keep / revert bar ─────────────────────────────────────────────────────
    Rectangle {
        anchors { horizontalCenter: parent.horizontalCenter; bottom: parent.bottom; bottomMargin: s(14) }
        width: keepRow.implicitWidth + s(24); height: s(48); radius: height / 2
        color: Theme.background
        border.color: Qt.rgba(Theme.active.r, Theme.active.g, Theme.active.b, 0.4)
        opacity: DisplayService.awaitingConfirm ? 1 : 0
        visible: opacity > 0
        z: 10
        Behavior on opacity { NumberAnimation { duration: Anim.normal } }
        Row {
            id: keepRow
            anchors.centerIn: parent; spacing: s(12)
            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: "Keep these settings? Reverting in " + DisplayService.revertIn + " s"
                font.pixelSize: s(12); color: Theme.text
            }
            Pill { text: "Revert"; onClicked: DisplayService.revert() }
            Pill { text: "Keep"; accent: true; onClicked: DisplayService.confirm() }
        }
    }

    component Pill: Rectangle {
        property string text
        property bool accent: false
        signal clicked()
        width: pt.implicitWidth + s(24); height: s(32); radius: height / 2
        color: accent ? Theme.active : (ph.hovered ? Theme.cardHover : Theme.card)
        Text { id: pt; anchors.centerIn: parent; text: parent.text; font.pixelSize: s(12); font.weight: Font.Bold; color: parent.accent ? Theme.background : Theme.text }
        HoverHandler { id: ph; cursorShape: Qt.PointingHandCursor }
        MouseArea { anchors.fill: parent; onClicked: parent.clicked() }
    }

    component OptionRow: Item {
        id: orow
        property string label
        property var options: []
        property var current
        signal picked(var key)
        width: col.width; height: s(32)
        Text {
            anchors.verticalCenter: parent.verticalCenter
            width: s(70)
            text: orow.label
            font.pixelSize: s(11); font.weight: Font.Bold
            color: Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.55)
        }
        Row {
            anchors { left: parent.left; leftMargin: s(76); verticalCenter: parent.verticalCenter }
            spacing: s(6)
            Repeater {
                model: orow.options
                delegate: Rectangle {
                    required property var modelData
                    readonly property bool on: modelData.key === orow.current
                    width: ot.implicitWidth + s(18); height: s(28); radius: s(8)
                    color: on ? Qt.rgba(Theme.active.r, Theme.active.g, Theme.active.b, 0.16) : (oh.hovered ? Theme.cardHover : Theme.card)
                    Behavior on color { ColorAnimation { duration: Anim.normal } }
                    Text { id: ot; anchors.centerIn: parent; text: modelData.text; font.pixelSize: s(11); color: parent.on ? Theme.active : Theme.text }
                    HoverHandler { id: oh; cursorShape: Qt.PointingHandCursor }
                    MouseArea { anchors.fill: parent; onClicked: orow.picked(modelData.key) }
                }
            }
        }
    }
}
