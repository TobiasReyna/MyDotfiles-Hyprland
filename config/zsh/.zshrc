# =============================================================================
# Zsh — Configuración modular para Arch Linux + Ghostty + Material You
# Enlazado por `install.sh` hacia ~/.zshrc
# =============================================================================

# Salir temprano en shells no interactivas
[[ -o interactive ]] || return

# -----------------------------------------------------------------------------
# PATH y variables de entorno
# -----------------------------------------------------------------------------
typeset -U path PATH
path=("$HOME/.local/bin" $path)
export PATH

if command -v nvim >/dev/null 2>&1; then
    export EDITOR="nvim"
    export VISUAL="nvim"
else
    export EDITOR="nano"
    export VISUAL="nano"
fi

# -----------------------------------------------------------------------------
# Historial robusto (XDG-compliant)
# -----------------------------------------------------------------------------
ZSH_STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/zsh"
ZSH_CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/zsh"
[[ -d "$ZSH_STATE_DIR" ]] || mkdir -p "$ZSH_STATE_DIR"
[[ -d "$ZSH_CACHE_DIR" ]] || mkdir -p "$ZSH_CACHE_DIR"

HISTFILE="$ZSH_STATE_DIR/history"
HISTSIZE=20000
SAVEHIST=20000

setopt EXTENDED_HISTORY
setopt HIST_EXPIRE_DUPS_FIRST
setopt HIST_IGNORE_DUPS
setopt HIST_IGNORE_ALL_DUPS
setopt HIST_FIND_NO_DUPS
setopt HIST_IGNORE_SPACE
setopt HIST_SAVE_NO_DUPS
setopt HIST_REDUCE_BLANKS
setopt SHARE_HISTORY
setopt AUTO_CD
setopt INTERACTIVE_COMMENTS

# -----------------------------------------------------------------------------
# Autocompletado nativo (compinit cacheado)
# -----------------------------------------------------------------------------
autoload -Uz compinit
compinit -d "$ZSH_CACHE_DIR/zcompdump"

zmodload zsh/complist
zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}' 'r:|[._-]=* r:|=*' 'l:|=* r:|=*'
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
zstyle ':completion:*' group-name ''
zstyle ':completion:*:descriptions' format '%F{8}-- %d --%f'

# -----------------------------------------------------------------------------
# Edición de línea y búsqueda por prefijo con flechas Arriba/Abajo
# -----------------------------------------------------------------------------
bindkey -e
autoload -Uz up-line-or-beginning-search down-line-or-beginning-search
zle -N up-line-or-beginning-search
zle -N down-line-or-beginning-search

bindkey '^[[A' up-line-or-beginning-search
bindkey '^[[B' down-line-or-beginning-search
[[ -n "${terminfo[kcuu1]:-}" ]] && bindkey "${terminfo[kcuu1]}" up-line-or-beginning-search
[[ -n "${terminfo[kcud1]:-}" ]] && bindkey "${terminfo[kcud1]}" down-line-or-beginning-search
bindkey '^[[3~' delete-char
bindkey '^[[H' beginning-of-line
bindkey '^[[F' end-of-line
bindkey '^[[1;5C' forward-word
bindkey '^[[1;5D' backward-word

# -----------------------------------------------------------------------------
# Colores dinámicos de Matugen + recarga en caliente con SIGUSR1
# -----------------------------------------------------------------------------
load_matugen_colors() {
    local colors_file="${XDG_CONFIG_HOME:-$HOME/.config}/zsh/matugen-colors.zsh"
    if [[ -r "$colors_file" ]]; then
        source "$colors_file"
    elif [[ -r "$HOME/dotfiles/config/zsh/matugen-colors.zsh" ]]; then
        source "$HOME/dotfiles/config/zsh/matugen-colors.zsh"
    fi
}

# `scripts/wallpaper.sh` verifica que este proceso atrape SIGUSR1 (bit 0x200 en
# SigCgt) antes de enviar la señal para actualizar colores sin cerrar la sesión.
TRAPUSR1() {
    load_matugen_colors
    if zle; then
        zle reset-prompt
    fi
}

# -----------------------------------------------------------------------------
# Aliases y utilidades para Arch Linux y el entorno Hyprland
# -----------------------------------------------------------------------------
alias ls='ls --color=auto'
alias ll='ls -lh --color=auto'
alias la='ls -lAh --color=auto'
alias grep='grep --color=auto'

alias wall='wallpaper.sh'
alias wallrand='wallpaper.sh --random'
alias reload-hypr='hyprctl reload'
alias minifetch='fastfetch --config "${XDG_CONFIG_HOME:-$HOME/.config}/fastfetch/mini.jsonc"'

update() {
    if command -v yay >/dev/null 2>&1; then
        yay -Syu "$@"
    elif command -v paru >/dev/null 2>&1; then
        paru -Syu "$@"
    else
        sudo pacman -Syu "$@"
    fi
}

cleanup() {
    local -a orphans
    orphans=(${(f)"$(pacman -Qtdq 2>/dev/null)"})
    if (( ${#orphans[@]} > 0 )); then
        sudo pacman -Rns "${orphans[@]}"
    else
        print "No hay paquetes huérfanos para eliminar."
    fi
}

# -----------------------------------------------------------------------------
# Prompt Starship
# -----------------------------------------------------------------------------
if command -v starship >/dev/null 2>&1; then
    eval "$(starship init zsh)"
fi

# -----------------------------------------------------------------------------
# Plugins de Zsh (orden estricto: autosuggestions -> syntax-highlighting al final)
# -----------------------------------------------------------------------------
if [[ -r /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh ]]; then
    source /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh
fi

if [[ -r /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ]]; then
    source /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
fi

# Aplicar paleta de Matugen después de cargar los plugins para sobrescribir
# ZSH_HIGHLIGHT_STYLES y ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE.
load_matugen_colors

# -----------------------------------------------------------------------------
# Mini fetch automático al abrir Ghostty (solo 1er nivel, sin subshells/tmux)
# -----------------------------------------------------------------------------
if [[ -o interactive ]] \
    && [[ "${TERM_PROGRAM:-}" == "ghostty" || -n "${GHOSTTY_RESOURCES_DIR:-}" ]] \
    && [[ "${SHLVL:-1}" -eq 1 ]] \
    && [[ -z "${TMUX:-}" && -z "${VSCODE_PID:-}" ]] \
    && command -v fastfetch >/dev/null 2>&1 \
    && [[ -r "${XDG_CONFIG_HOME:-$HOME/.config}/fastfetch/mini.jsonc" ]]; then
    fastfetch --config "${XDG_CONFIG_HOME:-$HOME/.config}/fastfetch/mini.jsonc"
fi
