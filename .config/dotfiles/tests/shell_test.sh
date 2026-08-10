#!/usr/bin/env bash
set -euo pipefail

script_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
source "$script_dir/test_helpers.sh"

expected_work_tree=$(git -C "$script_dir" rev-parse --show-toplevel)
expected_repo_dir=$(git -C "$expected_work_tree" rev-parse --absolute-git-dir)
assert_eq "${DOTFILES_WORK_TREE:-$expected_work_tree}" "${DOTFILES_WORK_TREE:-}" 'runner work tree'
assert_eq "${DOTFILES_GIT_DIR:-$expected_repo_dir}" "${DOTFILES_GIT_DIR:-}" 'runner git dir'

temp_base=${TMPDIR:-/tmp}
anchor=$(mktemp -d "$temp_base/dotfiles-test.anchor.XXXXXXXX")
outside=$(mktemp -d "$temp_base/dotfiles-outside.XXXXXXXX")

cleanup() {
  rm -rf -- "$anchor" "$outside"
}
trap cleanup EXIT

: > "$outside/.dotfiles-test-root"
: > "$outside/sentinel"
TEST_ROOT="$anchor/../$(basename "$outside")"
export TEST_ROOT

if cleanup_test_root 2>/dev/null; then
  fail 'cleanup_test_root accepted a traversal path'
fi

[[ -f $outside/sentinel ]] || fail 'cleanup_test_root traversed outside its test root'

make_test_root
valid_root=$TEST_ROOT
cleanup_test_root
[[ ! -e $valid_root ]] || fail 'cleanup_test_root did not remove a valid test root'

make_test_root
ambient_work_tree="$TEST_ROOT/ambient-repo"
ambient_config="$TEST_ROOT/global.gitconfig"
ambient_excludes="$TEST_ROOT/global-excludes"
git init -q "$ambient_work_tree"
: > "$ambient_work_tree/.gitignore"
printf '.ambient-secret\n' > "$ambient_excludes"
git config -f "$ambient_config" core.excludesFile "$ambient_excludes"
if DOTFILES_GIT_DIR="$ambient_work_tree/.git" \
  DOTFILES_WORK_TREE="$ambient_work_tree" \
  GIT_CONFIG_GLOBAL="$ambient_config" \
  IGNORE_TEST_PATHS='.ambient-secret' \
  "$script_dir/ignore_test.sh" >/dev/null 2>&1; then
  fail 'ignore_test accepted an ambient global exclude'
fi
cleanup_test_root

printf 'PASS: shell helpers\n'
