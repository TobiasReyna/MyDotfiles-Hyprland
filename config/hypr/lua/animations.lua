-- =============================================================================
-- Animaciones y curvas Bezier — Estilo Caelestia / Material Expressive
-- Fluidas, orgánicas y rápidas sin sensación de lag.
-- =============================================================================

hl.config({
    animations = {
        enabled = true,
    },
})

-- Curvas Bezier (Material Design 3 Expressive)
hl.curve("expressiveFastSpatial",    { type = "bezier", points = { { 0.42, 1.67 }, { 0.21, 0.90 } } })
hl.curve("expressiveDefaultSpatial", { type = "bezier", points = { { 0.38, 1.21 }, { 0.22, 1.00 } } })
hl.curve("emphasizedDecel",          { type = "bezier", points = { { 0.05, 0.70 }, { 0.10, 1.00 } } })
hl.curve("md3_decel",                { type = "bezier", points = { { 0.05, 0.80 }, { 0.10, 1.00 } } })
hl.curve("almostLinear",             { type = "bezier", points = { { 0.50, 0.50 }, { 0.75, 1.00 } } })

-- Árbol de animaciones
hl.animation({ leaf = "global",           enabled = true, speed = 4,   bezier = "emphasizedDecel" })

-- Bordes
hl.animation({ leaf = "border",           enabled = true, speed = 5,   bezier = "emphasizedDecel" })

-- Ventanas
hl.animation({ leaf = "windows",          enabled = true, speed = 4.2, bezier = "expressiveDefaultSpatial" })
hl.animation({ leaf = "windowsIn",        enabled = true, speed = 3.8, bezier = "expressiveDefaultSpatial", style = "popin 85%" })
hl.animation({ leaf = "windowsOut",       enabled = true, speed = 2.6, bezier = "md3_decel",                style = "popin 85%" })
hl.animation({ leaf = "windowsMove",      enabled = true, speed = 3.6, bezier = "expressiveFastSpatial" })

-- Desvanecimientos
hl.animation({ leaf = "fade",             enabled = true, speed = 3.0, bezier = "md3_decel" })
hl.animation({ leaf = "fadeIn",           enabled = true, speed = 2.6, bezier = "md3_decel" })
hl.animation({ leaf = "fadeOut",          enabled = true, speed = 2.0, bezier = "almostLinear" })

-- Capas (popups, barra y overlays de Quickshell)
hl.animation({ leaf = "layers",           enabled = true, speed = 3.5, bezier = "emphasizedDecel" })
hl.animation({ leaf = "layersIn",         enabled = true, speed = 3.2, bezier = "expressiveDefaultSpatial", style = "popin 85%" })
hl.animation({ leaf = "layersOut",        enabled = true, speed = 2.0, bezier = "md3_decel",                style = "fade" })
hl.animation({ leaf = "fadeLayersIn",     enabled = true, speed = 2.5, bezier = "md3_decel" })
hl.animation({ leaf = "fadeLayersOut",    enabled = true, speed = 1.8, bezier = "almostLinear" })

-- Workspaces
hl.animation({ leaf = "workspaces",       enabled = true, speed = 3.6, bezier = "emphasizedDecel",          style = "slidefade 20%" })
hl.animation({ leaf = "workspacesIn",     enabled = true, speed = 3.4, bezier = "emphasizedDecel",          style = "slidefade 20%" })
hl.animation({ leaf = "workspacesOut",    enabled = true, speed = 3.0, bezier = "md3_decel",                style = "slidefade 20%" })
hl.animation({ leaf = "specialWorkspace", enabled = true, speed = 3.4, bezier = "emphasizedDecel",          style = "slidefadevert -20%" })
