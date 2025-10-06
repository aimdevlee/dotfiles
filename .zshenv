# Define XDG Base directory environment variables
export XDG_CACHE_HOME="$HOME/.cache"
export XDG_CONFIG_HOME="$HOME/.config"
export XDG_DATA_HOME="$HOME/.local/share"
export XDG_STATE_HOME="$HOME/.local/state"

# zsh configuration.
export ZDOTDIR="$XDG_CONFIG_HOME/zsh"

# uv
export PATH="$HOME/.local/share/../bin:$PATH"

# FZF configuration
export FZF_DEFAULT_OPTS="--color=fg+:#e0def4,bg+:#393552,hl+:#ea9a97 --color=border:#44415a,header:#3e8fb0,gutter:#232136 --color=spinner:#f6c177,info:#9ccfd8 --color=pointer:#c4a7e7,marker:#eb6f92,prompt:#908caa"
FD_OPTS="--hidden --follow --strip-cwd-prefix --exclude .git"
export FZF_DEFAULT_COMMAND="fd --type=f $FD_OPTS"
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
bindkey "ç" fzf-cd-widget
export FZF_ALT_C_COMMAND="fd --type=d $FD_OPTS"
export FZF_CTRL_T_OPTS="--preview 'bat -n --color=always --line-range :500 {}'"
export FZF_ALT_C_OPTS="--preview 'eza --tree --color=always {} | head -200'"
# pnpm
export PNPM_HOME="/Users/dongbin-lee/.local/share/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
  *) export PATH="$PNPM_HOME:$PATH" ;;
esac
# pnpm end


# Man pages
export MANPAGER='nvim +Man!'

# Set up neovim as the default editor.
export EDITOR="$(which nvim)"
export VISUAL="$EDITOR"
