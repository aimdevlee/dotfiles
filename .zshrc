export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME=""

# plugins=(git)
source $ZSH/oh-my-zsh.sh

fpath+=("$(brew --prefix)/share/zsh/site-functions")

source /opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh
source /opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

if type brew &>/dev/null; then
FPATH=$(brew --prefix)/share/zsh-completions:$FPATH

autoload -Uz compinit
compinit
fi

# history setup
HISTFILE=$HOME/.zsh_history
SAVEHIST=1000
HISTSIZE=999
setopt share_history
setopt hist_expire_dups_first
setopt hist_ignore_dups
setopt hist_verify

# asdf
. $(brew --prefix asdf)/libexec/asdf.sh

# z
. /opt/homebrew/etc/profile.d/z.sh

# fzf
eval "$(fzf --zsh)"

# Use fd instead of fzf
export FZF_DEFAULT_COMMAND='fd --hidden --strip-cwd-prefix --exclude .git'
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
bindkey "ç" fzf-cd-widget
export FZF_ALT_C_COMMAND='fd --type=d --hidden --strip-cwd-prefix --exclude .git'

# Use fd to generate the list for directory completion
_fzf_compgen_path() {
  fd --hidden --follow --exclude .git . "$1"
}

# Use fd to generate the list for directory completion
_fzf_compgen_dir() {
  fd --type d --hidden --exclude .git . "$1"
}

export FZF_CTRL_T_OPTS="--preview 'bat -n --color=always --line-range :500 {}'"
export FZF_ALT_C_OPTS="--preview 'eza --tree --color=always {} | head -200'"

# Advanced customization of fzf options via _fzf_comprun function
# - The first argument to the function is the name of the command.
# - You should make sure to pass the rest of the arguments to fzf.
_fzf_comprun() {
  local command=$1
  shift

  case "$command" in
    cd)           fzf --preview 'eza --tree --color=always {} | head -200' "$@" ;;
    export|unset) fzf --preview "eval 'echo $'{}"         "$@" ;;
    ssh)          fzf --preview 'dig {}'                   "$@" ;;
    *)            fzf --preview "bat -n --color=always --line-range :500 {}" "$@" ;;
  esac
}

# bat
export BAT_THEME=tokyonight_night

# eza
alias ls='eza --color=always --long --git --no-filesize --icons=always --no-time --no-user --no-permissions'

# direnv
eval "$(direnv hook zsh)"

# Check if nvim is in the path and if it is, set it as the default editor
# if command -v nvim > /dev/null 2>&1; then
#   alias vi='nvim'
#   alias vim='nvim'
# fi

# starship
export STARSHIP_CONFIG=~/.config/starship/starship.toml
eval "$(starship init zsh)"

# git bare repository
alias dotfiles='/usr/bin/git --git-dir=$HOME/.dotfiles.git --work-tree=$HOME'

# navi sheet path(same as config path)
export NAVI_PATH=$HOME/.config/navi

# yazi
export EDITOR=nvim
function y() {
	local tmp="$(mktemp -t "yazi-cwd.XXXXXX")" cwd
	yazi "$@" --cwd-file="$tmp"
	if cwd="$(command cat -- "$tmp")" && [ -n "$cwd" ] && [ "$cwd" != "$PWD" ]; then
		builtin cd -- "$cwd"
	fi
	rm -f -- "$tmp"
}
