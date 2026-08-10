#!/bin/bash
set -euo pipefail

script_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
# shellcheck source=test_helpers.sh
source "$script_dir/test_helpers.sh"

work_tree=$(/usr/bin/git -C "$script_dir" rev-parse --show-toplevel)
bootstrap="$work_tree/.config/dotfiles/bootstrap"

make_test_root
trap cleanup_test_root EXIT
/bin/mkdir -p "$TEST_ROOT/git-home" "$TEST_ROOT/git-tmp"

fixture_git() {
  /usr/bin/env -i \
    HOME="$TEST_ROOT/git-home" \
    PATH=/usr/bin:/bin \
    LC_ALL=C \
    TMPDIR="$TEST_ROOT/git-tmp" \
    GIT_CONFIG_NOSYSTEM=1 \
    GIT_CONFIG_GLOBAL=/dev/null \
    /usr/bin/git -c core.hooksPath=/dev/null "$@"
}

assert_absent() {
  [[ ! -e $1 && ! -L $1 ]] || fail "expected path to be absent [$1]"
}

assert_file_mode() {
  local expected=$1
  local path=$2
  local actual
  actual=$(/usr/bin/stat -f '%Lp' "$path")
  assert_eq "$expected" "$actual" "mode for $path"
}

snapshot_tree() {
  local root=$1
  (
    cd "$root"
    /usr/bin/find . -print0 | LC_ALL=C /usr/bin/sort -z | while IFS= read -r -d '' path; do
      if [[ -L $path ]]; then
        printf 'L %q %q\n' "$path" "$(/usr/bin/readlink "$path")"
      elif [[ -f $path ]]; then
        printf 'F %q %s ' "$path" "$(/usr/bin/stat -f '%Lp' "$path")"
        /usr/bin/shasum -a 256 "$path"
      elif [[ -d $path ]]; then
        printf 'D %q %s\n' "$path" "$(/usr/bin/stat -f '%Lp' "$path")"
      fi
    done
  )
}

make_remote() {
  local name=$1
  local source="$TEST_ROOT/$name-source"
  local remote="$TEST_ROOT/$name-remote.git"

  /bin/mkdir -p "$source/.config/dotfiles/templates"
  fixture_git init -q -b main "$source"
  fixture_git -C "$source" config user.name 'Bootstrap Test'
  fixture_git -C "$source" config user.email 'bootstrap@example.invalid'
  fixture_git -C "$source" config commit.gpgSign false
  printf 'tracked payload\n' > "$source/tracked.txt"
  printf '#!/bin/bash\nprintf "fixture check from %%s\\n" "$0"\n' > "$source/.config/dotfiles/check"
  /bin/chmod +x "$source/.config/dotfiles/check"
  printf '[user]\n  name = Example Only\n' > "$source/.config/dotfiles/templates/gitconfig.local.example"
  printf 'example@example.invalid ssh-ed25519 INVALID\n' > "$source/.config/dotfiles/templates/allowed_signers.local.example"
  printf '# example only\n' > "$source/.config/dotfiles/templates/zshrc.local.example"
  fixture_git -C "$source" add .
  fixture_git -C "$source" commit -qm fixture
  fixture_git clone --bare -q "$source" "$remote"
  REMOTE=$remote
  SOURCE=$source
}

run_bootstrap() {
  local home=$1
  local remote=$2
  shift 2
  local output="$home.bootstrap-output"
  local status

  set +e
  /usr/bin/env -i \
    HOME="$home" \
    PATH=/usr/bin:/bin \
    LC_ALL=C \
    DOTFILES_REMOTE="$remote" \
    DOTFILES_GIT_DIR="$home/.cfg" \
    DOTFILES_WORK_TREE="$home" \
    XDG_STATE_HOME="$home/.state" \
    DOTFILES_SKIP_PLATFORM_CHECK=1 \
    "$bootstrap" "$@" > "$output" 2>&1
  status=$?
  set -e
  BOOTSTRAP_STATUS=$status
  BOOTSTRAP_OUTPUT=$(/bin/cat "$output")
}

make_remote clean
clean_home="$TEST_ROOT/clean-home"
/bin/mkdir "$clean_home"
run_bootstrap "$clean_home" "$REMOTE" --yes
assert_eq 0 "$BOOTSTRAP_STATUS" 'clean bootstrap succeeds'
assert_eq 'tracked payload' "$(<"$clean_home/tracked.txt")" 'tracked payload placed'
assert_eq true "$(/usr/bin/git --git-dir="$clean_home/.cfg" config --bool core.bare)" 'repository is bare'
assert_eq no "$(/usr/bin/git --git-dir="$clean_home/.cfg" config status.showUntrackedFiles)" 'untracked status setting'
assert_eq '+refs/heads/*:refs/remotes/origin/*' "$(/usr/bin/git --git-dir="$clean_home/.cfg" config --get-all remote.origin.fetch)" 'fetch refspec'
assert_contains 'platform check skipped by explicit test override' "$BOOTSTRAP_OUTPUT" 'test-only platform warning'
assert_absent "$clean_home/.gitconfig.local"
assert_absent "$clean_home/.config/git/allowed_signers.local"
assert_absent "$clean_home/.zshrc.local"
assert_contains '.gitconfig.local' "$BOOTSTRAP_OUTPUT" 'git identity copy instruction'
assert_contains 'allowed_signers.local' "$BOOTSTRAP_OUTPUT" 'allowed signers copy instruction'
assert_contains '.zshrc.local' "$BOOTSTRAP_OUTPUT" 'zsh copy instruction'
[[ $BOOTSTRAP_OUTPUT != *brew* ]] || fail 'bootstrap must not install programs'

identity_home="$TEST_ROOT/identity-home"
/bin/mkdir "$identity_home"
printf '[user]\n  name = Local Fixture\n' > "$identity_home/.gitconfig.local"
run_bootstrap "$identity_home" "$REMOTE" --yes
assert_eq 0 "$BOOTSTRAP_STATUS" 'bootstrap with local identity succeeds'
assert_contains "fixture check from $identity_home/.config/dotfiles/check" "$BOOTSTRAP_OUTPUT" \
  'check runs from the checked-out fixture, not the real home'

make_remote conflicts
printf 'upstream executable\n' > "$SOURCE/bin tool"
/bin/chmod +x "$SOURCE/bin tool"
/bin/ln -s 'upstream target' "$SOURCE/link item"
/bin/ln -s $'upstream trailing\n' "$SOURCE/trailing link"
/bin/mkdir -p "$SOURCE/odd[chars]"
odd_name="dollar\$quote's"
printf 'odd\n' > "$SOURCE/odd[chars]/$odd_name"
fixture_git -C "$SOURCE" add .
fixture_git -C "$SOURCE" commit -qm conflicts
fixture_git --git-dir="$REMOTE" fetch -q "$SOURCE" main:main

dry_home="$TEST_ROOT/dry-home"
/bin/mkdir "$dry_home"
printf 'local executable bytes\n' > "$dry_home/bin tool"
/bin/chmod 700 "$dry_home/bin tool"
/bin/ln -s 'local target' "$dry_home/link item"
/bin/ln -s 'upstream trailing' "$dry_home/trailing link"
dry_before=$(snapshot_tree "$dry_home")
run_bootstrap "$dry_home" "$REMOTE" --dry-run
assert_eq 0 "$BOOTSTRAP_STATUS" 'dry-run succeeds'
assert_contains 'bin\ tool' "$BOOTSTRAP_OUTPUT" 'dry-run lists shell-escaped spaced conflict'
assert_contains 'link\ item' "$BOOTSTRAP_OUTPUT" 'dry-run lists shell-escaped symlink conflict'
assert_contains '/backups/' "$BOOTSTRAP_OUTPUT" 'dry-run prints backup destination'
assert_eq "$dry_before" "$(snapshot_tree "$dry_home")" 'dry-run leaves byte/ref/file-list snapshot unchanged'
assert_absent "$dry_home/.cfg"

yes_home="$TEST_ROOT/yes-home"
/bin/mkdir "$yes_home"
printf 'local executable bytes\n' > "$yes_home/bin tool"
/bin/chmod 700 "$yes_home/bin tool"
/bin/ln -s 'local target' "$yes_home/link item"
/bin/ln -s 'upstream trailing' "$yes_home/trailing link"
run_bootstrap "$yes_home" "$REMOTE" --yes
assert_eq 0 "$BOOTSTRAP_STATUS" 'approved conflict bootstrap succeeds'
backup=$(/usr/bin/find "$yes_home/.state/dotfiles/backups" -mindepth 1 -maxdepth 1 -type d | /usr/bin/head -1)
assert_eq 'local executable bytes' "$(<"$backup/bin tool")" 'backup preserves bytes'
assert_file_mode 700 "$backup/bin tool"
assert_eq 'local target' "$(/usr/bin/readlink "$backup/link item")" 'backup preserves symlink target'
[[ -L $backup/trailing\ link ]] || fail 'trailing-newline symlink mismatch must be backed up'
assert_eq 'upstream executable' "$(<"$yes_home/bin tool")" 'checkout replaces conflict'
assert_file_mode 755 "$yes_home/bin tool"
assert_eq 'upstream target' "$(/usr/bin/readlink "$yes_home/link item")" 'checkout places upstream symlink'
assert_eq odd "$(<"$yes_home/odd[chars]/$odd_name")" 'safe unusual path checkout'
backup_count=$(/usr/bin/find "$yes_home/.state/dotfiles/backups" -mindepth 1 -maxdepth 1 -type d | /usr/bin/wc -l | /usr/bin/tr -d ' ')
yes_before=$(snapshot_tree "$yes_home")
run_bootstrap "$yes_home" "$REMOTE" --yes
assert_eq 0 "$BOOTSTRAP_STATUS" 'idempotent rerun succeeds'
assert_eq "$backup_count" "$(/usr/bin/find "$yes_home/.state/dotfiles/backups" -mindepth 1 -maxdepth 1 -type d | /usr/bin/wc -l | /usr/bin/tr -d ' ')" 'rerun creates no backup'
assert_eq "$yes_before" "$(snapshot_tree "$yes_home")" 'rerun causes no worktree churn'

identical_home="$TEST_ROOT/identical-home"
/bin/mkdir "$identical_home"
/bin/cp "$SOURCE/tracked.txt" "$identical_home/tracked.txt"
run_bootstrap "$identical_home" "$REMOTE" --yes
assert_eq 0 "$BOOTSTRAP_STATUS" "identical destination bootstrap succeeds: $BOOTSTRAP_OUTPUT"
assert_absent "$identical_home/.state/dotfiles/backups"

make_remote newline
newline_name=$'line\nbreak'
printf 'newline\n' > "$SOURCE/$newline_name"
fixture_git -C "$SOURCE" add .
fixture_git -C "$SOURCE" commit -qm newline
fixture_git --git-dir="$REMOTE" fetch -q "$SOURCE" main:main
newline_home="$TEST_ROOT/newline-home"
/bin/mkdir "$newline_home"
run_bootstrap "$newline_home" "$REMOTE" --dry-run
[[ $BOOTSTRAP_STATUS -ne 0 ]] || fail 'newline path must fail closed'
assert_contains 'newline path' "$BOOTSTRAP_OUTPUT" 'newline rejection is documented'
assert_absent "$newline_home/.cfg"

escape_home="$TEST_ROOT/escape-home"
escape_target="$TEST_ROOT/escape-target"
/bin/mkdir "$escape_home" "$escape_target"
/bin/ln -s "$escape_target" "$escape_home/.state"
run_bootstrap "$escape_home" "$REMOTE" --dry-run
[[ $BOOTSTRAP_STATUS -ne 0 ]] || fail 'backup-root symlink escape must fail'
assert_absent "$escape_home/.cfg"
assert_eq '' "$(/usr/bin/find "$escape_target" -mindepth 1 -print -quit)" 'symlink escape target unchanged'

reject_home="$TEST_ROOT/reject-home"
/bin/mkdir "$reject_home"
fixture_git clone --bare -q "$REMOTE" "$reject_home/.cfg"
fixture_git --git-dir="$reject_home/.cfg" remote set-url origin "$TEST_ROOT/wrong.git"
reject_before=$(snapshot_tree "$reject_home")
run_bootstrap "$reject_home" "$REMOTE" --yes
[[ $BOOTSTRAP_STATUS -ne 0 ]] || fail 'mismatched origin must fail'
assert_contains 'origin' "$BOOTSTRAP_OUTPUT" 'mismatched origin error'
assert_eq "$reject_before" "$(snapshot_tree "$reject_home")" 'mismatched origin leaves state unchanged'

nonbare_home="$TEST_ROOT/nonbare-home"
/bin/mkdir "$nonbare_home"
fixture_git init -q "$nonbare_home/.cfg"
run_bootstrap "$nonbare_home" "$REMOTE" --yes
[[ $BOOTSTRAP_STATUS -ne 0 ]] || fail 'non-bare repository must fail'

decline_home="$TEST_ROOT/decline-home"
/bin/mkdir "$decline_home"
printf 'decline bytes\n' > "$decline_home/tracked.txt"
decline_before=$(snapshot_tree "$decline_home")
set +e
printf 'n\n' | /usr/bin/env -i HOME="$decline_home" PATH=/usr/bin:/bin LC_ALL=C DOTFILES_REMOTE="$REMOTE" DOTFILES_GIT_DIR="$decline_home/.cfg" DOTFILES_WORK_TREE="$decline_home" XDG_STATE_HOME="$decline_home/.state" DOTFILES_SKIP_PLATFORM_CHECK=1 "$bootstrap" > "$decline_home.output" 2>&1
decline_status=$?
set -e
[[ $decline_status -ne 0 ]] || fail 'declined prompt must not succeed'
assert_eq "$decline_before" "$(snapshot_tree "$decline_home")" 'decline leaves no changes'

make_remote checkout-failure
printf 'replacement\n' > "$SOURCE/conflict.txt"
/bin/mkdir "$SOURCE/locked"
printf 'cannot place\n' > "$SOURCE/locked/new.txt"
fixture_git -C "$SOURCE" add .
fixture_git -C "$SOURCE" commit -qm 'checkout failure fixture'
fixture_git --git-dir="$REMOTE" fetch -q "$SOURCE" main:main
failure_home="$TEST_ROOT/failure-home"
/bin/mkdir -p "$failure_home/locked"
printf 'keep me\n' > "$failure_home/conflict.txt"
/bin/chmod 500 "$failure_home/locked"
run_bootstrap "$failure_home" "$REMOTE" --yes
/bin/chmod 700 "$failure_home/locked"
[[ $BOOTSTRAP_STATUS -ne 0 ]] || fail 'checkout failure fixture must fail'
failure_backup=$(/usr/bin/find "$failure_home/.state/dotfiles/backups" -mindepth 1 -maxdepth 1 -type d | /usr/bin/head -1)
assert_eq 'keep me' "$(<"$failure_backup/conflict.txt")" 'failed checkout retains backup'
assert_contains "$failure_backup" "$BOOTSTRAP_OUTPUT" 'failed checkout prints backup path'
assert_contains 'mv --' "$BOOTSTRAP_OUTPUT" 'failed checkout prints restoration command'

hostile_home="$TEST_ROOT/hostile-home"
/bin/mkdir -p "$hostile_home/hostile-bin" "$hostile_home/hostile-tmp;touch PWNED"
printf '[core]\n  hooksPath = %s\n[alias]\n  clone = !touch %s\n' "$hostile_home/hooks" "$hostile_home/ambient-pwned" > "$hostile_home/.gitconfig"
/bin/mkdir "$hostile_home/hooks"
printf '#!/bin/bash\ntouch %q\n' "$hostile_home/hook-pwned" > "$hostile_home/hooks/post-checkout"
/bin/chmod +x "$hostile_home/hooks/post-checkout"
printf '#!/bin/bash\ntouch %q\nexit 99\n' "$hostile_home/path-pwned" > "$hostile_home/hostile-bin/git"
/bin/chmod +x "$hostile_home/hostile-bin/git"
set +e
/usr/bin/env -i HOME="$hostile_home" PATH="$hostile_home/hostile-bin:/usr/bin:/bin" LC_ALL=C TMPDIR="$hostile_home/hostile-tmp;touch PWNED" DOTFILES_REMOTE="$REMOTE" DOTFILES_GIT_DIR="$hostile_home/.cfg" DOTFILES_WORK_TREE="$hostile_home" XDG_STATE_HOME="$hostile_home/.state" DOTFILES_SKIP_PLATFORM_CHECK=1 "$bootstrap" --yes > "$hostile_home.output" 2>&1
hostile_status=$?
set -e
assert_eq 0 "$hostile_status" 'hostile ambient environment is ignored'
assert_absent "$hostile_home/path-pwned"
assert_absent "$hostile_home/hook-pwned"
assert_absent "$hostile_home/ambient-pwned"
assert_absent "$hostile_home/PWNED"

signal_home="$TEST_ROOT/signal-home"
/bin/mkdir "$signal_home"
printf 'conflict\n' > "$signal_home/tracked.txt"
set +e
( printf ''; /bin/sleep 10 ) | /usr/bin/env -i HOME="$signal_home" PATH=/usr/bin:/bin LC_ALL=C DOTFILES_REMOTE="$REMOTE" DOTFILES_GIT_DIR="$signal_home/.cfg" DOTFILES_WORK_TREE="$signal_home" XDG_STATE_HOME="$signal_home/.state" DOTFILES_SKIP_PLATFORM_CHECK=1 "$bootstrap" > "$signal_home.output" 2>&1 &
signal_pid=$!
/bin/sleep 1
/bin/kill -TERM "$signal_pid" 2>/dev/null
wait "$signal_pid" 2>/dev/null
set -e
assert_absent "$signal_home/.cfg"
[[ -z $(/usr/bin/find "$signal_home" -maxdepth 1 -name '.cfg.bootstrap.*' -print -quit) ]] || fail 'signal cleans candidate'

set +e
"$bootstrap" --yes --dry-run > "$TEST_ROOT/invalid.output" 2>&1
invalid_status=$?
set -e
[[ $invalid_status -ne 0 ]] || fail 'combined options must be rejected'

printf 'PASS: bootstrap is conflict-safe, non-destructive, hostile-environment resistant, and idempotent\n'
