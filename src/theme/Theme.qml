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
import "."

QtObject {
    // ── Bindings to Modular Singletons ────────────────────────────────────────
    // Note: property alias cannot point to other singletons, so we use direct bindings.
    
    // Colors
    property color background: Colors.background
    property color active:     Colors.active
    // Accent hue from matugen with the saturation pushed up (bar icons, tray, monitor rings);
    // pale wallpapers otherwise give an almost-white accent
    readonly property color accentVivid: vivid(active)
    function vivid(c) {
        return Qt.hsla(c.hslHue, Math.max(c.hslSaturation, 0.85), Math.min(Math.max(c.hslLightness, 0.62), 0.70), 1)
    }

    // One colour per bar icon: matugen custom_colors (fixed hue, blended toward the wallpaper)
    readonly property color iconWifi:          vivid(Colors.cyan)
    readonly property color iconVpn:           vivid(Colors.pink)
    readonly property color iconTailscale:     vivid(Colors.pink)
    readonly property color iconBluetooth:     vivid(Colors.blue)
    readonly property color iconHotspot:       vivid(Colors.cyan)
    readonly property color iconAudio:         vivid(Colors.purple)
    readonly property color iconBattery:       vivid(Colors.green)
    readonly property color iconNotifications: vivid(Colors.yellow)
    property color text:       Colors.text
    property color subtext:    Colors.subtext
    property color icon:       Colors.icon
    property color border:     Colors.border
    property color iconFont:   Colors.iconFont
    property color error:      Colors.error
    property color errorSolid: Colors.errorSolid
    property color card:       Colors.card
    property color cardHover:  Colors.cardHover
    readonly property color netUpload:   Colors.netUpload
    readonly property color netDownload: Colors.netDownload

    property color wsBackground: Colors.wsBackground
    property color wsActive:     Colors.wsActive
    property color wsOccupied:   Colors.wsOccupied
    property color wsEmpty:      Colors.wsEmpty
    property color wsOverlay:    Colors.wsOverlay
    property color wsUrgent:     Colors.wsUrgent

    // Metrics
    property bool barEnabled: Metrics.barEnabled
    
    property int borderWidth:   Metrics.borderWidth
    property int cornerRadius:  Metrics.cornerRadius
    property int notchHeight:   Metrics.notchHeight
        
    property int notchPadding:           Metrics.notchPadding
            
    property int lNotchMinWidth: Metrics.lNotchMinWidth
    property int lNotchMaxWidth: Metrics.lNotchMaxWidth
    property int cNotchMinWidth: Metrics.cNotchMinWidth
    property int cNotchMaxWidth: Metrics.cNotchMaxWidth
    property int rNotchMinWidth: Metrics.rNotchMinWidth
    property int rNotchMaxWidth: Metrics.rNotchMaxWidth

    property int dashboardWidth:  Metrics.dashboardWidth
    property int dashboardHeight: Metrics.dashboardHeight

    property int notificationsWidth: Metrics.notificationsWidth
    property int notificationToastWidth: Metrics.notificationToastWidth
    property int networkPopupWidth:  Metrics.networkPopupWidth

    property int popupMaxWidth:   Metrics.popupMaxWidth
    property int popupMaxHeight:  Metrics.popupMaxHeight
    property int popupPadding:     Metrics.popupPadding

    property int wsDotSize:     Metrics.wsDotSize
    property int wsActiveWidth: Metrics.wsActiveWidth
    property int wsSpacing:     Metrics.wsSpacing
    property int wsPadding:     Metrics.wsPadding
    property int wsRadius:      Metrics.wsRadius

}
