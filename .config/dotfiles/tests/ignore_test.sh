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
  .config/herdr/plugins.json
  .config/tmux/plugins/tpm/tpm
  .config/nvim/.luarc.json
  .config/example/credentials.local
  .config/example/secrets.local
)

for path in "${ignored_paths[@]}"; do
  assert_ignored_by_worktree_policy "$repo_dir" "$work_tree" "$path"
done

printf 'PASS: ignore policy\n'
