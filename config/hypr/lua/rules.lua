-- =============================================================================
-- Reglas de ventanas y capas (Hyprland 0.57+ Lua API)
-- =============================================================================

-- -----------------------------------------------------------------------------
-- Reglas base de higiene
-- -----------------------------------------------------------------------------
hl.window_rule({
    name           = "suppress-maximize-events",
    match          = { class = ".*" },
    suppress_event = "maximize",
})

hl.window_rule({
    name  = "fix-xwayland-drags",
    match = {
        class      = "^$",
        title      = "^$",
        xwayland   = true,
        float      = true,
        fullscreen = false,
        pin        = false,
    },
    no_focus = true,
})

-- -----------------------------------------------------------------------------
-- Terminal Ghostty: opacidad sutil para aprovechar el blur de Hyprland
-- -----------------------------------------------------------------------------
hl.window_rule({
    name    = "ghostty-opacity",
    match   = { class = "^(com\\.mitchellh\\.ghostty|ghostty)$" },
    opacity = "0.90 0.85",
})

-- -----------------------------------------------------------------------------
-- Satty: editor de capturas flotante y centrado
-- -----------------------------------------------------------------------------
hl.window_rule({
    name   = "satty-float-center",
    match  = { class = "^(com\\.gabm\\.satty|org\\.satty\\.satty|satty)$" },
    float  = true,
    center = true,
})

-- -----------------------------------------------------------------------------
-- Diálogos del sistema y selectores de archivos en modo flotante
-- -----------------------------------------------------------------------------
hl.window_rule({
    name   = "portal-gtk-float",
    match  = { class = "^(xdg-desktop-portal-gtk)$" },
    float  = true,
    center = true,
})

hl.window_rule({
    name   = "hyprpolkitagent-float",
    match  = { class = "^(hyprpolkitagent)$" },
    float  = true,
    center = true,
})

hl.window_rule({
    name   = "file-dialogs-float",
    match  = { title = "^(Abrir|Guardar|Seleccionar|Open|Save|Select|Choose).*$" },
    float  = true,
    center = true,
})

-- -----------------------------------------------------------------------------
-- Gaming (Steam): mínima latencia y sin efectos de compositor innecesarios
-- -----------------------------------------------------------------------------
hl.window_rule({
    name      = "steam-games-performance",
    match     = { class = "^steam_app_.*$" },
    immediate = true, -- Permite tearing si `general.allow_tearing = true`
    no_blur   = true,
    no_anim   = true,
    no_shadow = true,
    opaque    = true,
})

-- -----------------------------------------------------------------------------
-- Reglas de capas (Quickshell)
-- -----------------------------------------------------------------------------
hl.layer_rule({
    name         = "quickshell-blur",
    match        = { namespace = "^quickshell.*$" },
    blur         = true,
    blur_popups  = true,
    ignore_alpha = 0.2,
})
