-- =============================================================================
-- Hyprland 0.57+ — Punto de entrada principal (API oficial Lua)
-- Documentación / stubs locales: /usr/share/hypr/stubs/hl.meta.lua
-- =============================================================================

-- Resolver el directorio del archivo actual para cargar módulos locales desde
-- `lua/?.lua` tanto cuando esté enlazado en ~/.config/hypr como al verificarlo
-- directamente dentro de ~/dotfiles/config/hypr.
local config_dir
if debug and debug.getinfo then
    local source = debug.getinfo(1, "S").source
    if source and source:sub(1, 1) == "@" then
        config_dir = source:sub(2):match("^(.*)/[^/]+$")
    end
end

local xdg_config = os.getenv("XDG_CONFIG_HOME") or ((os.getenv("HOME") or "") .. "/.config")
local fallback_dir = xdg_config .. "/hypr"

if config_dir and config_dir ~= "" then
    package.path = config_dir .. "/lua/?.lua;" .. fallback_dir .. "/lua/?.lua;" .. package.path
else
    package.path = fallback_dir .. "/lua/?.lua;" .. package.path
end

-- =============================================================================
-- Carga modular en orden estricto
-- =============================================================================
require("colors")
require("env")
require("monitors")
require("autostart")
require("input")
require("general")
require("animations")
require("rules")
require("keybinds")
