#!/usr/bin/env bash
set -euo pipefail

script_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
source "$script_dir/test_helpers.sh"

expected_work_tree=$(git -C "$script_dir" rev-parse --show-toplevel)
expected_repo_dir=$(git -C "$expected_work_tree" rev-parse --absolute-git-dir)

canonical_path() {
  (cd -P -- "$1" && pwd)
}

assert_auto_runner_context() {
  local actual_work_tree=$1
  local actual_repo_dir=$2

  [[ -n $actual_work_tree && -n $actual_repo_dir ]] || fail 'runner context is unset'
  assert_eq "$(canonical_path "$expected_work_tree")" "$(canonical_path "$actual_work_tree")" 'runner work tree' || return 1
  actual_repo_dir=$(git -C "$actual_work_tree" --git-dir="$actual_repo_dir" --work-tree="$actual_work_tree" rev-parse --absolute-git-dir) || return 1
  assert_eq "$(canonical_path "$expected_repo_dir")" "$(canonical_path "$actual_repo_dir")" 'runner git dir'
}

assert_explicit_runner_context() {
  local supplied_work_tree=$1
  local supplied_repo_dir=$2
  local derived_work_tree
  local derived_repo_dir
  local resolved_repo_dir

  [[ -n $supplied_work_tree && -n $supplied_repo_dir ]] || fail 'explicit runner context is unset'
  derived_work_tree=$(git -C "$supplied_work_tree" rev-parse --show-toplevel) || return 1
  assert_eq "$(canonical_path "$derived_work_tree")" "$(canonical_path "$supplied_work_tree")" 'explicit runner work tree' || return 1
  derived_repo_dir=$(git -C "$derived_work_tree" rev-parse --absolute-git-dir) || return 1
  resolved_repo_dir=$(git -C "$supplied_work_tree" --git-dir="$supplied_repo_dir" --work-tree="$supplied_work_tree" rev-parse --absolute-git-dir) || return 1
  assert_eq "$(canonical_path "$derived_repo_dir")" "$(canonical_path "$resolved_repo_dir")" 'explicit runner git dir'
}

case ${DOTFILES_TEST_CONTEXT_MODE:-} in
  auto) assert_auto_runner_context "$DOTFILES_WORK_TREE" "$DOTFILES_GIT_DIR" ;;
  explicit) assert_explicit_runner_context "$DOTFILES_WORK_TREE" "$DOTFILES_GIT_DIR" ;;
  *) fail 'runner context mode is unset or invalid' ;;
esac

if assert_auto_runner_context "$expected_work_tree" "$expected_work_tree" 2>/dev/null; then
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
explicit_clone="$TEST_ROOT/explicit-clone"
init_fixture_repo
git clone -q "$TEST_ROOT/remote.git" "$explicit_clone"
assert_explicit_runner_context "$explicit_clone" "$explicit_clone/.git"
if assert_explicit_runner_context "$explicit_clone" "$expected_repo_dir" 2>/dev/null; then
  fail 'explicit runner context accepted a mismatched git directory'
fi
cleanup_test_root

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

copy_zsh_startup_fixture() {
  local fixture_home=$1
  local missing_brew=$2

  mkdir -p "$fixture_home/.config/zsh" "$fixture_home/.cache" "$fixture_home/.local/share" "$fixture_home/.local/state"
  cp "$expected_work_tree/.zshenv" "$fixture_home/.zshenv"
  sed "s|/opt/homebrew/bin/brew|$missing_brew|g" \
    "$expected_work_tree/.config/zsh/.zprofile" > "$fixture_home/.config/zsh/.zprofile"
  cp "$expected_work_tree/.config/zsh/.zshrc" "$fixture_home/.config/zsh/.zshrc"
}

run_isolated_zsh_startup() {
  local fixture_home=$1
  local stdout_file=$2
  local stderr_file=$3
  local command=$4

  env -i \
    HOME="$fixture_home" \
    PATH=/usr/bin:/bin \
    /bin/zsh -lic "$command" >"$stdout_file" 2>"$stderr_file"
}

make_test_root
zsh_home="$TEST_ROOT/home"
zsh_stdout="$TEST_ROOT/zsh.stdout"
zsh_stderr="$TEST_ROOT/zsh.stderr"
missing_brew="$TEST_ROOT/no-optional-tools/brew"
copy_zsh_startup_fixture "$zsh_home" "$missing_brew"

if ! run_isolated_zsh_startup "$zsh_home" "$zsh_stdout" "$zsh_stderr" 'print shell-loaded'; then
  fail "isolated zsh startup failed: $(cat "$zsh_stderr")"
fi
assert_eq 'shell-loaded' "$(cat "$zsh_stdout")" 'isolated zsh startup marker'
assert_eq '' "$(cat "$zsh_stderr")" 'isolated zsh startup stderr'

printf 'export DOTFILES_LOCAL_LOADED=yes\n' > "$zsh_home/.zshrc.local"
if ! run_isolated_zsh_startup "$zsh_home" "$zsh_stdout" "$zsh_stderr" 'print "$DOTFILES_LOCAL_LOADED"'; then
  fail "isolated local override startup failed: $(cat "$zsh_stderr")"
fi
assert_eq yes "$(cat "$zsh_stdout")" 'local zsh override'
assert_eq '' "$(cat "$zsh_stderr")" 'local zsh override stderr'
cleanup_test_root

expected_local_template='# Machine-local project roots and private tool initialization.
TS_SEARCH_PATHS=("$HOME/Developer:1")

# Keep secrets out of this example and out of the dotfiles repository.
# source "$HOME/.config/company/shell.zsh"'
assert_eq "$expected_local_template" "$(cat "$expected_work_tree/.config/dotfiles/templates/zshrc.local.example")" 'local zsh template'

printf 'PASS: shell helpers\n'
