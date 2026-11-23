// =============================================================================
// Paleta Material You fallback para Quickshell (modo oscuro neutro)
// NOTA: Este archivo será sobrescrito dinámicamente por `matugen` usando
// `config/matugen/templates/quickshell-colors.qml`.
// Se usa el prefijo `colorOn*` (en lugar de `on*`) para evitar colisiones con
// la sintaxis de signal handlers `on<Property>` de Qt6 QML.
// =============================================================================
pragma Singleton

import QtQuick

QtObject {
    // Ruta del wallpaper activo
    readonly property string wallpaperPath: ""

    // Acentos principales
    readonly property color sourceColor: "#b8c4e0"
    readonly property color primary: "#b8c4e0"
    readonly property color colorOnPrimary: "#222f47"
    readonly property color primaryContainer: "#384560"
    readonly property color colorOnPrimaryContainer: "#d8e2ff"

    readonly property color secondary: "#c2c6d4"
    readonly property color colorOnSecondary: "#2c303b"
    readonly property color secondaryContainer: "#424652"
    readonly property color colorOnSecondaryContainer: "#dee2f0"

    readonly property color tertiary: "#d4c0d8"
    readonly property color colorOnTertiary: "#392c3d"
    readonly property color tertiaryContainer: "#504154"
    readonly property color colorOnTertiaryContainer: "#f1dcf5"

    // Fondo y superficies (Material Design 3)
    readonly property color background: "#131316"
    readonly property color colorOnBackground: "#e4e2e6"
    readonly property color surface: "#1b1b1f"
    readonly property color surfaceDim: "#131316"
    readonly property color surfaceBright: "#39393d"
    readonly property color surfaceVariant: "#44474f"
    readonly property color surfaceTint: "#b8c4e0"
    readonly property color surfaceContainerLowest: "#0e0e11"
    readonly property color surfaceContainerLow: "#1b1b1f"
    readonly property color surfaceContainer: "#1f1f24"
    readonly property color surfaceContainerHigh: "#2a2a2f"
    readonly property color surfaceContainerHighest: "#35353a"
    readonly property color colorOnSurface: "#e4e2e6"
    readonly property color colorOnSurfaceVariant: "#c5c6d0"

    // Superficies inversas
    readonly property color inverseSurface: "#e4e2e6"
    readonly property color inverseOnSurface: "#303034"
    readonly property color inversePrimary: "#4f5d7a"

    // Contornos, sombras y errores
    readonly property color outline: "#8e9099"
    readonly property color outlineVariant: "#44474f"
    readonly property color shadow: "#000000"
    readonly property color scrim: "#000000"

    readonly property color error: "#ffb4ab"
    readonly property color colorOnError: "#690005"
    readonly property color errorContainer: "#93000a"
    readonly property color colorOnErrorContainer: "#ffdad6"
}
