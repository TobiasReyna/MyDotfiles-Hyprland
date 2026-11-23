// =============================================================================
// Paleta Material You para Quickshell generada automáticamente por `matugen`
// Wallpaper origen: {{image}}
// No editar manualmente: Quickshell detecta cambios y recarga en vivo.
// Se usa el prefijo `colorOn*` (en lugar de `on*`) para evitar colisiones con
// la sintaxis de signal handlers `on<Property>` de Qt6 QML.
// =============================================================================
pragma Singleton

import QtQuick

QtObject {
    // Ruta del wallpaper activo
    readonly property string wallpaperPath: "{{image}}"

    // Acentos principales
    readonly property color sourceColor: "{{colors.source_color.default.hex}}"
    readonly property color primary: "{{colors.primary.default.hex}}"
    readonly property color colorOnPrimary: "{{colors.on_primary.default.hex}}"
    readonly property color primaryContainer: "{{colors.primary_container.default.hex}}"
    readonly property color colorOnPrimaryContainer: "{{colors.on_primary_container.default.hex}}"

    readonly property color secondary: "{{colors.secondary.default.hex}}"
    readonly property color colorOnSecondary: "{{colors.on_secondary.default.hex}}"
    readonly property color secondaryContainer: "{{colors.secondary_container.default.hex}}"
    readonly property color colorOnSecondaryContainer: "{{colors.on_secondary_container.default.hex}}"

    readonly property color tertiary: "{{colors.tertiary.default.hex}}"
    readonly property color colorOnTertiary: "{{colors.on_tertiary.default.hex}}"
    readonly property color tertiaryContainer: "{{colors.tertiary_container.default.hex}}"
    readonly property color colorOnTertiaryContainer: "{{colors.on_tertiary_container.default.hex}}"

    // Fondo y superficies (Material Design 3)
    readonly property color background: "{{colors.background.default.hex}}"
    readonly property color colorOnBackground: "{{colors.on_background.default.hex}}"
    readonly property color surface: "{{colors.surface.default.hex}}"
    readonly property color surfaceDim: "{{colors.surface_dim.default.hex}}"
    readonly property color surfaceBright: "{{colors.surface_bright.default.hex}}"
    readonly property color surfaceVariant: "{{colors.surface_variant.default.hex}}"
    readonly property color surfaceTint: "{{colors.surface_tint.default.hex}}"
    readonly property color surfaceContainerLowest: "{{colors.surface_container_lowest.default.hex}}"
    readonly property color surfaceContainerLow: "{{colors.surface_container_low.default.hex}}"
    readonly property color surfaceContainer: "{{colors.surface_container.default.hex}}"
    readonly property color surfaceContainerHigh: "{{colors.surface_container_high.default.hex}}"
    readonly property color surfaceContainerHighest: "{{colors.surface_container_highest.default.hex}}"
    readonly property color colorOnSurface: "{{colors.on_surface.default.hex}}"
    readonly property color colorOnSurfaceVariant: "{{colors.on_surface_variant.default.hex}}"

    // Superficies inversas
    readonly property color inverseSurface: "{{colors.inverse_surface.default.hex}}"
    readonly property color inverseOnSurface: "{{colors.inverse_on_surface.default.hex}}"
    readonly property color inversePrimary: "{{colors.inverse_primary.default.hex}}"

    // Contornos, sombras y errores
    readonly property color outline: "{{colors.outline.default.hex}}"
    readonly property color outlineVariant: "{{colors.outline_variant.default.hex}}"
    readonly property color shadow: "{{colors.shadow.default.hex}}"
    readonly property color scrim: "{{colors.scrim.default.hex}}"

    readonly property color error: "{{colors.error.default.hex}}"
    readonly property color colorOnError: "{{colors.on_error.default.hex}}"
    readonly property color errorContainer: "{{colors.error_container.default.hex}}"
    readonly property color colorOnErrorContainer: "{{colors.on_error_container.default.hex}}"
}
