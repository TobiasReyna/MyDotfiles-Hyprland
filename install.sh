#!/usr/bin/env bash
# =============================================================================
# install.sh — Instalador idempotente para Arch Linux + Hyprland 0.57+ (Lua)
#              + Quickshell (Material Design 3) + Matugen + Ghostty + Zsh
# =============================================================================

set -euo pipefail

# -----------------------------------------------------------------------------
# Colores y utilidades de salida
# -----------------------------------------------------------------------------
if [[ -t 1 ]]; then
    C_RESET='\033[0m'
    C_BOLD='\033[1m'
    C_DIM='\033[2m'
    C_BLUE='\033[1;34m'
    C_CYAN='\033[1;36m'
    C_GREEN='\033[1;32m'
    C_YELLOW='\033[1;33m'
    C_RED='\033[1;31m'
    C_MAGENTA='\033[1;35m'
else
    C_RESET='' C_BOLD='' C_DIM='' C_BLUE='' C_CYAN=''
    C_GREEN='' C_YELLOW='' C_RED='' C_MAGENTA=''
fi

log_section() { printf "\n${C_BLUE}==>${C_RESET} ${C_BOLD}%s${C_RESET}\n" "$*"; }
log_info()    { printf "  ${C_CYAN}[INFO]${C_RESET} %s\n" "$*"; }
log_ok()      { printf "  ${C_GREEN}[OK]${C_RESET}   %s\n" "$*"; }
log_link()    { printf "  ${C_BLUE}[LINK]${C_RESET} %s -> %s\n" "$1" "$2"; }
log_copy()    { printf "  ${C_MAGENTA}[COPY]${C_RESET} %s -> %s ${C_DIM}(archivo regular para Matugen)${C_RESET}\n" "$1" "$2"; }
log_warn()    { printf "  ${C_YELLOW}[WARN]${C_RESET} %s\n" "$*" >&2; }
log_err()     { printf "  ${C_RED}[ERR]${C_RESET}  %s\n" "$*" >&2; }

# -----------------------------------------------------------------------------
# Configuración y flags CLI
# -----------------------------------------------------------------------------
REPO_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
XDG_CONFIG="${XDG_CONFIG_HOME:-$HOME/.config}"
BACKUP_DIR="$HOME/.dotfiles-backup-$(date +%Y%m%d-%H%M%S)"
BACKUP_USED=0

SKIP_PACKAGES=0
SKIP_SERVICES=0
NO_BACKUP=0
DRY_RUN=0

PACMAN_PACKAGES=(
    hyprland
    hypridle
    hyprlock
    hyprpolkitagent
    xdg-desktop-portal-hyprland
    xdg-desktop-portal-gtk
    qt5-wayland
    qt6-wayland
    egl-wayland
    qt6-declarative
    qt6-svg
    qt6-5compat
    qt6-multimedia
    qt6-shadertools
    awww
    grim
    slurp
    satty
    wl-clipboard
    cliphist
    imagemagick
    jq
    ghostty
    firefox
    zsh
    zsh-autosuggestions
    zsh-syntax-highlighting
    starship
    networkmanager
    bluez
    bluez-utils
    pipewire
    pipewire-pulse
    wireplumber
    playerctl
    cava
    libnotify
    brightnessctl
    upower
    power-profiles-daemon
    lm_sensors
    ttf-jetbrains-mono-nerd
    inter-font
    noto-fonts
    noto-fonts-emoji
    git
)

AUR_PACKAGES=(
    quickshell-git
    matugen-bin
    ttf-material-symbols-variable-git
)

SYSTEM_SERVICES=(
    NetworkManager.service
    bluetooth.service
    power-profiles-daemon.service
    upower.service
)

usage() {
    cat <<'EOF'
Uso: ./install.sh [OPCIONES]

Instala dependencias, crea backups seguros y despliega las configuraciones de
Hyprland (Lua 0.57+), Quickshell, Matugen, Satty, Ghostty, Zsh y Starship.

Opciones:
  --skip-packages   Omite la instalación de paquetes (pacman y AUR)
  --skip-services   Omite la activación de servicios con systemctl
  --no-backup       No respalda archivos previos antes de sobrescribir
  --dry-run         Muestra el plan completo sin modificar el sistema
  -h, --help        Muestra esta ayuda y sale
EOF
}

parse_args() {
    while (( $# > 0 )); do
        case "$1" in
            --skip-packages) SKIP_PACKAGES=1 ;;
            --skip-services) SKIP_SERVICES=1 ;;
            --no-backup)     NO_BACKUP=1 ;;
            --dry-run)       DRY_RUN=1 ;;
            -h|--help)
                usage
                exit 0
                ;;
            *)
                log_err "Opción desconocida: $1"
                usage >&2
                exit 1
                ;;
        esac
        shift
    done
}

run_cmd() {
    if (( DRY_RUN == 1 )); then
        printf "  ${C_DIM}[DRY-RUN] %s${C_RESET}\n" "$*"
    else
        "$@"
    fi
}

ask_yes_no() {
    local prompt="$1"
    local default="${2:-n}"
    if (( DRY_RUN == 1 )) || [[ ! -t 0 ]]; then
        return 1
    fi
    local hint="[s/N]"
    [[ "$default" == "y" ]] && hint="[S/n]"
    local reply
    read -r -p "  $prompt $hint " reply || return 1
    reply="${reply:-$default}"
    [[ "$reply" =~ ^[sSyY]$ ]]
}

# -----------------------------------------------------------------------------
# Paso 1: Verificación de entorno
# -----------------------------------------------------------------------------
AUR_HELPER=""

check_environment() {
    log_section "1. Verificación de entorno"

    if [[ "${EUID:-$(id -u)}" -eq 0 ]]; then
        log_err "No ejecutes este script directamente como root. Usá tu usuario normal (sudo se invocará solo cuando sea necesario)."
        exit 1
    fi

    if ! command -v pacman >/dev/null 2>&1; then
        log_err "No se encontró 'pacman'. Este instalador está diseñado para Arch Linux o derivadas."
        exit 1
    fi

    if [[ -f /etc/os-release ]]; then
        # shellcheck disable=SC1091
        source /etc/os-release
        log_ok "Sistema detectado: ${PRETTY_NAME:-Arch Linux}"
    else
        log_ok "Gestor pacman detectado."
    fi

    if command -v yay >/dev/null 2>&1; then
        AUR_HELPER="yay"
        log_ok "Helper AUR detectado: yay"
    elif command -v paru >/dev/null 2>&1; then
        AUR_HELPER="paru"
        log_ok "Helper AUR detectado: paru"
    else
        log_warn "No se detectó 'yay' ni 'paru' para instalar paquetes AUR (${AUR_PACKAGES[*]})."
        if (( SKIP_PACKAGES == 0 )); then
            if (( DRY_RUN == 1 )); then
                log_info "En ejecución real se ofrecería instalar 'yay-bin' desde AUR (o continuar solo con pacman)."
            elif ask_yes_no "¿Deseás compilar e instalar 'yay-bin' automáticamente ahora?" "n"; then
                install_yay_bin
            else
                log_info "Podés instalar yay luego con:"
                log_info "  sudo pacman -S --needed base-devel git && git clone https://aur.archlinux.org/yay-bin.git /tmp/yay-bin && (cd /tmp/yay-bin && makepkg -si)"
            fi
        fi
    fi
}

install_yay_bin() {
    log_info "Instalando prerequisitos base-devel y git para yay-bin..."
    sudo pacman -S --needed --noconfirm base-devel git
    local tmp_yay
    tmp_yay="$(mktemp -d /tmp/yay-bin.XXXXXX)"
    trap 'rm -rf "$tmp_yay"' RETURN
    git clone https://aur.archlinux.org/yay-bin.git "$tmp_yay"
    (cd "$tmp_yay" && makepkg -si --noconfirm)
    if command -v yay >/dev/null 2>&1; then
        AUR_HELPER="yay"
        log_ok "yay-bin instalado correctamente."
    fi
}

# -----------------------------------------------------------------------------
# Paso 2: Instalación de dependencias
# -----------------------------------------------------------------------------
install_packages() {
    log_section "2. Instalación de dependencias"

    if (( SKIP_PACKAGES == 1 )); then
        log_info "Omitido por flag --skip-packages."
        return 0
    fi

    log_info "Paquetes oficiales (${#PACMAN_PACKAGES[@]}): ${PACMAN_PACKAGES[*]}"
    run_cmd sudo pacman -S --needed "${PACMAN_PACKAGES[@]}"

    if [[ -n "$AUR_HELPER" ]]; then
        log_info "Paquetes AUR con $AUR_HELPER (${#AUR_PACKAGES[@]}): ${AUR_PACKAGES[*]}"
        run_cmd "$AUR_HELPER" -S --needed "${AUR_PACKAGES[@]}"
    else
        log_warn "Sin helper AUR activo; omitiendo paquetes AUR: ${AUR_PACKAGES[*]}"
    fi
}

# -----------------------------------------------------------------------------
# Paso 3: Creación de directorios base
# -----------------------------------------------------------------------------
create_directories() {
    log_section "3. Creación de directorios base"

    local -a dirs=(
        "$XDG_CONFIG/hypr/lua"
        "$XDG_CONFIG/quickshell"
        "$XDG_CONFIG/matugen"
        "$XDG_CONFIG/ghostty/themes"
        "$XDG_CONFIG/zsh"
        "$XDG_CONFIG/satty"
        "$XDG_CONFIG/cava"
        "$HOME/.local/bin"
        "$HOME/.local/state/zsh"
        "$HOME/.local/state/wallpaper"
        "$HOME/.cache/zsh"
        "$HOME/Pictures/Screenshots"
        "$HOME/Pictures/Wallpapers"
    )

    local d
    for d in "${dirs[@]}"; do
        if [[ -d "$d" ]]; then
            log_ok "Existe: $d"
        else
            log_info "Crear directorio: $d"
            run_cmd mkdir -p "$d"
        fi
    done
}

# -----------------------------------------------------------------------------
# Paso 4 y 5: Backup automático + despliegue inteligente (symlinks y copias)
# -----------------------------------------------------------------------------
backup_target() {
    local target="$1"

    # Nada que respaldar si no existe ni como archivo ni como symlink roto
    if [[ ! -e "$target" && ! -L "$target" ]]; then
        return 0
    fi

    if (( NO_BACKUP == 1 )); then
        log_warn "Eliminando sin backup (--no-backup): $target"
        run_cmd rm -rf "$target"
        return 0
    fi

    local rel_path="${target#"$HOME"/}"
    local dest_backup="$BACKUP_DIR/$rel_path"
    BACKUP_USED=1

    log_warn "Respaldando $target -> $dest_backup"
    run_cmd mkdir -p "$(dirname "$dest_backup")"
    run_cmd mv "$target" "$dest_backup"
}

deploy_symlink() {
    local src="$1"
    local dest="$2"

    if [[ ! -e "$src" ]]; then
        log_err "Origen inexistente en el repo: $src"
        exit 1
    fi

    if [[ -L "$dest" ]]; then
        local current_target
        current_target="$(readlink -f "$dest" 2>/dev/null || true)"
        local expected_target
        expected_target="$(readlink -f "$src")"
        if [[ "$current_target" == "$expected_target" ]]; then
            log_ok "Symlink ya vigente: $dest -> $src"
            return 0
        fi
    fi

    if [[ -e "$dest" || -L "$dest" ]]; then
        backup_target "$dest"
    fi

    log_link "$dest" "$src"
    run_cmd mkdir -p "$(dirname "$dest")"
    run_cmd ln -sfn "$src" "$dest"
}

# Copia archivos dinámicos de Matugen como archivos regulares para que al
# regenerar paletas jamás se modifique ni ensucie el árbol de Git del repo.
deploy_copy() {
    local src="$1"
    local dest="$2"

    if [[ ! -f "$src" ]]; then
        log_err "Fallback inexistente en el repo: $src"
        exit 1
    fi

    if [[ -L "$dest" ]]; then
        # Si antes era un symlink (p. ej. hacia ~/dotfiles), lo reemplazamos por copia regular
        local link_target
        link_target="$(readlink -f "$dest" 2>/dev/null || true)"
        if [[ "$link_target" == "$REPO_DIR/"* ]]; then
            log_warn "Reemplazando symlink previo por archivo regular: $dest"
            run_cmd rm -f "$dest"
        else
            backup_target "$dest"
        fi
    elif [[ -f "$dest" ]]; then
        if cmp -s "$src" "$dest"; then
            log_copy "$src" "$dest"
            log_ok "Ya coincide con el fallback (archivo regular)."
            return 0
        fi
        backup_target "$dest"
    elif [[ -e "$dest" ]]; then
        backup_target "$dest"
    fi

    log_copy "$src" "$dest"
    run_cmd mkdir -p "$(dirname "$dest")"
    run_cmd cp "$src" "$dest"
}

deploy_configs() {
    log_section "4 & 5. Despliegue de configuraciones (symlinks estáticos + copias para Matugen)"

    # --- Hyprland (estáticos) ---
    deploy_symlink "$REPO_DIR/config/hypr/hyprland.lua"  "$XDG_CONFIG/hypr/hyprland.lua"
    deploy_symlink "$REPO_DIR/config/hypr/hypridle.conf" "$XDG_CONFIG/hypr/hypridle.conf"
    deploy_symlink "$REPO_DIR/config/hypr/hyprlock.conf" "$XDG_CONFIG/hypr/hyprlock.conf"

    local lua_mod
    for lua_mod in animations autostart env general input keybinds monitors rules; do
        deploy_symlink "$REPO_DIR/config/hypr/lua/${lua_mod}.lua" "$XDG_CONFIG/hypr/lua/${lua_mod}.lua"
    done

    # --- Quickshell (estáticos; ThemeColors.qml se copia aparte) ---
    deploy_symlink "$REPO_DIR/config/quickshell/shell.qml"  "$XDG_CONFIG/quickshell/shell.qml"
    deploy_symlink "$REPO_DIR/config/quickshell/qmldir"     "$XDG_CONFIG/quickshell/qmldir"
    deploy_symlink "$REPO_DIR/config/quickshell/bar"        "$XDG_CONFIG/quickshell/bar"
    deploy_symlink "$REPO_DIR/config/quickshell/components" "$XDG_CONFIG/quickshell/components"
    deploy_symlink "$REPO_DIR/config/quickshell/osd"        "$XDG_CONFIG/quickshell/osd"
    deploy_symlink "$REPO_DIR/config/quickshell/popups"     "$XDG_CONFIG/quickshell/popups"
    deploy_symlink "$REPO_DIR/config/quickshell/services"   "$XDG_CONFIG/quickshell/services"

    # --- Matugen (config y templates) ---
    deploy_symlink "$REPO_DIR/config/matugen/config.toml" "$XDG_CONFIG/matugen/config.toml"
    deploy_symlink "$REPO_DIR/config/matugen/templates"   "$XDG_CONFIG/matugen/templates"

    # --- Ghostty (config estático; themes/matugen se copia aparte) ---
    deploy_symlink "$REPO_DIR/config/ghostty/config" "$XDG_CONFIG/ghostty/config"

    # --- Satty y Cava ---
    deploy_symlink "$REPO_DIR/config/satty/config.toml"    "$XDG_CONFIG/satty/config.toml"
    deploy_symlink "$REPO_DIR/config/cava/quickshell.conf" "$XDG_CONFIG/cava/quickshell.conf"

    # --- Zsh y scripts ---
    deploy_symlink "$REPO_DIR/config/zsh/.zshrc"        "$HOME/.zshrc"
    deploy_symlink "$REPO_DIR/scripts/wallpaper.sh"     "$HOME/.local/bin/wallpaper.sh"
    run_cmd chmod +x "$REPO_DIR/scripts/wallpaper.sh"

    # --- 6 archivos dinámicos sobrescritos por Matugen (COPIA regular, NO symlink) ---
    log_info "Copiando los 6 archivos dinámicos de Matugen como archivos regulares (protege el árbol Git):"
    deploy_copy "$REPO_DIR/config/hypr/lua/colors.lua"        "$XDG_CONFIG/hypr/lua/colors.lua"
    deploy_copy "$REPO_DIR/config/hypr/colors-hyprlock.conf"  "$XDG_CONFIG/hypr/colors-hyprlock.conf"
    deploy_copy "$REPO_DIR/config/quickshell/ThemeColors.qml" "$XDG_CONFIG/quickshell/ThemeColors.qml"
    deploy_copy "$REPO_DIR/config/ghostty/themes/matugen"     "$XDG_CONFIG/ghostty/themes/matugen"
    deploy_copy "$REPO_DIR/config/zsh/matugen-colors.zsh"     "$XDG_CONFIG/zsh/matugen-colors.zsh"
    deploy_copy "$REPO_DIR/config/starship.toml"              "$XDG_CONFIG/starship.toml"
}

# -----------------------------------------------------------------------------
# Paso 6: Servicios del sistema
# -----------------------------------------------------------------------------
enable_services() {
    log_section "6. Servicios del sistema (systemd)"

    if (( SKIP_SERVICES == 1 )); then
        log_info "Omitido por flag --skip-services."
        return 0
    fi

    if ! command -v systemctl >/dev/null 2>&1; then
        log_warn "systemctl no disponible en este entorno; omitiendo habilitación de servicios."
        return 0
    fi

    local svc
    for svc in "${SYSTEM_SERVICES[@]}"; do
        if systemctl list-unit-files "$svc" >/dev/null 2>&1; then
            log_info "Habilitando $svc"
            run_cmd sudo systemctl enable --now "$svc" || log_warn "No se pudo iniciar ahora $svc (quedará disponible al reiniciar)."
        else
            log_warn "Unidad no encontrada (paquete no instalado aún): $svc"
        fi
    done
}

# -----------------------------------------------------------------------------
# Paso 7: Shell por defecto, paleta inicial y resumen
# -----------------------------------------------------------------------------
post_setup() {
    log_section "7. Shell por defecto y paleta inicial"

    if command -v zsh >/dev/null 2>&1; then
        local zsh_bin current_shell
        zsh_bin="$(command -v zsh)"
        current_shell="$(getent passwd "$USER" | cut -d: -f7 || echo "${SHELL:-}")"
        if [[ "$current_shell" == "$zsh_bin" ]]; then
            log_ok "La shell por defecto ya es Zsh ($zsh_bin)."
        elif (( DRY_RUN == 1 )); then
            log_info "En ejecución real se ofrecería cambiar la shell por defecto a $zsh_bin (chsh -s \"$zsh_bin\")."
        elif ask_yes_no "¿Cambiar tu shell por defecto a Zsh ($zsh_bin)?" "y"; then
            chsh -s "$zsh_bin"
            log_ok "Shell cambiada a $zsh_bin."
        else
            log_info "Podés cambiarla luego con: chsh -s \"$zsh_bin\""
        fi
    fi

    # Detectar si existe algún wallpaper para ofrecer corrida inicial de matugen
    local first_wall=""
    local search_dir
    for search_dir in "$REPO_DIR/wallpapers" "$HOME/Pictures/Wallpapers"; do
        [[ -d "$search_dir" ]] || continue
        first_wall="$(find "$search_dir" -maxdepth 2 -type f \( \
            -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.webp' \
        \) | sort | head -n 1 || true)"
        [[ -n "$first_wall" ]] && break
    done

    if [[ -n "$first_wall" ]] && command -v matugen >/dev/null 2>&1; then
        if (( DRY_RUN == 1 )); then
            log_info "Wallpaper detectado ($first_wall): en ejecución real se ofrecería generar la paleta inicial con matugen."
        elif ask_yes_no "Se encontró un wallpaper ($first_wall). ¿Generar paleta inicial con matugen ahora?" "y"; then
            matugen image "$first_wall" -m dark -t scheme-tonal-spot --source-color-index 0 -c "$XDG_CONFIG/matugen/config.toml" \
                || log_warn "matugen reportó un aviso (si no estás dentro de Hyprland/Wayland, es esperable)."
            log_ok "Paleta inicial generada con matugen."
        fi
    else
        log_info "Sin wallpapers locales aún: se usará la paleta oscura neutra fallback hasta agregar imágenes en ~/dotfiles/wallpapers o ~/Pictures/Wallpapers."
    fi
}

print_summary() {
    log_section "Resumen final"

    if (( DRY_RUN == 1 )); then
        log_warn "Modo --dry-run activo: no se modificó ningún archivo del sistema."
    else
        log_ok "Instalación completada correctamente."
    fi

    if (( BACKUP_USED == 1 )); then
        if (( DRY_RUN == 1 )); then
            log_info "Se crearía backup de archivos previos en: $BACKUP_DIR"
        else
            log_info "Backup de archivos previos guardado en: $BACKUP_DIR"
        fi
    else
        log_info "No fue necesario crear backup (no había conflictos previos)."
    fi

    cat <<EOF

  Próximos pasos recomendados:
    1. Copiá tus wallpapers favoritos en ~/dotfiles/wallpapers/ o ~/Pictures/Wallpapers/.
    2. Cerrá sesión (o reiniciá) y elegí Hyprland en tu display manager.
    3. Usá Super + W para abrir el selector visual de wallpapers y generar tu tema Material You en vivo.
    4. Si tenés GPU NVIDIA en laptop híbrida (Optimus), revisá las notas en config/hypr/lua/env.lua.
EOF
}

main() {
    parse_args "$@"
    if (( DRY_RUN == 1 )); then
        log_warn "Ejecutando en modo --dry-run (simulación sin cambios reales)."
    fi
    check_environment
    install_packages
    create_directories
    deploy_configs
    enable_services
    post_setup
    print_summary
}

main "$@"
