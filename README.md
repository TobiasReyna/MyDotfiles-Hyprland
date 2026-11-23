# Arch Linux Dotfiles — Hyprland (Lua 0.57+) · Quickshell · Material You

Entorno de escritorio modular para **Arch Linux + Wayland**, construido sobre **Hyprland 0.57+ con su API oficial en Lua**, una interfaz personalizada en **Quickshell (Qt6/QML)** inspirada en **Material Design 3 / Caelestia**, y tematización dinámica **Material You** generada automáticamente desde el wallpaper con **Matugen** y **awww**.

---

## Características principales

- **Hyprland 0.57+ 100% modular en Lua (`hl.*`):** separado en módulos limpios (`colors`, `env`, `monitors`, `autostart`, `input`, `general`, `animations`, `rules`, `keybinds`), validado contra `hl.meta.lua` y `hyprland --verify-config`.
- **Quickshell estilo Caelestia (`Qt6/QML`):** barra superior con blur nativo, botón con logo de Arch Linux, **lanzador de aplicaciones nativo** (`DesktopEntries` con búsqueda instantánea y navegación por teclado), **visor interactivo de atajos de teclado** (`Super + K`, sincronizado automáticamente con `keybinds.lua`), workspaces interactivos, reloj y calendario en español, **mini reproductor multimedia MPRIS con visualizador Cava reactivo** (y fondo difuminado de carátula), **administrador de notificaciones 100% nativo** (`NotificationServer` con toasts flotantes, centro de notificaciones e historial + modo No molestar), monitor de sistema (`CPU %`, `RAM %`, `Temp °C`), bandeja del sistema con menú contextual Material You (filtrando `nm-applet`), OSD flotante de volumen/brillo y popups interactivos para **Wi-Fi/Bluetooth**, **Audio (PipeWire)**, **Energía/Perfiles + modo "Mantener encendida"** (`systemd-inhibit` + Wayland `IdleInhibitor`) y **Selector visual de Wallpapers**.
- **Material You en vivo (`matugen` + `awww`):** al cambiar el wallpaper (desde `Super + W`, `Super + Shift + W` o `wallpaper.sh`), se regeneran y recargan en caliente los colores de Hyprland, Hyprlock, Quickshell, Ghostty (`SIGUSR2`), Zsh (`SIGUSR1` seguro vía `SigCgt`) y Starship.
- **Capturas y anotación instantánea:** flujo con `grim` + `slurp` + `satty` + `wl-copy` (captura completa, región directa al portapapeles o anotación inmediata con cierre rápido).
- **Terminal y Shell modernos:** **Ghostty 1.4+** con transparencia coordinada con el blur de Hyprland, **Zsh** con historial deduplicado de 20 000 líneas, `zsh-autosuggestions`, `zsh-syntax-highlighting` y **Starship** personalizado para Arch Linux.
- **Instalador idempotente (`install.sh`):** realiza backup automático de configuraciones previas y copia los 6 archivos dinámicos de Matugen como archivos regulares para no ensuciar el árbol Git.

---

## Stack tecnológico

| Componente | Tecnología | Detalles |
| --- | --- | --- |
| **Compositor Wayland** | `Hyprland 0.57+` | Configuración oficial en Lua (`hyprland.lua`), `hypridle`, `hyprlock`, `hyprpolkitagent` |
| **Desktop Shell / Barra** | `Quickshell` (`quickshell-git`) | Barra con logo Arch, lanzador nativo (`DesktopEntries`), popups, IPC (`qs ipc`) y OSD en Qt6/QML |
| **Tema dinámico** | `Matugen 4.2+` | Paletas Material Design 3 + colores ANSI armonizados |
| **Wallpapers** | `awww` + `scripts/wallpaper.sh` | Transiciones suaves a 144 FPS, persistencia y API JSON para Quickshell |
| **Terminal** | `Ghostty 1.4+` | `JetBrainsMono Nerd Font`, ligaduras, recarga de tema en vivo (`SIGUSR2`) |
| **Shell y Prompt** | `Zsh` + `Starship` | Plugins nativos de Arch, recarga en caliente (`TRAPUSR1`), paleta `[palettes.matugen]` |
| **Capturas de pantalla** | `grim` + `slurp` + `satty` + `wl-copy` | Guardado en `~/Pictures/Screenshots/` y edición flotante centrada |
| **Audio / Red / Energía** | `PipeWire` · `Cava` · `NetworkManager` · `BlueZ` · `UPower` | Controlado desde Quickshell con `PipeWire`, `cava`, `nmcli`, `bluetoothctl`, `powerprofilesctl` y `systemd-inhibit` |

---

## Estructura del repositorio

```text
dotfiles/
├── config/
│   ├── cava/quickshell.conf           # Perfil raw ASCII para el visualizador del mini reproductor
│   ├── ghostty/
│   │   ├── config                     # Configuración principal de Ghostty 1.4+
│   │   └── themes/matugen             # Tema fallback (copiado para Matugen)
│   ├── hypr/
│   │   ├── hyprland.lua               # Punto de entrada Lua
│   │   ├── hypridle.conf              # Timeouts de brillo, bloqueo, DPMS y suspensión
│   │   ├── hyprlock.conf              # Pantalla de bloqueo minimalista
│   │   ├── colors-hyprlock.conf       # Colores fallback de Hyprlock (copiado para Matugen)
│   │   └── lua/                       # Módulos: colors, env, monitors, autostart, input, general, animations, rules, keybinds
│   ├── matugen/
│   │   ├── config.toml                # Esquema Material You, colores ANSI y post_hooks
│   │   └── templates/                 # Templates para Hyprland, Hyprlock, Quickshell, Ghostty, Zsh y Starship
│   ├── quickshell/
│   │   ├── shell.qml                  # ShellRoot + manejadores IPC
│   │   ├── ThemeColors.qml            # Singleton fallback (copiado para Matugen)
│   │   ├── bar/                       # Bar.qml
│   │   ├── components/                # MaterialIcon, PillButton, ToggleTile, PopupSurface
│   │   ├── osd/                       # Osd.qml (volumen/brillo) y NotificationPopups.qml (toasts)
│   │   ├── popups/                    # Launcher, Keybinds, Media, NotificationCenter, TrayMenu, NetworkBluetooth, Audio, Power, Wallpaper, Calendar, SysStats
│   │   └── services/                  # SysStats, Network, Bluetooth, Power, Caffeine, Audio, Cava, Notification, Keybinds, Brightness, PopupState
│   ├── satty/config.toml              # Configuración del anotador de capturas
│   ├── zsh/
│   │   ├── .zshrc                     # Enlazado a ~/.zshrc
│   │   └── matugen-colors.zsh         # Fallback de colores Zsh (copiado para Matugen)
│   └── starship.toml                  # Fallback de Starship (copiado para Matugen)
├── scripts/
│   └── wallpaper.sh                   # Gestor de wallpapers (awww + matugen + recarga en vivo)
├── wallpapers/                        # Colocá aquí tus wallpapers locales
├── install.sh                         # Instalador automático e idempotente
├── LICENSE                            # Licencia MIT
└── README.md
```

---

## Instalación rápida

```bash
git clone https://github.com/<tu-usuario>/dotfiles.git ~/dotfiles
cd ~/dotfiles
./install.sh
```

### Flags útiles de `install.sh`

| Flag | Descripción |
| --- | --- |
| `--dry-run` | Simula todo el proceso mostrando qué paquetes, symlinks y copias se harían sin modificar el sistema. |
| `--skip-packages` | Omite la instalación vía `pacman`/AUR y solo despliega configuraciones y servicios. |
| `--skip-services` | Omite `systemctl enable --now` para los daemons del sistema. |
| `--no-backup` | Sobrescribe archivos existentes sin crear `~/.dotfiles-backup-<fecha>/`. |

> **Protección del árbol Git:** Los 6 archivos que `matugen` sobrescribe al cambiar el wallpaper (`colors.lua`, `colors-hyprlock.conf`, `ThemeColors.qml`, `ghostty/themes/matugen`, `zsh/matugen-colors.zsh` y `starship.toml`) se **copian** como archivos regulares a `~/.config/...` en lugar de symlinkearse, manteniendo `~/dotfiles` siempre limpio.

---

## Atajos de teclado (Keybinds)

Definidos en [`config/hypr/lua/keybinds.lua`](config/hypr/lua/keybinds.lua) usando `SUPER` como modificador principal:

| Atajo | Acción |
| --- | --- |
| `Super + Enter` | Abrir terminal (`ghostty`) |
| `Super + Space` | Abrir/cerrar lanzador de aplicaciones nativo (`qs ipc call launcher toggle`) |
| `Super + K` | Abrir/cerrar visor interactivo de atajos de teclado (`qs ipc call keybinds toggle`) |
| `Super + B` | Abrir navegador (`firefox`) |
| `Super + Q` | Cerrar ventana activa |
| `Super + V` | Alternar ventana flotante |
| `Super + F` | Alternar pantalla completa |
| `Super + L` | Bloquear pantalla (`hyprlock`) |
| `Super + W` | Abrir selector visual de wallpapers (`qs ipc call wallpaper toggle`) |
| `Super + Shift + W` | Cambiar a un wallpaper aleatorio y regenerar Material You (`wallpaper.sh --random`) |
| `Super + X` | Abrir menú de energía y perfiles (`qs ipc call power toggle`) |
| `Print` | Captura de pantalla completa (guarda en `~/Pictures/Screenshots/` y copia al portapapeles) |
| `Super + Shift + S` | Captura de región enviada directo a **Satty** para anotar/censurar/copiar |
| `Super + Ctrl + S` | Captura de región directa al portapapeles (sin abrir editor) |
| `Super + Flechas` / `Super + Alt + H/J/K/L` | Mover foco entre ventanas *(HJKL usa `Alt` para no colisionar con `Super + L`)* |
| `Super + Shift + Flechas` / `Super + Shift + H/J/K/L` | Mover ventana activa de posición |
| `Super + 1..9` / `Super + Shift + 1..9` | Cambiar de workspace / mover ventana activa al workspace `1..9` |
| `Super + Scroll` | Recorrer workspaces existentes (`e+1` / `e-1`) |
| `Super + Click Izq / Der` | Arrastrar / redimensionar ventana con el mouse |
| `XF86Audio*` / `XF86MonBrightness*` | Volumen (`wpctl`), reproducción (`playerctl`) y brillo (`brightnessctl` + OSD) |

---

## Notas de NVIDIA y Gaming

1. **Parámetros del kernel (bootloader):** asegurate de habilitar KMS y framebuffer DRM de NVIDIA en tu entrada de `systemd-boot` o `GRUB`:
   ```text
   nvidia_drm.modeset=1 nvidia_drm.fbdev=1
   ```
   Y añadir los módulos `nvidia nvidia_modeset nvidia_uvm nvidia_drm` en `/etc/mkinitcpio.conf` (`MODULES=(...)`) seguido de `sudo mkinitcpio -P`.
2. **GPU dedicada (MUX switch) vs Laptop híbrida (Optimus):**
   - Por defecto [`config/hypr/lua/env.lua`](config/hypr/lua/env.lua) deja activas `LIBVA_DRIVER_NAME=nvidia`, `NVD_BACKEND=direct` y `__GLX_VENDOR_LIBRARY_NAME=nvidia` (ideal para **dGPU / MUX switch**).
   - En **modo híbrido (Optimus)**, comentá esas tres líneas para que el escritorio corra sobre la iGPU (menor consumo y mejor batería) y lanzá juegos en Steam con `prime-run %command%`.
3. **Gaming y VRR:** `monitors.lua` activa `vrr = 2` (VRR solo en pantalla completa) y `rules.lua` aplica `immediate`, `no_blur`, `no_anim`, `no_shadow` y `opaque` a ventanas `^steam_app_.*$`. Si el cursor parpadea en NVIDIA, cambiá `cursor.no_hardware_cursors` a `true` (o `2`) en [`config/hypr/lua/general.lua`](config/hypr/lua/general.lua).

---

## Screenshots

> *(Agregá tus capturas en `docs/screenshots/` y reemplazá las rutas de ejemplo debajo)*

| Escritorio y barra Quickshell | Selector de Wallpapers (Material You) |
| --- | --- |
| ![Escritorio](docs/screenshots/desktop.png) | ![Wallpapers](docs/screenshots/wallpaper-picker.png) |

| Popups de Conectividad / Audio / Energía | Ghostty + Zsh + Starship |
| --- | --- |
| ![Popups](docs/screenshots/popups.png) | ![Terminal](docs/screenshots/terminal.png) |

---

## Licencia

Distribuido bajo la licencia [MIT](LICENSE).
