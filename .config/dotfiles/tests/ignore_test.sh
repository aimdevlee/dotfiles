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
  .config/tmux-sessionizer/tmux-sessionizer.local.conf
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

assert_eq_quiet() {
  local expected=$1
  local actual=$2
  local message=$3

  [[ $expected == "$actual" ]] || fail "$message"
}

run_config_file() {
  env -i PATH=/usr/bin:/bin LC_ALL=C TMPDIR=/tmp GIT_CONFIG_NOSYSTEM=1 git config "$@"
}

assert_common_git_config_policy() {
  local config_path=$1
  local key
  local value

  for key in user.name user.email user.signingKey; do
    if run_config_file --file "$config_path" --get "$key" >/dev/null 2>&1; then
      fail "tracked Git config must not define $key"
      return 1
    fi
  done

  if ! value=$(run_config_file --bool --file "$config_path" --get user.useConfigOnly 2>/dev/null); then
    fail 'tracked Git config must enable user.useConfigOnly'
    return 1
  fi
  assert_eq_quiet true "$value" 'tracked Git config must enable user.useConfigOnly' || return 1

  if ! value=$(run_config_file --file "$config_path" --get include.path 2>/dev/null); then
    fail 'tracked Git config must include a local identity file'
    return 1
  fi
  assert_eq_quiet '~/.gitconfig.local' "$value" 'tracked Git config must include ~/.gitconfig.local' || return 1
}

canonical_file_path() {
  local path=$1
  local directory

  directory=$(cd -P -- "$(dirname -- "$path")" && pwd)
  printf '%s/%s\n' "$directory" "$(basename -- "$path")"
}

git_config_path="$work_tree/.config/git/config"
assert_common_git_config_policy "$git_config_path" || exit 1

make_test_root
fixture_home="$TEST_ROOT/home"
fixture_xdg_config="$fixture_home/.config"
fixture_key="$fixture_home/.ssh/id_ed25519"
fixture_common_config="$fixture_xdg_config/git/config"
fixture_local_config="$fixture_home/.gitconfig.local"
fixture_allowed_signers="$fixture_xdg_config/git/allowed_signers.local"

cleanup_fixture() {
  cleanup_test_root
}
trap cleanup_fixture EXIT

mkdir -p "$fixture_home/.ssh" "$fixture_xdg_config/git"
cp "$git_config_path" "$fixture_common_config"

identity_config="$TEST_ROOT/identity.gitconfig"
cp "$git_config_path" "$identity_config"
printf '\n[user]\n  email = secret@company.invalid\n' >> "$identity_config"
if assert_common_git_config_policy "$identity_config" >/dev/null 2>&1; then
  fail 'Git config policy accepted an arbitrary identity'
fi

commented_config="$TEST_ROOT/commented.gitconfig"
sed 's/useConfigOnly = true/# useConfigOnly = true/' "$git_config_path" > "$commented_config"
if assert_common_git_config_policy "$commented_config" >/dev/null 2>&1; then
  fail 'Git config policy accepted a commented-only useConfigOnly setting'
fi

cp "$work_tree/.config/dotfiles/templates/gitconfig.local.example" "$fixture_local_config"
cp "$work_tree/.config/dotfiles/templates/allowed_signers.local.example" "$fixture_allowed_signers"
ssh-keygen -q -t ed25519 -N '' -f "$fixture_key"
sed -i '' \
  -e 's/Your Name/Dotfiles Test/' \
  -e 's/you@example.com/dotfiles-test@example.invalid/g' \
  -e 's|REPLACE_WITH_YOUR_PUBLIC_KEY|'"$(awk '{print $2}' "$fixture_key.pub")"'|' \
  "$fixture_local_config" "$fixture_allowed_signers"

run_fixture_git() {
  env -i HOME="$fixture_home" XDG_CONFIG_HOME="$fixture_xdg_config" PATH=/usr/bin:/bin LC_ALL=C TMPDIR=/tmp \
    git "$@"
}

assert_fixture_git_setting() {
  local key=$1
  local expected_value=$2
  local expected_origin=$3
  local description=$4
  local setting
  local origin
  local value

  if ! setting=$(run_fixture_git config --global --includes --show-origin --get "$key"); then
    fail "$description is unavailable in the fixture"
    return 1
  fi
  origin=${setting%%$'\t'*}
  value=${setting#*$'\t'}
  [[ $origin == file:* && $setting == *$'\t'* ]] || {
    fail "$description did not report a file origin"
    return 1
  }
  origin=${origin#file:}
  assert_eq_quiet "$expected_value" "$value" "$description resolved an unexpected value" || return 1
  assert_eq_quiet "$(canonical_file_path "$expected_origin")" "$(canonical_file_path "$origin")" "$description resolved from an unexpected file"
}

assert_fixture_git_setting user.name 'Dotfiles Test' "$fixture_local_config" 'fixture Git user name' || exit 1
assert_fixture_git_setting user.email 'dotfiles-test@example.invalid' "$fixture_local_config" 'fixture Git user email' || exit 1
assert_fixture_git_setting user.signingKey '~/.ssh/id_ed25519.pub' "$fixture_local_config" 'fixture Git signing key' || exit 1
assert_fixture_git_setting gpg.ssh.allowedSignersFile '~/.config/git/allowed_signers.local' "$fixture_local_config" 'fixture Git allowed signers file' || exit 1
assert_fixture_git_setting user.useConfigOnly true "$fixture_common_config" 'fixture Git local-only identity policy' || exit 1

hostile_global_config="$TEST_ROOT/hostile.gitconfig"
printf '[user]\n  name = Attacker\n' > "$hostile_global_config"
GIT_CONFIG_GLOBAL="$hostile_global_config" \
  GIT_CONFIG_COUNT=1 \
  GIT_CONFIG_KEY_0=user.name \
  GIT_CONFIG_VALUE_0='Command Scope Attacker' \
  assert_fixture_git_setting user.name 'Dotfiles Test' "$fixture_local_config" 'fixture Git user name under hostile ambient config' || exit 1

printf 'PASS: ignore policy\n'
