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

assert_not_contains() {
  local needle=$1
  local haystack=$2
  local message=${3:-expected value not to contain substring}

  [[ $haystack != *"$needle"* ]] || fail "$message: unexpectedly found [$needle] in [$haystack]"
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
  printf '# sessionizer example only\n' > "$source/.config/dotfiles/templates/tmux-sessionizer.local.conf.example"
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
  run_bootstrap_with_paths "$home" "$remote" "$home/.cfg" "$home/.state" "$@"
}

run_bootstrap_with_paths() {
  local home=$1
  local remote=$2
  local git_dir=$3
  local state_home=$4
  shift 4
  local output="$home.bootstrap-output"
  local status

  set +e
  if [[ $state_home == DEFAULT ]]; then
    /usr/bin/env -i \
      HOME="$home" PATH=/usr/bin:/bin LC_ALL=C \
      DOTFILES_REMOTE="$remote" DOTFILES_GIT_DIR="$git_dir" DOTFILES_WORK_TREE="$home" \
      DOTFILES_SKIP_PLATFORM_CHECK=1 \
      "$bootstrap" "$@" > "$output" 2>&1
  else
    /usr/bin/env -i \
      HOME="$home" PATH=/usr/bin:/bin LC_ALL=C \
      DOTFILES_REMOTE="$remote" DOTFILES_GIT_DIR="$git_dir" DOTFILES_WORK_TREE="$home" \
      XDG_STATE_HOME="$state_home" DOTFILES_SKIP_PLATFORM_CHECK=1 \
      "$bootstrap" "$@" > "$output" 2>&1
  fi
  status=$?
  set -e
  BOOTSTRAP_STATUS=$status
  BOOTSTRAP_OUTPUT=$(/bin/cat "$output")
}

run_bootstrap_from_source() {
  local home=$1
  local remote=$2
  local source=$3
  shift 3
  local output="$home.bootstrap-output"
  local status

  set +e
  /usr/bin/env -i \
    HOME="$home" PATH=/usr/bin:/bin LC_ALL=C \
    DOTFILES_REMOTE="$remote" DOTFILES_SOURCE="$source" DOTFILES_GIT_DIR="$home/.cfg" DOTFILES_WORK_TREE="$home" \
    XDG_STATE_HOME="$home/.state" DOTFILES_SKIP_PLATFORM_CHECK=1 \
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
assert_absent "$clean_home/.config/tmux-sessionizer/tmux-sessionizer.local.conf"
assert_contains '.gitconfig.local' "$BOOTSTRAP_OUTPUT" 'git identity copy instruction'
assert_contains 'allowed_signers.local' "$BOOTSTRAP_OUTPUT" 'allowed signers copy instruction'
assert_contains '.zshrc.local' "$BOOTSTRAP_OUTPUT" 'zsh copy instruction'
assert_contains 'tmux-sessionizer.local.conf' "$BOOTSTRAP_OUTPUT" 'tmux-sessionizer local config copy instruction'
[[ $BOOTSTRAP_OUTPUT != *brew* ]] || fail 'bootstrap must not install programs'

make_remote reviewed-source
printf 'reviewed commit A\n' > "$SOURCE/reviewed.txt"
fixture_git -C "$SOURCE" add reviewed.txt
fixture_git -C "$SOURCE" commit -qm 'reviewed commit A'
fixture_git --git-dir="$REMOTE" fetch -q "$SOURCE" main:main
reviewed_clone="$TEST_ROOT/reviewed-normal-clone"
fixture_git clone -q "$REMOTE" "$reviewed_clone"
reviewed_head=$(fixture_git -C "$reviewed_clone" rev-parse HEAD)
printf 'remote advance B\n' > "$SOURCE/remote-advance.txt"
fixture_git -C "$SOURCE" add remote-advance.txt
fixture_git -C "$SOURCE" commit -qm 'remote advance B'
fixture_git --git-dir="$REMOTE" fetch -q "$SOURCE" main:main
remote_head=$(fixture_git --git-dir="$REMOTE" rev-parse refs/heads/main)
[[ $reviewed_head != "$remote_head" ]] || fail 'reviewed source and final remote must diverge for source pinning'
source_pinned_home="$TEST_ROOT/source-pinned-home"
/bin/mkdir "$source_pinned_home"
source_pinned_before=$(snapshot_tree "$source_pinned_home")
run_bootstrap_from_source "$source_pinned_home" "$REMOTE" "$reviewed_clone/.git" --dry-run
assert_eq 0 "$BOOTSTRAP_STATUS" "source-pinned dry-run succeeds: $BOOTSTRAP_OUTPUT"
assert_eq "$source_pinned_before" "$(snapshot_tree "$source_pinned_home")" 'source-pinned dry-run changes nothing'
assert_absent "$source_pinned_home/.cfg"
assert_not_contains remote-advance.txt "$BOOTSTRAP_OUTPUT" 'source-pinned dry-run does not inspect final remote advance'
run_bootstrap_from_source "$source_pinned_home" "$REMOTE" "$reviewed_clone/.git" --yes
assert_eq 0 "$BOOTSTRAP_STATUS" "source-pinned bootstrap succeeds: $BOOTSTRAP_OUTPUT"
assert_eq 'reviewed commit A' "$(<"$source_pinned_home/reviewed.txt")" 'source-pinned checkout uses reviewed commit'
assert_absent "$source_pinned_home/remote-advance.txt"
assert_eq "$reviewed_head" "$(fixture_git --git-dir="$source_pinned_home/.cfg" rev-parse HEAD)" 'dry-run and actual placement use the reviewed source HEAD'
assert_eq "$REMOTE" "$(fixture_git --git-dir="$source_pinned_home/.cfg" config --get remote.origin.url)" 'source-pinned installation resets origin to final remote'

invalid_source_home="$TEST_ROOT/invalid-source-home"
/bin/mkdir "$invalid_source_home"
invalid_source_before=$(snapshot_tree "$invalid_source_home")
run_bootstrap_from_source "$invalid_source_home" "$REMOTE" "$TEST_ROOT/missing-reviewed-source" --dry-run
[[ $BOOTSTRAP_STATUS -ne 0 ]] || fail 'missing DOTFILES_SOURCE must fail without falling back to the final remote'
assert_contains 'bare clone failed' "$BOOTSTRAP_OUTPUT" 'missing DOTFILES_SOURCE failure is clear'
assert_eq "$invalid_source_before" "$(snapshot_tree "$invalid_source_home")" 'invalid DOTFILES_SOURCE leaves worktree unchanged'
assert_absent "$invalid_source_home/.cfg"

identity_home="$TEST_ROOT/identity-home"
/bin/mkdir "$identity_home"
printf '[user]\n  name = Local Fixture\n' > "$identity_home/.gitconfig.local"
run_bootstrap "$identity_home" "$REMOTE" --yes
assert_eq 0 "$BOOTSTRAP_STATUS" 'bootstrap with local identity succeeds'
assert_contains "fixture check from $identity_home/.config/dotfiles/check" "$BOOTSTRAP_OUTPUT" \
  'check runs from the checked-out fixture, not the real home'
assert_absent "$identity_home/.config/git/allowed_signers.local"
assert_absent "$identity_home/.zshrc.local"
assert_absent "$identity_home/.config/tmux-sessionizer/tmux-sessionizer.local.conf"
assert_contains "/bin/cp -- $identity_home/.config/dotfiles/templates/allowed_signers.local.example $identity_home/.config/git/allowed_signers.local" \
  "$BOOTSTRAP_OUTPUT" 'missing allowed signers template hint with existing identity'
assert_contains "/bin/cp -- $identity_home/.config/dotfiles/templates/zshrc.local.example $identity_home/.zshrc.local" \
  "$BOOTSTRAP_OUTPUT" 'missing zsh template hint with existing identity'
assert_contains "/bin/cp -- $identity_home/.config/dotfiles/templates/tmux-sessionizer.local.conf.example $identity_home/.config/tmux-sessionizer/tmux-sessionizer.local.conf" \
  "$BOOTSTRAP_OUTPUT" 'missing tmux-sessionizer template hint with existing identity'

make_remote protected-git-dir
/bin/mkdir -p "$SOURCE/.cfg"
printf 'tracked repository collision\n' > "$SOURCE/.cfg/HEAD"
fixture_git -C "$SOURCE" add .
fixture_git -C "$SOURCE" commit -qm 'protected git directory path'
fixture_git --git-dir="$REMOTE" fetch -q "$SOURCE" main:main
protected_git_home="$TEST_ROOT/protected-git-home"
/bin/mkdir "$protected_git_home"
printf 'unchanged\n' > "$protected_git_home/sentinel"
protected_git_before=$(snapshot_tree "$protected_git_home")
run_bootstrap "$protected_git_home" "$REMOTE" --yes
[[ $BOOTSTRAP_STATUS -ne 0 ]] || fail 'tracked path beneath Git directory must be rejected'
assert_contains 'Git directory' "$BOOTSTRAP_OUTPUT" 'Git directory overlap rejection'
assert_absent "$protected_git_home/.cfg"
assert_eq "$protected_git_before" "$(snapshot_tree "$protected_git_home")" 'Git directory overlap leaves worktree unchanged'
assert_absent "$protected_git_home/.state/dotfiles/backups"

make_remote protected-spaced-git-dir
/bin/mkdir -p "$SOURCE/.config/dotfiles repo.git"
printf 'tracked spaced repository collision\n' > "$SOURCE/.config/dotfiles repo.git/HEAD"
fixture_git -C "$SOURCE" add .
fixture_git -C "$SOURCE" commit -qm 'protected spaced git directory path'
fixture_git --git-dir="$REMOTE" fetch -q "$SOURCE" main:main
spaced_git_home="$TEST_ROOT/spaced-git-home"
/bin/mkdir -p "$spaced_git_home/.config"
spaced_git_before=$(snapshot_tree "$spaced_git_home")
run_bootstrap_with_paths "$spaced_git_home" "$REMOTE" "$spaced_git_home/.config/dotfiles repo.git" "$spaced_git_home/.state" --yes
[[ $BOOTSTRAP_STATUS -ne 0 ]] || fail 'tracked path beneath spaced Git directory must be rejected'
assert_contains 'Git directory' "$BOOTSTRAP_OUTPUT" 'spaced Git directory overlap rejection'
assert_absent "$spaced_git_home/.config/dotfiles repo.git"
assert_eq "$spaced_git_before" "$(snapshot_tree "$spaced_git_home")" 'spaced Git overlap leaves worktree unchanged'

make_remote protected-backup-root
/bin/mkdir -p "$SOURCE/.local/state/dotfiles/backups/retained"
printf 'must not overwrite recovery\n' > "$SOURCE/.local/state/dotfiles/backups/retained/data"
fixture_git -C "$SOURCE" add .
fixture_git -C "$SOURCE" commit -qm 'protected backup root path'
fixture_git --git-dir="$REMOTE" fetch -q "$SOURCE" main:main
protected_backup_home="$TEST_ROOT/protected-backup-home"
/bin/mkdir "$protected_backup_home"
printf 'unchanged\n' > "$protected_backup_home/sentinel"
protected_backup_before=$(snapshot_tree "$protected_backup_home")
run_bootstrap_with_paths "$protected_backup_home" "$REMOTE" "$protected_backup_home/.cfg" DEFAULT --yes
[[ $BOOTSTRAP_STATUS -ne 0 ]] || fail 'tracked path beneath backup root must be rejected'
assert_contains 'backup root' "$BOOTSTRAP_OUTPUT" 'backup root overlap rejection'
assert_absent "$protected_backup_home/.cfg"
assert_absent "$protected_backup_home/.local"
assert_eq "$protected_backup_before" "$(snapshot_tree "$protected_backup_home")" 'backup overlap leaves worktree unchanged'

make_remote protected-prefix-lookalike
/bin/mkdir -p "$SOURCE/.cfg2" "$SOURCE/.local/state/dotfiles/backups2"
printf 'allowed git prefix\n' > "$SOURCE/.cfg2/HEAD"
printf 'allowed backup prefix\n' > "$SOURCE/.local/state/dotfiles/backups2/data"
fixture_git -C "$SOURCE" add .
fixture_git -C "$SOURCE" commit -qm 'protected prefix lookalikes'
fixture_git --git-dir="$REMOTE" fetch -q "$SOURCE" main:main
lookalike_home="$TEST_ROOT/lookalike-home"
/bin/mkdir "$lookalike_home"
run_bootstrap_with_paths "$lookalike_home" "$REMOTE" "$lookalike_home/.cfg" DEFAULT --yes
assert_eq 0 "$BOOTSTRAP_STATUS" "protected prefix lookalikes remain allowed: $BOOTSTRAP_OUTPUT"
assert_eq 'allowed git prefix' "$(<"$lookalike_home/.cfg2/HEAD")" 'Git prefix lookalike checkout'
assert_eq 'allowed backup prefix' "$(<"$lookalike_home/.local/state/dotfiles/backups2/data")" 'backup prefix lookalike checkout'

make_remote protected-outside-roots
outside_home="$TEST_ROOT/outside-roots-home"
outside_git_parent="$TEST_ROOT/outside git parent"
outside_state="$TEST_ROOT/outside state"
/bin/mkdir "$outside_home" "$outside_git_parent" "$outside_state"
outside_home_before=$(snapshot_tree "$outside_home")
run_bootstrap_with_paths "$outside_home" "$REMOTE" "$outside_git_parent/.cfg with space" "$outside_state" --yes
[[ $BOOTSTRAP_STATUS -ne 0 ]] || fail 'protected roots outside worktree must fail closed'
assert_contains 'beneath the work tree' "$BOOTSTRAP_OUTPUT" 'outside protected root rejection'
assert_absent "$outside_git_parent/.cfg with space"
assert_eq '' "$(/usr/bin/find "$outside_state" -mindepth 1 -print -quit)" 'outside backup root unchanged'
assert_eq "$outside_home_before" "$(snapshot_tree "$outside_home")" 'outside-root rejection leaves worktree unchanged'

make_remote protected-root-ancestor
/bin/rm -rf "$SOURCE/.local"
printf 'tracked ancestor file\n' > "$SOURCE/.local"
printf 'remote conflict\n' > "$SOURCE/conflict.txt"
fixture_git -C "$SOURCE" add -A
fixture_git -C "$SOURCE" commit -qm 'protected root ancestor path'
fixture_git --git-dir="$REMOTE" fetch -q "$SOURCE" main:main
protected_ancestor_home="$TEST_ROOT/protected-ancestor-home"
/bin/mkdir "$protected_ancestor_home"
printf 'local ancestor bytes\n' > "$protected_ancestor_home/.local"
printf 'local conflict bytes\n' > "$protected_ancestor_home/conflict.txt"
protected_ancestor_before=$(snapshot_tree "$protected_ancestor_home")
run_bootstrap_with_paths "$protected_ancestor_home" "$REMOTE" "$protected_ancestor_home/.cfg" DEFAULT --yes
[[ $BOOTSTRAP_STATUS -ne 0 ]] || fail 'tracked file above backup root must be rejected'
assert_contains 'overlaps the protected backup root' "$BOOTSTRAP_OUTPUT" 'backup root ancestor overlap rejection'
assert_eq "$protected_ancestor_before" "$(snapshot_tree "$protected_ancestor_home")" 'protected ancestor rejection moves nothing'
assert_absent "$protected_ancestor_home/.cfg"
[[ -z $(/usr/bin/find "$protected_ancestor_home" -maxdepth 1 -name '.cfg.bootstrap.*' -print -quit) ]] || fail 'protected ancestor rejection cleans candidate'

make_remote ancestor-obstruction
/bin/mkdir -p "$SOURCE/nested"
printf 'first tracked descendant\n' > "$SOURCE/nested/first"
printf 'second tracked descendant\n' > "$SOURCE/nested/second"
fixture_git -C "$SOURCE" add .
fixture_git -C "$SOURCE" commit -qm 'ancestor obstruction paths'
fixture_git --git-dir="$REMOTE" fetch -q "$SOURCE" main:main
ancestor_file_home="$TEST_ROOT/ancestor-file-home"
/bin/mkdir "$ancestor_file_home"
printf 'original ancestor bytes\n' > "$ancestor_file_home/nested"
ancestor_file_before=$(snapshot_tree "$ancestor_file_home")
run_bootstrap "$ancestor_file_home" "$REMOTE" --dry-run
assert_eq 0 "$BOOTSTRAP_STATUS" 'ancestor file dry-run succeeds'
assert_contains '/nested -> ' "$BOOTSTRAP_OUTPUT" 'dry-run prints obstructing ancestor conflict'
assert_eq "$ancestor_file_before" "$(snapshot_tree "$ancestor_file_home")" 'ancestor dry-run changes nothing'
run_bootstrap "$ancestor_file_home" "$REMOTE" --yes
assert_eq 0 "$BOOTSTRAP_STATUS" "ancestor file conflict bootstrap succeeds: $BOOTSTRAP_OUTPUT"
ancestor_file_backup=$(/usr/bin/find "$ancestor_file_home/.state/dotfiles/backups" -mindepth 1 -maxdepth 1 -type d | /usr/bin/head -1)
assert_eq 'original ancestor bytes' "$(<"$ancestor_file_backup/nested")" 'ancestor file bytes retained once'
assert_eq 'first tracked descendant' "$(<"$ancestor_file_home/nested/first")" 'first descendant checked out'
assert_eq 'second tracked descendant' "$(<"$ancestor_file_home/nested/second")" 'second descendant checked out'
assert_eq 1 "$(/usr/bin/find "$ancestor_file_home/.state/dotfiles/backups" -mindepth 1 -maxdepth 1 -type d | /usr/bin/wc -l | /usr/bin/tr -d ' ')" 'one deduplicated ancestor backup'
run_bootstrap "$ancestor_file_home" "$REMOTE" --yes
assert_eq 0 "$BOOTSTRAP_STATUS" 'ancestor file rerun is idempotent'
assert_eq 1 "$(/usr/bin/find "$ancestor_file_home/.state/dotfiles/backups" -mindepth 1 -maxdepth 1 -type d | /usr/bin/wc -l | /usr/bin/tr -d ' ')" 'ancestor rerun creates no backup'

ancestor_link_home="$TEST_ROOT/ancestor-link-home"
ancestor_link_target="$TEST_ROOT/ancestor-link-target"
/bin/mkdir "$ancestor_link_home" "$ancestor_link_target"
printf 'outside target untouched\n' > "$ancestor_link_target/sentinel"
/bin/ln -s "$ancestor_link_target" "$ancestor_link_home/nested"
run_bootstrap "$ancestor_link_home" "$REMOTE" --yes
assert_eq 0 "$BOOTSTRAP_STATUS" "ancestor symlink conflict bootstrap succeeds: $BOOTSTRAP_OUTPUT"
ancestor_link_backup=$(/usr/bin/find "$ancestor_link_home/.state/dotfiles/backups" -mindepth 1 -maxdepth 1 -type d | /usr/bin/head -1)
[[ -L $ancestor_link_backup/nested ]] || fail 'ancestor symlink itself is retained in backup'
assert_eq "$ancestor_link_target" "$(/usr/bin/readlink "$ancestor_link_backup/nested")" 'ancestor symlink target retained'
assert_eq 'outside target untouched' "$(<"$ancestor_link_target/sentinel")" 'ancestor symlink target is not mutated'
assert_eq 'first tracked descendant' "$(<"$ancestor_link_home/nested/first")" 'symlink obstruction replaced by checked-out directory'

make_remote cooperative-lock
lock_home="$TEST_ROOT/lock-home"
/bin/mkdir "$lock_home" "$lock_home/.cfg.bootstrap.lock"
printf 'other process lock\n' > "$lock_home/.cfg.bootstrap.lock/owner"
lock_before=$(snapshot_tree "$lock_home")
run_bootstrap "$lock_home" "$REMOTE" --yes
[[ $BOOTSTRAP_STATUS -ne 0 ]] || fail 'existing cooperative lock must reject bootstrap'
assert_contains 'lock' "$BOOTSTRAP_OUTPUT" 'existing lock failure is clear'
assert_eq "$lock_before" "$(snapshot_tree "$lock_home")" 'existing lock is untouched'
assert_absent "$lock_home/.cfg"
[[ -z $(/usr/bin/find "$lock_home" -maxdepth 1 -name '.cfg.bootstrap.*' ! -name '.cfg.bootstrap.lock' -print -quit) ]] || fail 'locked bootstrap creates no candidate'
/bin/rm "$lock_home/.cfg.bootstrap.lock/owner"
/bin/rmdir "$lock_home/.cfg.bootstrap.lock"
run_bootstrap "$lock_home" "$REMOTE" --yes
assert_eq 0 "$BOOTSTRAP_STATUS" 'one bootstrap proceeds after lock owner releases'
assert_absent "$lock_home/.cfg.bootstrap.lock"

make_remote candidate-race
printf 'remote race bytes\n' > "$SOURCE/race-conflict"
fixture_git -C "$SOURCE" add .
fixture_git -C "$SOURCE" commit -qm 'candidate installation race fixture'
fixture_git --git-dir="$REMOTE" fetch -q "$SOURCE" main:main
race_home="$TEST_ROOT/race-home"
/bin/mkdir "$race_home"
printf 'local race bytes\n' > "$race_home/race-conflict"
set +e
( /bin/sleep 1; /bin/mkdir "$race_home/.cfg"; printf 'y\n' ) | \
  /usr/bin/env -i HOME="$race_home" PATH=/usr/bin:/bin LC_ALL=C \
    DOTFILES_REMOTE="$REMOTE" DOTFILES_GIT_DIR="$race_home/.cfg" DOTFILES_WORK_TREE="$race_home" \
    XDG_STATE_HOME="$race_home/.state" DOTFILES_SKIP_PLATFORM_CHECK=1 \
    "$bootstrap" > "$race_home.output" 2>&1
race_status=$?
set -e
[[ $race_status -ne 0 ]] || fail 'candidate destination race must fail closed'
assert_eq '' "$(/usr/bin/find "$race_home/.cfg" -mindepth 1 -print -quit)" 'candidate is never nested in raced Git directory'
[[ -z $(/usr/bin/find "$race_home" -maxdepth 1 -name '.cfg.bootstrap.*' -print -quit) ]] || fail 'candidate race cleans candidate and lock'
race_backup=$(/usr/bin/find "$race_home/.state/dotfiles/backups" -mindepth 1 -maxdepth 1 -type d | /usr/bin/head -1)
assert_eq 'local race bytes' "$(<"$race_backup/race-conflict")" 'candidate race retains moved conflict backup'
assert_contains "$race_backup" "$(/bin/cat "$race_home.output")" 'candidate race prints retained backup'

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
/bin/mkdir -p "$hostile_home/hostile-bin" "$hostile_home/hostile-tmp;touch PWNED" "$hostile_home/perl-lib"
printf '%s\n' 'BEGIN { open my $fh, ">", $ENV{DOTFILES_TEST_PERL_MARKER}; }' '1;' > "$hostile_home/perl-lib/Hostile.pm"
printf '[core]\n  hooksPath = %s\n[alias]\n  clone = !touch %s\n' "$hostile_home/hooks" "$hostile_home/ambient-pwned" > "$hostile_home/.gitconfig"
/bin/mkdir "$hostile_home/hooks"
printf '#!/bin/bash\ntouch %q\n' "$hostile_home/hook-pwned" > "$hostile_home/hooks/post-checkout"
/bin/chmod +x "$hostile_home/hooks/post-checkout"
printf '#!/bin/bash\ntouch %q\nexit 99\n' "$hostile_home/path-pwned" > "$hostile_home/hostile-bin/git"
/bin/chmod +x "$hostile_home/hostile-bin/git"
set +e
/usr/bin/env -i HOME="$hostile_home" PATH="$hostile_home/hostile-bin:/usr/bin:/bin" LC_ALL=C TMPDIR="$hostile_home/hostile-tmp;touch PWNED" PERL5LIB="$hostile_home/perl-lib" PERL5OPT=-MHostile DOTFILES_TEST_PERL_MARKER="$hostile_home/perl-pwned" DOTFILES_REMOTE="$REMOTE" DOTFILES_GIT_DIR="$hostile_home/.cfg" DOTFILES_WORK_TREE="$hostile_home" XDG_STATE_HOME="$hostile_home/.state" DOTFILES_SKIP_PLATFORM_CHECK=1 "$bootstrap" --yes > "$hostile_home.output" 2>&1
hostile_status=$?
set -e
assert_eq 0 "$hostile_status" 'hostile ambient environment is ignored'
assert_absent "$hostile_home/path-pwned"
assert_absent "$hostile_home/hook-pwned"
assert_absent "$hostile_home/ambient-pwned"
assert_absent "$hostile_home/PWNED"
assert_absent "$hostile_home/perl-pwned"

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
