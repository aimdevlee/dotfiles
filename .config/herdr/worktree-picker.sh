#!/bin/sh
# Pick a git worktree with fzf and open it as a herdr workspace.
#
# Stands in for the tmux-sessionizer popup that used to be on prefix+C-f:
# tmux-sessionizer creates tmux sessions, which mean nothing under herdr.
# Creating worktrees is left to the dev-start skill, which also brings up the
# baton server -- this only opens ones that already exist.

set -eu

if ! root=$(git rev-parse --show-toplevel 2>/dev/null); then
  printf 'Not inside a git repository (cwd: %s)\n' "$(pwd)"
  printf 'Press enter to close: '
  read -r _
  exit 0
fi

# `git worktree list` prints "<path>  <sha> [<branch>]".
selection=$(git -C "$root" worktree list | fzf --prompt='worktree> ' --reverse --height=100%) || exit 0
[ -n "$selection" ] || exit 0

path=${selection%% *}
[ -d "$path" ] || exit 0

herdr worktree open --path "$path" --label "$(basename "$path")"
