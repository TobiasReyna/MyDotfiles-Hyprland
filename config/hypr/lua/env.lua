-- =============================================================================
-- Variables de entorno — Wayland, Qt6/GTK, Electron y Gaming NVIDIA
-- =============================================================================

-- Sesión Wayland / XDG
hl.env("XDG_CURRENT_DESKTOP", "Hyprland")
hl.env("XDG_SESSION_TYPE", "wayland")
hl.env("XDG_SESSION_DESKTOP", "Hyprland")

-- Cursor global (Bibata-Modern-Classic es XCursor puro, sin carpeta hyprcursors;
-- omitir HYPRCURSOR_THEME permite que Hyprland cargue XCURSOR_THEME sin fallback roto)
hl.env("XCURSOR_THEME", "Bibata-Modern-Classic")
hl.env("XCURSOR_SIZE", "24")
hl.env("HYPRCURSOR_SIZE", "24")

-- Qt6 / Wayland
-- Nota sobre escala fraccional (1.25): Qt6 y GTK en Wayland leen la escala
-- directamente del compositor (`wp_fractional_scale_v1`). No fijar `QT_SCALE_FACTOR`
-- ni `GDK_SCALE` evita el doble escalado.
hl.env("QT_QPA_PLATFORM", "wayland;xcb")
hl.env("QT_QPA_PLATFORMTHEME", "qt6ct")
hl.env("QT_WAYLAND_DISABLE_WINDOWDECORATION", "1")
hl.env("QT_AUTO_SCREEN_SCALE_FACTOR", "1")
hl.env("QT_SCALE_FACTOR_ROUNDING_POLICY", "PassThrough")

-- GTK / SDL / Clutter / Electron
hl.env("GDK_BACKEND", "wayland,x11,*")
hl.env("SDL_VIDEODRIVER", "wayland")
hl.env("CLUTTER_BACKEND", "wayland")
hl.env("ELECTRON_OZONE_PLATFORM_HINT", "auto")

-- =============================================================================
-- NVIDIA & Gaming
-- -----------------------------------------------------------------------------
-- Modo GPU dedicada (MUX switch / dGPU only):
--   Dejá activas todas las variables de abajo. Si notás problemas con GBM en
--   algún driver, podés sumar `hl.env("GBM_BACKEND", "nvidia-drm")`.
--
-- Modo híbrido (Optimus / iGPU para escritorio + dGPU para juegos):
--   Comentá `LIBVA_DRIVER_NAME`, `NVD_BACKEND` y `__GLX_VENDOR_LIBRARY_NAME`
--   para que Hyprland corra sobre la iGPU (mejor batería y menos wakeups de la
--   dGPU), y ejecutá los juegos con `prime-run %command%` en Steam.
--   Opcionalmente fijá `AQ_DRM_DEVICES` apuntando primero a la iGPU.
-- =============================================================================
hl.env("LIBVA_DRIVER_NAME", "nvidia")
hl.env("NVD_BACKEND", "direct")
hl.env("__GLX_VENDOR_LIBRARY_NAME", "nvidia")

hl.env("__GL_GSYNC_ALLOWED", "1")
hl.env("__GL_VRR_ALLOWED", "1")
hl.env("PROTON_ENABLE_NVAPI", "1")
hl.env("PROTON_HIDE_NVIDIA_GPU", "0")
