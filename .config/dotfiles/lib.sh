#!/usr/bin/env bash

PASS_COUNT=0
WARN_COUNT=0
FAIL_COUNT=0

pass() {
  PASS_COUNT=$((PASS_COUNT + 1))
  printf 'PASS: %s\n' "$*"
}

warn() {
  WARN_COUNT=$((WARN_COUNT + 1))
  printf 'WARN: %s\n' "$*"
}

fail_check() {
  FAIL_COUNT=$((FAIL_COUNT + 1))
  printf 'FAIL: %s\n' "$*"
}

have() {
  command -v "$1" >/dev/null 2>&1
}

dotgit() (
  unset GIT_CONFIG GIT_CONFIG_GLOBAL GIT_CONFIG_SYSTEM GIT_CONFIG_PARAMETERS GIT_CONFIG_COUNT
  unset GIT_DIR GIT_WORK_TREE GIT_COMMON_DIR GIT_INDEX_FILE
  unset GIT_OBJECT_DIRECTORY GIT_ALTERNATE_OBJECT_DIRECTORIES
  export GIT_CONFIG_NOSYSTEM=1
  export GIT_OPTIONAL_LOCKS=0
  /usr/bin/git \
    --git-dir="${DOTFILES_GIT_DIR:-$HOME/.cfg}" \
    --work-tree="${DOTFILES_WORK_TREE:-$HOME}" \
    "$@"
)

expand_home_path() {
  local value=$1

  case $value in
    '~/'*) printf '%s/%s\n' "$HOME" "${value#\~/}" ;;
    *) printf '%s\n' "$value" ;;
  esac
}

summary() {
  printf 'Summary: %s PASS, %s WARN, %s FAIL\n' "$PASS_COUNT" "$WARN_COUNT" "$FAIL_COUNT"
  [[ $FAIL_COUNT -eq 0 ]]
}
