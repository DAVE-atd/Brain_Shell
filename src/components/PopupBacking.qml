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
import "../"

// PopupBacking — opaque fill behind an expanded popup notch.
// The surface shape uses Theme.background (with the user's bar opacity). While a
// popup is open this region is drawn opaque on top of it. It is grown by `pad`
// so it also covers the curved flares where the popup joins the bar / screen
// edge; DynamicSurface clips it to the surface shape, so nothing spills out.
//
// Only opacity changes (no `visible` toggling): the layer it is rendered into
// stops updating if its content starts out invisible.

Rectangle {
    id: root

    required property Item target
    property bool shown: false
    property real pad: 0

    x: target.x - pad
    y: target.y - pad
    width:  target.width  + pad * 2
    height: target.height + pad * 2

    color: Qt.rgba(Theme.background.r, Theme.background.g, Theme.background.b, 1)
    opacity: shown ? 1 : 0
    Behavior on opacity { NumberAnimation { duration: Anim.transition; easing.type: Anim.globalCurve } }
}
