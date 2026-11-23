-- =============================================================================
-- Apariencia general, decoraciones, blur, sombras, misc y cursor
-- Estética limpia estilo Caelestia con colores dinámicos desde `colors.lua`.
-- =============================================================================

local colors = require("colors")

hl.config({
    general = {
        gaps_in     = 5,
        gaps_out    = 10,
        border_size = 2,

        col = {
            active_border = {
                colors = { colors.primary, colors.secondary },
                angle  = 45,
            },
            inactive_border = colors.outline_variant,
        },

        resize_on_border = false,
        -- Activar (`true`) si deseás habilitar tearing junto a la regla `immediate` en juegos
        allow_tearing    = false,
        layout           = "dwindle",
    },

    dwindle = {
        preserve_split = true,
    },

    decoration = {
        rounding         = 12,
        rounding_power   = 2,
        active_opacity   = 1.0,
        inactive_opacity = 1.0,
        dim_inactive     = false,

        blur = {
            enabled           = true,
            xray              = false,
            size              = 6,
            passes            = 3,
            new_optimizations = true,
            ignore_opacity    = true,
            vibrancy          = 0.1696,
            popups            = true,
        },

        shadow = {
            enabled      = true,
            range        = 12,
            render_power = 3,
            color        = colors.shadow,
        },
    },

    misc = {
        disable_hyprland_logo    = true,
        disable_splash_rendering = true,
        force_default_wallpaper  = 0,
        background_color         = colors.background,
    },

    -- En Hyprland 0.57+, `vfr` (Variable Frame Rate) vive bajo `debug.vfr`
    debug = {
        vfr = true,
    },

    cursor = {
        -- Cambiar a `true` (o `1`) si el cursor parpadea o desaparece en NVIDIA;
        -- `2` habilita detección automática.
        no_hardware_cursors = false,
    },

    -- Evita que apps XWayland (Steam, juegos, apps legacy) se vean borrosas con
    -- escalado fraccional (1.25).
    xwayland = {
        force_zero_scaling = true,
    },
})
