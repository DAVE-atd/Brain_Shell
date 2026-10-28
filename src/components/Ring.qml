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
import QtQuick.Shapes
import "../"

// Ring — circular gauge drawn with Shapes (no shader).
//
//   value       0..1, animated
//   gap         degrees left open at the bottom (0 = full circle)
//   thickness   stroke width in px
//   color / trackColor
//
// The arc starts at the bottom-left end of the gap (or 12 o'clock for a full
// circle) and fills clockwise.

Item {
    id: root

    property real  value:      0
    property real  gap:        0
    property real  thickness:  2
    property color color:      Theme.active
    property color trackColor: Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.12)
    property int   duration:   Anim.slow

    readonly property real span:  360 - gap
    readonly property real start: gap > 0 ? 90 + gap / 2 : -90
    readonly property real radius: Math.min(width, height) / 2 - thickness / 2
    property real _shown: Math.max(0, Math.min(1, isNaN(value) ? 0 : value))
    Behavior on _shown { NumberAnimation { duration: root.duration; easing.type: Easing.OutCubic } }

    Shape {
        anchors.fill: parent
        preferredRendererType: Shape.CurveRenderer

        ShapePath {
            fillColor: "transparent"
            strokeColor: root.trackColor
            strokeWidth: root.thickness
            capStyle: ShapePath.RoundCap
            PathAngleArc {
                centerX: root.width / 2; centerY: root.height / 2
                radiusX: root.radius;    radiusY: root.radius
                startAngle: root.start;  sweepAngle: root.span
            }
        }

        ShapePath {
            fillColor: "transparent"
            strokeColor: root._shown > 0.002 ? root.color : "transparent"
            strokeWidth: root.thickness
            capStyle: ShapePath.RoundCap
            PathAngleArc {
                centerX: root.width / 2; centerY: root.height / 2
                radiusX: root.radius;    radiusY: root.radius
                startAngle: root.start;  sweepAngle: root.span * root._shown
            }
        }
    }
}
