# =============================================================================
# Colores Zsh fallback — Material You (modo oscuro neutro)
# NOTA: Este archivo será sobrescrito dinámicamente por `matugen` usando
# `config/matugen/templates/zsh-colors.zsh`.
# =============================================================================

# Variables de acento reutilizables (prompt, fzf, scripts, etc.)
export MATUGEN_PRIMARY="#b8c4e0"
export MATUGEN_SECONDARY="#c2c6d4"
export MATUGEN_TERTIARY="#d4c0d8"
export MATUGEN_BACKGROUND="#131316"
export MATUGEN_SURFACE="#1b1b1f"
export MATUGEN_SURFACE_CONTAINER="#1f1f24"
export MATUGEN_ON_SURFACE="#e4e2e6"
export MATUGEN_ON_SURFACE_VARIANT="#c5c6d0"
export MATUGEN_OUTLINE="#8e9099"
export MATUGEN_ERROR="#ffb4ab"

# zsh-autosuggestions
export ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE="fg=#8e9099"

# zsh-syntax-highlighting
typeset -gA ZSH_HIGHLIGHT_STYLES
ZSH_HIGHLIGHT_STYLES[default]="fg=#e4e2e6"
ZSH_HIGHLIGHT_STYLES[unknown-token]="fg=#ffb4ab,bold"
ZSH_HIGHLIGHT_STYLES[reserved-word]="fg=#d4c0d8,bold"
ZSH_HIGHLIGHT_STYLES[alias]="fg=#b8c4e0"
ZSH_HIGHLIGHT_STYLES[suffix-alias]="fg=#b8c4e0,underline"
ZSH_HIGHLIGHT_STYLES[global-alias]="fg=#b8c4e0,bold"
ZSH_HIGHLIGHT_STYLES[builtin]="fg=#b8c4e0"
ZSH_HIGHLIGHT_STYLES[function]="fg=#b8c4e0"
ZSH_HIGHLIGHT_STYLES[command]="fg=#a6e3a1"
ZSH_HIGHLIGHT_STYLES[precommand]="fg=#a6e3a1,underline"
ZSH_HIGHLIGHT_STYLES[commandseparator]="fg=#8e9099"
ZSH_HIGHLIGHT_STYLES[path]="fg=#c2c6d4,underline"
ZSH_HIGHLIGHT_STYLES[path_prefix]="fg=#c5c6d0,underline"
ZSH_HIGHLIGHT_STYLES[globbing]="fg=#d4c0d8"
ZSH_HIGHLIGHT_STYLES[single-hyphen-option]="fg=#94e2d5"
ZSH_HIGHLIGHT_STYLES[double-hyphen-option]="fg=#94e2d5"
ZSH_HIGHLIGHT_STYLES[single-quoted-argument]="fg=#f9e2af"
ZSH_HIGHLIGHT_STYLES[double-quoted-argument]="fg=#f9e2af"
ZSH_HIGHLIGHT_STYLES[dollar-quoted-argument]="fg=#f9e2af"
ZSH_HIGHLIGHT_STYLES[back-quoted-argument]="fg=#d4c0d8"
ZSH_HIGHLIGHT_STYLES[redirection]="fg=#c2c6d4"
ZSH_HIGHLIGHT_STYLES[comment]="fg=#8e9099,italic"
ZSH_HIGHLIGHT_STYLES[arg0]="fg=#a6e3a1"
