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

if [[ -n ${IGNORE_TEST_PATHS:-} ]]; then
  ignored_paths=()
  while IFS= read -r path; do
    [[ -n $path ]] && ignored_paths+=("$path")
  done <<EOF
${IGNORE_TEST_PATHS}
EOF
fi

for path in "${ignored_paths[@]}"; do
  if ! ignored=$(git -c core.excludesFile=/dev/null -C "$work_tree" --git-dir="$repo_dir" --work-tree="$work_tree" check-ignore -v -- "$path"); then
    fail "expected [$path] to be ignored"
  fi
  source=${ignored%%$'\t'*}
  matched_path=${ignored#*$'\t'}
  assert_eq "$path" "$matched_path" "git check-ignore output"
  [[ $source == .gitignore:* ]] || fail "expected [$path] to match the worktree .gitignore, got [$source]"
done

printf 'PASS: ignore policy\n'
