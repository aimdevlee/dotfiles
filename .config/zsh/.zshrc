# history
setopt SHARE_HISTORY
setopt hist_expire_dups_first
setopt hist_ignore_dups

# completion
FPATH=$(brew --prefix)/share/zsh-completions:$FPATH
source $(brew --prefix)/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
source $(brew --prefix)/share/zsh-autosuggestions/zsh-autosuggestions.zsh

autoload -Uz compinit
compinit

zstyle ':completion:*' menu select

# keybind
bindkey -e

# alias
alias ls=eza

# for bare repo
# Do this after init bare repo config
# config config --local status.showUntrackedFiles no
alias config='/usr/bin/git --git-dir=$HOME/.cfg/ --work-tree=$HOME'

source <(fzf --zsh)
eval "$(zoxide init zsh)"
eval "$(oh-my-posh init zsh --config 'pure')"
eval "$(direnv hook zsh)"
eval "$(mise activate zsh)"

# Source local configuration if exists (contains sensitive functions)
[ -f "$HOME/.zshrc.local" ] && source "$HOME/.zshrc.local"

