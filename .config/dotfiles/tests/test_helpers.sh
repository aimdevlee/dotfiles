#!/usr/bin/env bash

fail() {
  printf 'FAIL: %s\n' "$*" >&2
  return 1
}

assert_eq() {
  local expected=$1
  local actual=$2
  local message=${3:-expected values to match}

  [[ $expected == "$actual" ]] || fail "$message: expected [$expected], got [$actual]"
}

assert_contains() {
  local needle=$1
  local haystack=$2
  local message=${3:-expected value to contain substring}

  [[ $haystack == *"$needle"* ]] || fail "$message: missing [$needle] in [$haystack]"
}

setup_dotfiles_test_context() {
  local script_dir=$1
  local derived_work_tree
  local derived_repo_dir

  if [[ -z ${DOTFILES_GIT_DIR:-} || -z ${DOTFILES_WORK_TREE:-} ]]; then
    derived_work_tree=$(git -C "$script_dir" rev-parse --show-toplevel 2>/dev/null || true)
    if [[ -n $derived_work_tree ]]; then
      derived_repo_dir=$(git -C "$derived_work_tree" rev-parse --absolute-git-dir)
    else
      derived_work_tree=$HOME
      derived_repo_dir=$HOME/.cfg
    fi

    : "${DOTFILES_WORK_TREE:=$derived_work_tree}"
    : "${DOTFILES_GIT_DIR:=$derived_repo_dir}"
    export DOTFILES_GIT_DIR DOTFILES_WORK_TREE
  fi
}

assert_ignored_by_worktree_policy() {
  local repo_dir=$1
  local work_tree=$2
  local path=$3
  local ignored
  local source
  local matched_path

  if ! ignored=$(git -c core.excludesFile=/dev/null -C "$work_tree" --git-dir="$repo_dir" --work-tree="$work_tree" check-ignore -v -- "$path"); then
    fail "expected [$path] to be ignored"
    return 1
  fi
  source=${ignored%%$'\t'*}
  matched_path=${ignored#*$'\t'}
  assert_eq "$path" "$matched_path" "git check-ignore output" || return 1
  [[ $source == .gitignore:* ]] || fail "expected [$path] to match the worktree .gitignore, got [$source]"
}

make_test_root() {
  local temp_base

  temp_base=$(cd -P -- "${TMPDIR:-/tmp}" && pwd)

  TEST_ROOT=$(mktemp -d "$temp_base/dotfiles-test.XXXXXXXX")
  : > "$TEST_ROOT/.dotfiles-test-root"
  export TEST_ROOT
}

cleanup_test_root() {
  local temp_base
  local root=${TEST_ROOT:-}
  local root_name

  temp_base=$(cd -P -- "${TMPDIR:-/tmp}" && pwd)

  [[ -n $root && -d $root && -f $root/.dotfiles-test-root ]] || return 0
  root_name=${root##*/}
  if [[ $root != "$temp_base/$root_name" || $root_name != dotfiles-test.* ]]; then
    fail "refusing to remove unvalidated test root [$root]"
    return 1
  fi

  rm -rf -- "$root"
}

init_fixture_repo() {
  local source_repo="$TEST_ROOT/source"

  git init -q "$source_repo"
  git -C "$source_repo" config user.name 'Dotfiles Test'
  git -C "$source_repo" config user.email 'dotfiles-test@example.invalid'
  git -C "$source_repo" config commit.gpgSign false
  : > "$source_repo/.fixture"
  git -C "$source_repo" add .fixture
  git -C "$source_repo" commit -qm 'fixture'
  git clone --bare -q "$source_repo" "$TEST_ROOT/remote.git"
}
