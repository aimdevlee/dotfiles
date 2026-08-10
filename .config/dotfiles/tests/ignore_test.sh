#!/usr/bin/env bash
set -euo pipefail

script_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
source "$script_dir/test_helpers.sh"

repo_dir=${DOTFILES_GIT_DIR:-"$HOME/.cfg"}
work_tree=${DOTFILES_WORK_TREE:-"$HOME"}

ignored_paths=(
  .cfg/HEAD
  .ssh/config
  .ssh/id_ed25519
  .zshrc.local
  .gitconfig.local
  .env
  .env.company
  .config/git/allowed_signers.local
  .config/herdr/session-history.json
  .config/herdr/herdr-server.log
  .config/herdr/herdr.sock
  .config/herdr/plugins/manifest.json
  .config/tmux/plugins/tpm/tpm
)

for path in "${ignored_paths[@]}"; do
  if ! ignored=$(git -C "$work_tree" --git-dir="$repo_dir" --work-tree="$work_tree" check-ignore -- "$path"); then
    fail "expected [$path] to be ignored"
  fi
  assert_eq "$path" "$ignored" "git check-ignore output"
done

printf 'PASS: ignore policy\n'
