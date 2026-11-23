# =============================================================================
# Colores Zsh generados automáticamente por `matugen`
# Wallpaper origen: {{image}}
#
# Para recarga en vivo sin reiniciar la terminal, definí en tu `.zshrc`:
#   TRAPUSR1() { [[ -r ~/.config/zsh/matugen-colors.zsh ]] && source ~/.config/zsh/matugen-colors.zsh; }
# =============================================================================

# Variables de acento reutilizables (prompt, fzf, scripts, etc.)
export MATUGEN_PRIMARY="{{colors.primary.default.hex}}"
export MATUGEN_SECONDARY="{{colors.secondary.default.hex}}"
export MATUGEN_TERTIARY="{{colors.tertiary.default.hex}}"
export MATUGEN_BACKGROUND="{{colors.background.default.hex}}"
export MATUGEN_SURFACE="{{colors.surface.default.hex}}"
export MATUGEN_SURFACE_CONTAINER="{{colors.surface_container.default.hex}}"
export MATUGEN_ON_SURFACE="{{colors.on_surface.default.hex}}"
export MATUGEN_ON_SURFACE_VARIANT="{{colors.on_surface_variant.default.hex}}"
export MATUGEN_OUTLINE="{{colors.outline.default.hex}}"
export MATUGEN_ERROR="{{colors.error.default.hex}}"

# zsh-autosuggestions
export ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE="fg={{colors.outline.default.hex}}"

# zsh-syntax-highlighting
typeset -gA ZSH_HIGHLIGHT_STYLES
ZSH_HIGHLIGHT_STYLES[default]="fg={{colors.on_surface.default.hex}}"
ZSH_HIGHLIGHT_STYLES[unknown-token]="fg={{colors.error.default.hex}},bold"
ZSH_HIGHLIGHT_STYLES[reserved-word]="fg={{colors.tertiary.default.hex}},bold"
ZSH_HIGHLIGHT_STYLES[alias]="fg={{colors.primary.default.hex}}"
ZSH_HIGHLIGHT_STYLES[suffix-alias]="fg={{colors.primary.default.hex}},underline"
ZSH_HIGHLIGHT_STYLES[global-alias]="fg={{colors.primary.default.hex}},bold"
ZSH_HIGHLIGHT_STYLES[builtin]="fg={{colors.primary.default.hex}}"
ZSH_HIGHLIGHT_STYLES[function]="fg={{colors.primary.default.hex}}"
ZSH_HIGHLIGHT_STYLES[command]="fg={{colors.term_green.default.hex}}"
ZSH_HIGHLIGHT_STYLES[precommand]="fg={{colors.term_green.default.hex}},underline"
ZSH_HIGHLIGHT_STYLES[commandseparator]="fg={{colors.outline.default.hex}}"
ZSH_HIGHLIGHT_STYLES[path]="fg={{colors.secondary.default.hex}},underline"
ZSH_HIGHLIGHT_STYLES[path_prefix]="fg={{colors.on_surface_variant.default.hex}},underline"
ZSH_HIGHLIGHT_STYLES[globbing]="fg={{colors.tertiary.default.hex}}"
ZSH_HIGHLIGHT_STYLES[single-hyphen-option]="fg={{colors.term_cyan.default.hex}}"
ZSH_HIGHLIGHT_STYLES[double-hyphen-option]="fg={{colors.term_cyan.default.hex}}"
ZSH_HIGHLIGHT_STYLES[single-quoted-argument]="fg={{colors.term_yellow.default.hex}}"
ZSH_HIGHLIGHT_STYLES[double-quoted-argument]="fg={{colors.term_yellow.default.hex}}"
ZSH_HIGHLIGHT_STYLES[dollar-quoted-argument]="fg={{colors.term_yellow.default.hex}}"
ZSH_HIGHLIGHT_STYLES[back-quoted-argument]="fg={{colors.tertiary.default.hex}}"
ZSH_HIGHLIGHT_STYLES[redirection]="fg={{colors.secondary.default.hex}}"
ZSH_HIGHLIGHT_STYLES[comment]="fg={{colors.outline.default.hex}},italic"
ZSH_HIGHLIGHT_STYLES[arg0]="fg={{colors.term_green.default.hex}}"
