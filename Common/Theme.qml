pragma Singleton
import QtQuick
import "../src" as BS

// DMS Theme tokens derived from Brain Shell's Theme (matugen colors).
QtObject {
    id: root

    readonly property bool isLightMode: BS.PrefsService.darkMode === false

    function withAlpha(c, a) { return Qt.rgba(c.r, c.g, c.b, a) }
    function _mix(a, b, t) { return Qt.rgba(a.r + (b.r - a.r) * t, a.g + (b.g - a.g) * t, a.b + (b.b - a.b) * t, 1) }
    function snap(value, dpr) { const s = dpr || 1; return Math.round(value * s) / s }

    readonly property color _bg: Qt.rgba(BS.Theme.background.r, BS.Theme.background.g, BS.Theme.background.b, 1)

    readonly property color primary:     BS.Theme.active
    readonly property color primaryText: _bg
    readonly property color secondary:   _mix(BS.Theme.active, BS.Theme.text, 0.45)
    readonly property color tertiary:    BS.Theme.subtext
    readonly property color error:       BS.Theme.error
    readonly property color errorText:   _bg
    readonly property color success:     "#a6e3a1"
    readonly property color warning:     "#f9e2af"
    readonly property color info:        "#89b4fa"

    readonly property color surface:                 _bg
    readonly property color surfaceContainer:        _mix(_bg, BS.Theme.text, 0.06)
    readonly property color surfaceContainerHigh:    _mix(_bg, BS.Theme.text, 0.10)
    readonly property color surfaceContainerHighest: _mix(_bg, BS.Theme.text, 0.15)
    readonly property color outline:                 withAlpha(BS.Theme.text, 0.35)
    readonly property color surfaceText:             BS.Theme.text
    readonly property color surfaceVariantText:      BS.Theme.subtext
    readonly property color widgetIconColor:         BS.Theme.text

    readonly property real fontSizeSmall:  12
    readonly property real fontSizeMedium: 14
    readonly property real fontSizeLarge:  16
    readonly property real fontSizeXLarge: 20
    readonly property real spacingXS: 4
    readonly property real spacingS:  8
    readonly property real spacingM:  12
    readonly property real spacingL:  16
    readonly property real spacingXL: 24
    readonly property real cornerRadius: BS.Theme.cornerRadius
}
