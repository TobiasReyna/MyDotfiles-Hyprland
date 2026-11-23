-- =============================================================================
-- Paleta de colores base — Material You (oscuro neutro)
--
-- NOTA: Este archivo provee valores fallback iniciales y será sobrescrito
-- dinámicamente por `matugen` en la siguiente fase a partir del wallpaper.
-- Todos los valores usan formato `rgba(rrggbbaa)` compatible con Hyprland.
-- =============================================================================

return {
    -- Acentos principales
    primary             = "rgba(b8c4e0ff)",
    primary_container   = "rgba(384560ff)",
    on_primary          = "rgba(222f47ff)",

    secondary           = "rgba(c2c6d4ff)",
    secondary_container = "rgba(424652ff)",
    on_secondary        = "rgba(2c303bff)",

    tertiary            = "rgba(d4c0d8ff)",
    tertiary_container  = "rgba(504154ff)",
    on_tertiary         = "rgba(392c3dff)",

    -- Superficies y fondo (Material 3 Dark Neutral)
    background             = "rgba(131316ff)",
    on_background          = "rgba(e4e2e6ff)",
    surface                = "rgba(1b1b1fff)",
    surface_dim            = "rgba(131316ff)",
    surface_bright         = "rgba(39393dff)",
    surface_container      = "rgba(1f1f24ff)",
    surface_container_high = "rgba(2a2a2fff)",
    on_surface             = "rgba(e4e2e6ff)",
    on_surface_variant     = "rgba(c5c6d0ff)",

    -- Bordes, contornos y sombras
    outline         = "rgba(8e9099ff)",
    outline_variant = "rgba(44474faa)",
    shadow          = "rgba(00000077)",

    -- Estados semánticos
    error           = "rgba(ffb4abff)",
    error_container = "rgba(93000aff)",
}
