-- =============================================================================
-- Autostart (equivalente en Lua 0.57+ a `exec-once`)
-- Se ejecuta únicamente al iniciar la sesión de Hyprland, no en reloads.
-- Nota: `nm-applet` se omite intencionalmente (la red se gestiona desde
-- Quickshell / NetworkManager).
-- =============================================================================

hl.on("hyprland.start", function()
    -- 1. Propagar entorno Wayland a systemd y D-Bus (portales, polkit, etc.)
    hl.exec_cmd("systemctl --user import-environment WAYLAND_DISPLAY XDG_CURRENT_DESKTOP")
    hl.exec_cmd("dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP")

    -- 1b. Aplicar tema y tamaño de cursor global (Hyprland + GTK / Electron / XWayland)
    hl.exec_cmd("hyprctl setcursor Bibata-Modern-Classic 24")
    hl.exec_cmd("gsettings set org.gnome.desktop.interface cursor-theme 'Bibata-Modern-Classic'")
    hl.exec_cmd("gsettings set org.gnome.desktop.interface cursor-size 24")

    -- 2. Agente Polkit nativo de Hyprland
    hl.exec_cmd("/usr/lib/hyprpolkitagent/hyprpolkitagent")

    -- 3. Daemon de wallpapers animados/dinámicos + restauración del último wallpaper
    hl.exec_cmd("awww-daemon")
    hl.exec_cmd([[sh -c 'if [ -x "$HOME/.local/bin/wallpaper.sh" ]; then "$HOME/.local/bin/wallpaper.sh" --restore; elif [ -x "$HOME/dotfiles/scripts/wallpaper.sh" ]; then "$HOME/dotfiles/scripts/wallpaper.sh" --restore; fi']])

    -- 4. Shell de escritorio (carga automáticamente ~/.config/quickshell/shell.qml)
    hl.exec_cmd("quickshell")

    -- 5. Gestión de inactividad y suspensión
    hl.exec_cmd("hypridle")

    -- 6. Historial del portapapeles (texto e imágenes)
    hl.exec_cmd("wl-paste --type text --watch cliphist store")
    hl.exec_cmd("wl-paste --type image --watch cliphist store")
end)
