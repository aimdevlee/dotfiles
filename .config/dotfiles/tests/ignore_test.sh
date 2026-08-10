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

git_config_path="$work_tree/.config/git/config"
git_config=$(<"$git_config_path")

if [[ $git_config == *aimdevlee* || $git_config == *'@gmail.com'* ]]; then
  fail 'tracked Git config contains a personal identity'
fi

assert_contains 'useConfigOnly = true' "$git_config" 'tracked Git config requires local-only identity' || exit 1
assert_contains 'path = ~/.gitconfig.local' "$git_config" 'tracked Git config includes local identity' || exit 1

make_test_root
fixture_home="$TEST_ROOT/home"
fixture_xdg_config="$fixture_home/.config"
fixture_key="$fixture_home/.ssh/id_ed25519"
fixture_config="$fixture_home/.gitconfig"
fixture_local_config="$fixture_home/.gitconfig.local"
fixture_allowed_signers="$fixture_xdg_config/git/allowed_signers.local"

cleanup_fixture() {
  cleanup_test_root
}
trap cleanup_fixture EXIT

mkdir -p "$fixture_home/.ssh" "$fixture_xdg_config/git"
cp "$git_config_path" "$fixture_config"
cp "$work_tree/.config/dotfiles/templates/gitconfig.local.example" "$fixture_local_config"
cp "$work_tree/.config/dotfiles/templates/allowed_signers.local.example" "$fixture_allowed_signers"
ssh-keygen -q -t ed25519 -N '' -f "$fixture_key"
sed -i '' \
  -e 's/Your Name/Dotfiles Test/' \
  -e 's/you@example.com/dotfiles-test@example.invalid/g' \
  -e 's|REPLACE_WITH_YOUR_PUBLIC_KEY|'"$(awk '{print $2}' "$fixture_key.pub")"'|' \
  "$fixture_local_config" "$fixture_allowed_signers"

fixture_git_config() {
  GIT_CONFIG_NOSYSTEM=1 HOME="$fixture_home" XDG_CONFIG_HOME="$fixture_xdg_config" \
    git config --global --includes --get "$1"
}

assert_eq 'Dotfiles Test' "$(fixture_git_config user.name)" 'fixture Git user name' || exit 1
assert_eq 'dotfiles-test@example.invalid' "$(fixture_git_config user.email)" 'fixture Git user email' || exit 1
assert_eq '~/.ssh/id_ed25519.pub' "$(fixture_git_config user.signingKey)" 'fixture Git signing key' || exit 1
assert_eq '~/.config/git/allowed_signers.local' "$(fixture_git_config gpg.ssh.allowedSignersFile)" 'fixture Git allowed signers file' || exit 1

printf 'PASS: ignore policy\n'
