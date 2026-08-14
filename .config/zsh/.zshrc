# history
setopt SHARE_HISTORY
setopt hist_expire_dups_first
setopt hist_ignore_dups

# completion
_dotfiles_init_brew_completions() {
  local brew_prefix

  if (( $+commands[brew] )); then
    brew_prefix="$(brew --prefix)"
    if [[ -d "$brew_prefix/share/zsh-completions" ]]; then
      FPATH="$brew_prefix/share/zsh-completions:$FPATH"
    fi
    if [[ -r "$brew_prefix/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" ]]; then
      source "$brew_prefix/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
    fi
    if [[ -r "$brew_prefix/share/zsh-autosuggestions/zsh-autosuggestions.zsh" ]]; then
      source "$brew_prefix/share/zsh-autosuggestions/zsh-autosuggestions.zsh"
    fi
  fi
}

_dotfiles_init_brew_completions
unfunction _dotfiles_init_brew_completions

autoload -Uz compinit
compinit

zstyle ':completion:*' menu select

# keybind
bindkey -e

# for bare repo
# Do this after init bare repo config
# config config --local status.showUntrackedFiles no
alias config='/usr/bin/git --git-dir=$HOME/.cfg/ --work-tree=$HOME'

if (( $+commands[eza] )); then
  alias ls=eza
fi
if (( $+commands[fzf] )) && [[ -o interactive && -t 0 && -t 1 ]]; then
  source <(fzf --zsh)
fi
if (( $+commands[zoxide] )); then
  eval "$(zoxide init zsh)"
fi
if (( $+commands[oh-my-posh] )) && [[ -r "$HOME/.config/omp/pure.omp.json" ]]; then
  eval "$(oh-my-posh init zsh --config "$HOME/.config/omp/pure.omp.json")"
fi
if (( $+commands[direnv] )); then
  eval "$(direnv hook zsh)"
fi
if (( $+commands[mise] )); then
  eval "$(mise activate zsh)"
fi

# Source local configuration if exists (contains sensitive functions)
[[ -r "$ZDOTDIR/.zshrc.local" ]] && source "$ZDOTDIR/.zshrc.local"
