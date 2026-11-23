#!/usr/bin/env bash
# =============================================================================
# wallpaper.sh — Gestor de wallpapers (awww) + Material You (matugen)
#
# Uso:
#   wallpaper.sh /ruta/a/imagen.jpg      Aplica un wallpaper específico
#   wallpaper.sh --random [directorio]   Aplica un wallpaper aleatorio distinto
#   wallpaper.sh --restore               Restaura el último wallpaper guardado
#   wallpaper.sh --list [directorio]     Lista wallpapers en JSON (para Quickshell)
#   wallpaper.sh --list --plain [dir]    Lista rutas limpias (una por línea)
#   wallpaper.sh --current               Imprime la ruta del wallpaper actual
#
# Variables opcionales de entorno:
#   WALLPAPER_DIR    Directorio por defecto de wallpapers
#   MATUGEN_MODE     Modo de color de matugen (default: dark)
#   MATUGEN_SCHEME   Esquema Material You (default: scheme-tonal-spot)
# =============================================================================

set -euo pipefail

STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/wallpaper"
STATE_FILE="$STATE_DIR/current_path"
CACHE_LINK="${XDG_CACHE_HOME:-$HOME/.cache}/current_wallpaper"

MATUGEN_MODE="${MATUGEN_MODE:-dark}"
MATUGEN_SCHEME="${MATUGEN_SCHEME:-scheme-tonal-spot}"

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd -- "$SCRIPT_DIR/.." && pwd)"

usage() {
    cat <<'EOF'
Uso: wallpaper.sh [OPCIÓN | RUTA_IMAGEN]

Modos:
  <ruta/a/imagen>             Aplica la imagen indicada como wallpaper y regenera colores
  --random [directorio]       Elige un wallpaper aleatorio distinto al actual
  --restore                   Restaura el último wallpaper guardado al iniciar sesión
  --list [--plain] [dir]      Lista wallpapers disponibles en JSON (o líneas con --plain)
  --current                   Muestra la ruta del wallpaper actualmente activo
  -h, --help                  Muestra esta ayuda
EOF
}

resolve_wallpaper_dir() {
    local requested="${1:-}"
    if [[ -n "$requested" ]]; then
        printf '%s\n' "$requested"
        return 0
    fi
    if [[ -n "${WALLPAPER_DIR:-}" && -d "$WALLPAPER_DIR" ]]; then
        printf '%s\n' "$WALLPAPER_DIR"
        return 0
    fi
    if [[ -d "$HOME/dotfiles/wallpapers" ]]; then
        printf '%s\n' "$HOME/dotfiles/wallpapers"
        return 0
    fi
    if [[ -d "$REPO_DIR/wallpapers" ]]; then
        printf '%s\n' "$REPO_DIR/wallpapers"
        return 0
    fi
    if [[ -d "$HOME/Pictures/Wallpapers" ]]; then
        printf '%s\n' "$HOME/Pictures/Wallpapers"
        return 0
    fi
    printf '%s\n' "$HOME/dotfiles/wallpapers"
}

get_current_wallpaper() {
    if [[ -f "$STATE_FILE" ]]; then
        cat "$STATE_FILE"
    elif [[ -L "$CACHE_LINK" ]]; then
        readlink -f "$CACHE_LINK" || true
    fi
}

collect_wallpapers() {
    local dir="$1"
    [[ -d "$dir" ]] || return 0
    find "$dir" -maxdepth 3 -type f \( \
        -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' \
        -o -iname '*.webp' -o -iname '*.gif' -o -iname '*.avif' -o -iname '*.jxl' \
    \) -print0 | sort -z
}

ensure_awww_daemon() {
    if ! command -v awww >/dev/null 2>&1; then
        echo "Error: 'awww' no está instalado." >&2
        return 1
    fi

    if awww query >/dev/null 2>&1; then
        return 0
    fi

    if command -v awww-daemon >/dev/null 2>&1; then
        nohup awww-daemon >/dev/null 2>&1 &
        disown || true
        local attempt
        for attempt in $(seq 1 30); do
            if awww query >/dev/null 2>&1; then
                return 0
            fi
            sleep 0.1
        done
    fi

    echo "Advertencia: awww-daemon no respondió a tiempo." >&2
    return 1
}

resolve_matugen_config() {
    local xdg_cfg="${XDG_CONFIG_HOME:-$HOME/.config}/matugen/config.toml"
    if [[ -f "$xdg_cfg" ]]; then
        printf '%s\n' "$xdg_cfg"
    elif [[ -f "$HOME/dotfiles/config/matugen/config.toml" ]]; then
        printf '%s\n' "$HOME/dotfiles/config/matugen/config.toml"
    elif [[ -f "$REPO_DIR/config/matugen/config.toml" ]]; then
        printf '%s\n' "$REPO_DIR/config/matugen/config.toml"
    else
        return 1
    fi
}

# Envía SIGUSR1 únicamente a sesiones `zsh` del usuario actual que tengan un
# manejador de señal registrado (bit 9 = 0x200 en SigCgt), evitando cerrar
# terminales abiertas que aún no definieron TRAPUSR1.
reload_zsh_safely() {
    local pid sigcgt_hex sigcgt_dec
    while IFS= read -r pid; do
        [[ -r "/proc/$pid/status" ]] || continue
        sigcgt_hex="$(awk '/^SigCgt:/ { print $2 }' "/proc/$pid/status" 2>/dev/null || true)"
        [[ -n "$sigcgt_hex" ]] || continue
        sigcgt_dec=$((16#$sigcgt_hex))
        if (( (sigcgt_dec & 0x200) != 0 )); then
            kill -USR1 "$pid" 2>/dev/null || true
        fi
    done < <(pgrep -u "$USER" -x zsh 2>/dev/null || true)
}

reload_apps() {
    # Hyprland (solo si hay sesión activa)
    if [[ -n "${HYPRLAND_INSTANCE_SIGNATURE:-}" ]] && command -v hyprctl >/dev/null 2>&1; then
        hyprctl reload >/dev/null 2>&1 || true
    fi

    # Ghostty 1.4+ recarga configuración y tema en vivo con SIGUSR2
    pkill -USR2 ghostty >/dev/null 2>&1 || true

    # Zsh interactivo (solo procesos con TRAPUSR1 activo)
    reload_zsh_safely
}

apply_wallpaper() {
    local input_path="$1"
    if [[ ! -f "$input_path" ]]; then
        echo "Error: no existe el archivo de imagen: $input_path" >&2
        exit 1
    fi

    local abs_path
    abs_path="$(realpath "$input_path")"

    # 1. Aplicar wallpaper con awww y transición fluida
    if ensure_awww_daemon; then
        awww img "$abs_path" \
            --transition-type grow \
            --transition-fps 144 \
            --transition-duration 1.2 \
            --transition-bezier .22,1,.36,1
    fi

    # 2. Persistir ruta actual y actualizar symlink en ~/.cache/current_wallpaper
    mkdir -p "$STATE_DIR" "$(dirname "$CACHE_LINK")"
    printf '%s\n' "$abs_path" > "$STATE_FILE"
    ln -sfn "$abs_path" "$CACHE_LINK"

    # 3. Regenerar paleta Material You con matugen
    if command -v matugen >/dev/null 2>&1; then
        local cfg
        if cfg="$(resolve_matugen_config)"; then
            # Asegurar directorios de salida antes de renderizar templates
            mkdir -p \
                "${XDG_CONFIG_HOME:-$HOME/.config}/hypr/lua" \
                "${XDG_CONFIG_HOME:-$HOME/.config}/quickshell" \
                "${XDG_CONFIG_HOME:-$HOME/.config}/ghostty/themes" \
                "${XDG_CONFIG_HOME:-$HOME/.config}/zsh"

            matugen image "$abs_path" \
                -m "$MATUGEN_MODE" \
                -t "$MATUGEN_SCHEME" \
                --source-color-index 0 \
                -c "$cfg" || echo "Advertencia: matugen terminó con errores." >&2
        else
            echo "Advertencia: no se encontró config.toml de matugen." >&2
        fi
    fi

    # 4. Recarga segura de aplicaciones activas
    reload_apps
}

cmd_random() {
    local dir
    dir="$(resolve_wallpaper_dir "${1:-}")"

    local -a files=()
    while IFS= read -r -d '' f; do
        files+=("$f")
    done < <(collect_wallpapers "$dir")

    if (( ${#files[@]} == 0 )); then
        echo "No se encontraron wallpapers en: $dir" >&2
        exit 1
    fi

    local current
    current="$(get_current_wallpaper)"

    local -a candidates=()
    local f
    for f in "${files[@]}"; do
        if [[ "$f" != "$current" ]]; then
            candidates+=("$f")
        fi
    done

    # Si solo hay un wallpaper en el directorio, usar ese mismo
    if (( ${#candidates[@]} == 0 )); then
        candidates=("${files[@]}")
    fi

    local selected="${candidates[RANDOM % ${#candidates[@]}]}"
    apply_wallpaper "$selected"
}

cmd_restore() {
    local current
    current="$(get_current_wallpaper)"

    if [[ -n "$current" && -f "$current" ]]; then
        apply_wallpaper "$current"
        return 0
    fi

    # Si todavía no hay wallpaper guardado, intentar elegir uno aleatorio si existe alguno
    local dir
    dir="$(resolve_wallpaper_dir "")"
    local -a files=()
    while IFS= read -r -d '' f; do
        files+=("$f")
    done < <(collect_wallpapers "$dir")

    if (( ${#files[@]} > 0 )); then
        apply_wallpaper "${files[0]}"
    fi
}

cmd_list() {
    local plain=0
    local dir_arg=""

    while (( $# > 0 )); do
        case "$1" in
            --plain) plain=1 ;;
            *) dir_arg="$1" ;;
        esac
        shift
    done

    local dir
    dir="$(resolve_wallpaper_dir "$dir_arg")"
    local current
    current="$(get_current_wallpaper)"

    local -a files=()
    while IFS= read -r -d '' f; do
        files+=("$f")
    done < <(collect_wallpapers "$dir")

    if (( plain == 1 )); then
        local f
        for f in "${files[@]}"; do
            printf '%s\n' "$f"
        done
        return 0
    fi

    # Salida JSON pensada para el selector visual en Quickshell
    if command -v jq >/dev/null 2>&1; then
        if (( ${#files[@]} == 0 )); then
            printf '[]\n'
            return 0
        fi
        printf '%s\0' "${files[@]}" | jq -R -s --arg current "$current" '
            split("\u0000")
            | map(select(length > 0))
            | map({
                name: (split("/") | last),
                path: .,
                active: (. == $current)
            })
        '
    else
        # Fallback sin jq
        printf '['
        local i f esc_path esc_name active
        for i in "${!files[@]}"; do
            f="${files[$i]}"
            esc_path="${f//\\/\\\\}"
            esc_path="${esc_path//\"/\\\"}"
            esc_name="$(basename -- "$f")"
            esc_name="${esc_name//\\/\\\\}"
            esc_name="${esc_name//\"/\\\"}"
            active="false"
            [[ "$f" == "$current" ]] && active="true"
            (( i > 0 )) && printf ','
            printf '{"name":"%s","path":"%s","active":%s}' "$esc_name" "$esc_path" "$active"
        done
        printf ']\n'
    fi
}

main() {
    if (( $# == 0 )); then
        usage
        exit 1
    fi

    case "$1" in
        -h|--help)
            usage
            ;;
        --random)
            shift
            cmd_random "${1:-}"
            ;;
        --restore)
            cmd_restore
            ;;
        --list)
            shift
            cmd_list "$@"
            ;;
        --current)
            get_current_wallpaper
            ;;
        -*)
            echo "Opción desconocida: $1" >&2
            usage >&2
            exit 1
            ;;
        *)
            apply_wallpaper "$1"
            ;;
    esac
}

main "$@"
