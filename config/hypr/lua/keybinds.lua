-- =============================================================================
-- Atajos de teclado, mouse y teclas multimedia (Hyprland 0.57+ Lua API)
--
-- Los comentarios `-- @bind Categoría | Combinación | Descripción` actúan como
-- fuente única de verdad para el visor interactivo `KeybindsPopup` (SUPER + K).
-- =============================================================================

local mod = "SUPER"

-- -----------------------------------------------------------------------------
-- Aplicaciones
-- -----------------------------------------------------------------------------
-- @bind Aplicaciones | SUPER + Enter | Abrir terminal Ghostty
hl.bind(mod .. " + Return", hl.dsp.exec_cmd("ghostty"), { desc = "Abrir terminal Ghostty" })

-- @bind Aplicaciones | SUPER + B | Abrir navegador Firefox
hl.bind(mod .. " + B",      hl.dsp.exec_cmd("firefox"),  { desc = "Abrir Firefox" })

-- @bind Aplicaciones | SUPER + E | Abrir explorador de archivos (Nautilus)
hl.bind(mod .. " + E",      hl.dsp.exec_cmd("nautilus"), { desc = "Abrir explorador de archivos (Nautilus)" })

-- -----------------------------------------------------------------------------
-- Shell y Sistema
-- -----------------------------------------------------------------------------
-- @bind Shell y Sistema | SUPER + Space | Abrir lanzador de aplicaciones
hl.bind(mod .. " + Space", hl.dsp.exec_cmd("qs ipc call launcher toggle"),  { desc = "Lanzador de aplicaciones (Quickshell)" })

-- @bind Shell y Sistema | SUPER + K | Mostrar atajos de teclado
hl.bind(mod .. " + K",     hl.dsp.exec_cmd("qs ipc call keybinds toggle"),  { desc = "Mostrar atajos de teclado (Quickshell)" })

-- @bind Shell y Sistema | SUPER + W | Selector visual de wallpapers
hl.bind(mod .. " + W",     hl.dsp.exec_cmd("qs ipc call wallpaper toggle"), { desc = "Selector de wallpapers (Quickshell)" })

-- @bind Shell y Sistema | SUPER + SHIFT + W | Wallpaper aleatorio (Material You)
hl.bind(
    mod .. " + SHIFT + W",
    hl.dsp.exec_cmd(
        [[sh -c 'if [ -x "$HOME/.local/bin/wallpaper.sh" ]; then "$HOME/.local/bin/wallpaper.sh" --random; elif [ -x "$HOME/dotfiles/scripts/wallpaper.sh" ]; then "$HOME/dotfiles/scripts/wallpaper.sh" --random; fi']]
    ),
    { desc = "Cambiar a un wallpaper aleatorio (Material You)" }
)

-- @bind Shell y Sistema | SUPER + X | Menú de energía y perfiles
hl.bind(mod .. " + X",     hl.dsp.exec_cmd("qs ipc call power toggle"),     { desc = "Menú de energía y perfiles (Quickshell)" })

-- @bind Shell y Sistema | SUPER + L | Bloquear pantalla (Hyprlock)
hl.bind(mod .. " + L",     hl.dsp.exec_cmd("hyprlock"),                     { desc = "Bloquear pantalla" })

-- -----------------------------------------------------------------------------
-- Ventanas
-- -----------------------------------------------------------------------------
-- @bind Ventanas | SUPER + Q | Cerrar ventana activa
hl.bind(mod .. " + Q", hl.dsp.window.close(),                  { desc = "Cerrar ventana activa" })

-- @bind Ventanas | SUPER + V | Alternar modo flotante
hl.bind(mod .. " + V", hl.dsp.window.float({ action = "toggle" }), { desc = "Alternar flotante" })

-- @bind Ventanas | SUPER + F | Alternar pantalla completa
hl.bind(mod .. " + F", hl.dsp.window.fullscreen({ mode = 0 }), { desc = "Pantalla completa" })

-- @bind Ventanas | SUPER + Flechas | Mover foco entre ventanas
hl.bind(mod .. " + left",  hl.dsp.focus({ direction = "left" }))
hl.bind(mod .. " + right", hl.dsp.focus({ direction = "right" }))
hl.bind(mod .. " + up",    hl.dsp.focus({ direction = "up" }))
hl.bind(mod .. " + down",  hl.dsp.focus({ direction = "down" }))

-- @bind Ventanas | SUPER + SHIFT + Flechas | Mover ventana activa
hl.bind(mod .. " + SHIFT + left",  hl.dsp.window.move({ direction = "left" }))
hl.bind(mod .. " + SHIFT + right", hl.dsp.window.move({ direction = "right" }))
hl.bind(mod .. " + SHIFT + up",    hl.dsp.window.move({ direction = "up" }))
hl.bind(mod .. " + SHIFT + down",  hl.dsp.window.move({ direction = "down" }))

-- HJKL (estilo Vim): usa SUPER + ALT para foco para no colisionar con SUPER + L (hyprlock).
-- @bind Ventanas | SUPER + ALT + H/J/K/L | Mover foco (estilo Vim)
hl.bind(mod .. " + ALT + H", hl.dsp.focus({ direction = "left" }))
hl.bind(mod .. " + ALT + J", hl.dsp.focus({ direction = "down" }))
hl.bind(mod .. " + ALT + K", hl.dsp.focus({ direction = "up" }))
hl.bind(mod .. " + ALT + L", hl.dsp.focus({ direction = "right" }))

-- @bind Ventanas | SUPER + SHIFT + H/J/K/L | Mover ventana (estilo Vim)
hl.bind(mod .. " + SHIFT + H", hl.dsp.window.move({ direction = "left" }))
hl.bind(mod .. " + SHIFT + J", hl.dsp.window.move({ direction = "down" }))
hl.bind(mod .. " + SHIFT + K", hl.dsp.window.move({ direction = "up" }))
hl.bind(mod .. " + SHIFT + L", hl.dsp.window.move({ direction = "right" }))

-- @bind Ventanas | SUPER + Click Izq | Arrastrar ventana
hl.bind(mod .. " + mouse:272", hl.dsp.window.drag(),   { mouse = true })

-- @bind Ventanas | SUPER + Click Der | Redimensionar ventana
hl.bind(mod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

-- -----------------------------------------------------------------------------
-- Workspaces
-- -----------------------------------------------------------------------------
-- @bind Workspaces | SUPER + 1..9 | Cambiar al workspace 1..9
-- @bind Workspaces | SUPER + SHIFT + 1..9 | Mover ventana al workspace 1..9
for i = 1, 9 do
    hl.bind(mod .. " + " .. i,         hl.dsp.focus({ workspace = i }))
    hl.bind(mod .. " + SHIFT + " .. i, hl.dsp.window.move({ workspace = i }))
end

-- @bind Workspaces | SUPER + Scroll | Recorrer workspaces activos
hl.bind(mod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
hl.bind(mod .. " + mouse_up",   hl.dsp.focus({ workspace = "e-1" }))

-- -----------------------------------------------------------------------------
-- Capturas de pantalla (grim + slurp + satty + wl-copy)
-- -----------------------------------------------------------------------------
-- @bind Capturas de pantalla | Print | Captura completa (guardar y copiar)
hl.bind(
    "Print",
    hl.dsp.exec_cmd(
        [[sh -c 'dir="$HOME/Pictures/Screenshots"; mkdir -p "$dir"; file="$dir/screenshot-$(date +%Y-%m-%d_%H-%M-%S).png"; grim - | tee "$file" | wl-copy']]
    ),
    { desc = "Captura completa (guardar y copiar)" }
)

-- @bind Capturas de pantalla | SUPER + SHIFT + S | Captura de región con editor Satty
hl.bind(
    mod .. " + SHIFT + S",
    hl.dsp.exec_cmd(
        [[sh -c 'mkdir -p "$HOME/Pictures/Screenshots"; geom=$(slurp); [ -n "$geom" ] && grim -g "$geom" -t ppm - | satty --filename - --copy-command wl-copy --early-exit']]
    ),
    { desc = "Captura de región con editor Satty" }
)

-- @bind Capturas de pantalla | SUPER + CTRL + S | Captura de región al portapapeles
hl.bind(
    mod .. " + CTRL + S",
    hl.dsp.exec_cmd(
        [[sh -c 'geom=$(slurp); [ -n "$geom" ] && grim -g "$geom" - | wl-copy']]
    ),
    { desc = "Captura de región al portapapeles" }
)

-- -----------------------------------------------------------------------------
-- Multimedia y Brillo
-- -----------------------------------------------------------------------------
-- @bind Multimedia y Brillo | Vol+ / Vol- | Subir o bajar volumen (5%)
hl.bind("XF86AudioRaiseVolume",  hl.dsp.exec_cmd("wpctl set-volume -l 1.0 @DEFAULT_AUDIO_SINK@ 5%+"), { locked = true, repeating = true })
hl.bind("XF86AudioLowerVolume",  hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"),        { locked = true, repeating = true })

-- @bind Multimedia y Brillo | Mute / MicMute | Silenciar audio o micrófono
hl.bind("XF86AudioMute",         hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"),       { locked = true })
hl.bind("XF86AudioMicMute",      hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"),     { locked = true })

-- @bind Multimedia y Brillo | Brillo+ / Brillo- | Ajustar brillo de pantalla (5%)
hl.bind("XF86MonBrightnessUp",   hl.dsp.exec_cmd("sh -c 'brightnessctl -e4 -n2 set 5%+ && qs ipc call osd showBrightness >/dev/null 2>&1 || true'"), { locked = true, repeating = true })
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("sh -c 'brightnessctl -e4 -n2 set 5%- && qs ipc call osd showBrightness >/dev/null 2>&1 || true'"), { locked = true, repeating = true })

-- @bind Multimedia y Brillo | Play / Prev / Next | Controlar reproducción multimedia
hl.bind("XF86AudioNext",         hl.dsp.exec_cmd("playerctl next"),                                   { locked = true })
hl.bind("XF86AudioPrev",         hl.dsp.exec_cmd("playerctl previous"),                               { locked = true })
hl.bind("XF86AudioPlay",         hl.dsp.exec_cmd("playerctl play-pause"),                             { locked = true })
hl.bind("XF86AudioPause",        hl.dsp.exec_cmd("playerctl play-pause"),                             { locked = true })
