-- =============================================================================
-- Monitores y VRR (Variable Refresh Rate)
-- =============================================================================

-- Regla genérica por defecto: resolución y tasa de refresco preferidas por el
-- panel (incluyendo pantallas integradas de alta tasa de refresco), posición
-- automática y escala fraccional 1.25.
hl.monitor({
    output   = "",
    mode     = "preferred",
    position = "auto",
    scale    = 1.25,
    -- VRR por monitor: 0 = off, 1 = siempre activo, 2 = solo en fullscreen (ideal gaming)
    vrr      = 2,
})

-- Ejemplo explícito para pantalla integrada de laptop de 144Hz:
-- hl.monitor({
--     output   = "eDP-1",
--     mode     = "1920x1200@144",
--     position = "0x0",
--     scale    = 1.25,
--     vrr      = 2,
-- })

-- Ejemplo para monitor externo conectado por HDMI o DisplayPort a la derecha:
-- hl.monitor({
--     output   = "HDMI-A-1",
--     mode     = "preferred",
--     position = "auto-right",
--     scale    = 1,
--     vrr      = 2,
-- })

-- Configuración global de VRR como respaldo (2 = solo fullscreen; cambiar a 1
-- si preferís VRR activo en todo el escritorio).
hl.config({
    misc = {
        vrr = 2,
    },
})
