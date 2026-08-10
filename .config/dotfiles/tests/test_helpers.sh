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
