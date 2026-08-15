#!/usr/bin/env bash

local_path_exists() {
  [[ -e $1 || -L $1 ]]
}

report_legacy_local_pair() {
  local label=$1
  local legacy_path=$2
  local active_path=$3

  local_path_exists "$legacy_path" || return 1

  if local_path_exists "$active_path"; then
    printf 'Legacy machine-local %s still exists: %q\n' "$label" "$legacy_path"
    printf 'Active XDG path also exists: %q\n' "$active_path"
    printf 'Compare both files, then remove the legacy path manually; no automatic migration was attempted.\n'
  else
    printf 'Legacy machine-local %s is no longer loaded: %q\n' "$label" "$legacy_path"
    printf 'Move it to the active XDG path:\n'
    printf '  /bin/mv -- %q %q\n' "$legacy_path" "$active_path"
  fi
  return 0
}

report_legacy_local_migrations() {
  local work_tree=$1
  local found=0

  report_legacy_local_pair 'Git config' "$work_tree/.gitconfig.local" \
    "$work_tree/.config/git/config.local" && found=1
  report_legacy_local_pair 'Zsh config' "$work_tree/.zshrc.local" \
    "$work_tree/.config/zsh/.zshrc.local" && found=1
  [[ $found -eq 0 ]]
}
