#!/usr/bin/env bash
set -euo pipefail

script_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
source "$script_dir/test_helpers.sh"

expected_work_tree=$(git -C "$script_dir" rev-parse --show-toplevel)
expected_repo_dir=$(git -C "$expected_work_tree" rev-parse --absolute-git-dir)

canonical_path() {
  (cd -P -- "$1" && pwd)
}

assert_runner_context() {
  local actual_work_tree=$1
  local actual_repo_dir=$2

  [[ -n $actual_work_tree && -n $actual_repo_dir ]] || fail 'runner context is unset'
  assert_eq "$(canonical_path "$expected_work_tree")" "$(canonical_path "$actual_work_tree")" 'runner work tree' || return 1
  assert_eq "$(canonical_path "$expected_repo_dir")" "$(canonical_path "$actual_repo_dir")" 'runner git dir'
}

assert_runner_context "$DOTFILES_WORK_TREE" "$DOTFILES_GIT_DIR"
if assert_runner_context "$expected_work_tree" "$expected_work_tree" 2>/dev/null; then
  fail 'runner context accepted an incorrect git directory'
fi

(
  DOTFILES_WORK_TREE=/explicit/work-tree
  DOTFILES_GIT_DIR=/explicit/git-dir
  setup_dotfiles_test_context "$script_dir"
  assert_eq /explicit/work-tree "$DOTFILES_WORK_TREE" 'explicit work tree override'
  assert_eq /explicit/git-dir "$DOTFILES_GIT_DIR" 'explicit git dir override'
)

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
  assert_ignored_by_worktree_policy "$ambient_work_tree/.git" "$ambient_work_tree" .ambient-secret >/dev/null 2>&1; then
  fail 'ignore_test accepted an ambient global exclude'
fi
cleanup_test_root

printf 'PASS: shell helpers\n'
