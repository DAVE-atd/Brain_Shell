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
import Quickshell.Hyprland
import "../"
import "../services"
import "wallpaper_carousel"

// Fullscreen skewed wallpaper carousel (wallpaper_carousel/Carousel.qml),
// wired to WallpaperService: lists WallpaperService.wallpaperDir and applies
// the pick through WallpaperService.apply() (awww + matugen).
// Opened with the "wallpaper-toggle" IPC target.

Carousel {
    id: root

    wlrNamespace: "brain-shell-wallpaper-carousel"

    defaultWallpaperFolder: {
        var d = WallpaperService.wallpaperDir || ""
        if (d.indexOf("~/") === 0) d = Quickshell.env("HOME") + d.substring(1)
        return d.replace(/\/+$/, "")
    }
    currentWallpaperPath: WallpaperService.currentWall
    hasWallpaperConfigured: WallpaperService.wallpaperDir !== ""
    shellSettingsHint: "Set a wallpaper folder in the Brain Shell wallpaper popup first."

    cfg: ({
        carouselMode:   "wrap",
        itemWidth:      300,
        itemHeight:     420,
        borderWidth:    3,
        overlayOpacity: 70,
        selectedScale:  110
    })

    getFocusedScreen: () => {
        var name = Hyprland.focusedMonitor ? Hyprland.focusedMonitor.name : ""
        var screens = Quickshell.screens
        for (var i = 0; i < screens.length; i++)
            if (screens[i].name === name) return screens[i]
        return screens.length ? screens[0] : null
    }

    onWallpaperPicked: (fullPath, screenName) => WallpaperService.apply(fullPath)
}
