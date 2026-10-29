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
// The surface shape uses Theme.background (with the user's bar opacity); while a
// popup is open this layer sits behind it so only the bar itself is see-through.
// Anchor it to a notch area; the edge* flags extends it over the screen-edge border strip.

Rectangle {
    id: root

    required property Item target
    property bool shown: false
    property real edgeExtend: 0
    // which screen edges the notch touches
    property bool edgeTop: false
    property bool edgeBottom: false
    property bool edgeLeft: false
    property bool edgeRight: false

    x: target.x - (edgeLeft ? edgeExtend : 0)
    y: target.y - (edgeTop ? edgeExtend : 0)
    width:  target.width  + (edgeLeft ? edgeExtend : 0) + (edgeRight ? edgeExtend : 0)
    height: target.height + (edgeTop ? edgeExtend : 0) + (edgeBottom ? edgeExtend : 0)

    color: Qt.rgba(Theme.background.r, Theme.background.g, Theme.background.b, 1)
    opacity: shown && PrefsService.bgOpacity < 1 ? 1 : 0
    visible: opacity > 0
    Behavior on opacity { NumberAnimation { duration: Anim.transition; easing.type: Anim.globalCurve } }
}
