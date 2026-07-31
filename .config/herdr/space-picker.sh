#!/bin/sh
# Pick a directory with fzf and open it as a new herdr workspace.
#
# Companion to worktree-picker.sh (prefix+C-f), which only lists worktrees of
# the repo you are already in. This one covers any project: zoxide's frecency
# list first, then every top-level directory under ~/Developer so freshly
# cloned repos show up before they have been visited.

set -eu

dir=$(
  {
    zoxide query -l
    fd --type d --max-depth 1 --absolute-path . "$HOME/Developer" | sed 's:/$::'
  } | awk '!seen[$0]++' | fzf --prompt='new space> ' --reverse --height=100%
) || exit 0

# zoxide keeps entries for directories that have since been deleted.
[ -d "$dir" ] || exit 0

herdr workspace create --cwd "$dir" --label "$(basename "$dir")" --focus
