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

fixture_git_with_index() {
  local index_file=$1
  shift

  /usr/bin/env -i \
    HOME="$TEST_ROOT/git-home" \
    PATH=/usr/bin:/bin \
    LC_ALL=C \
    TMPDIR="$TEST_ROOT/git-tmp" \
    GIT_CONFIG_NOSYSTEM=1 \
    GIT_CONFIG_GLOBAL=/dev/null \
    GIT_INDEX_FILE="$index_file" \
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
  printf '#!/bin/bash\nprintf "fixture check from %%s\\n" "$0"\nprintf "fixture check PATH=%%s\\n" "$PATH"\n' > "$source/.config/dotfiles/check"
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

run_bootstrap_with_index_file() {
  local home=$1
  local remote=$2
  local index_file=$3
  shift 3
  local output="$home.bootstrap-output"
  local status

  set +e
  /usr/bin/env -i \
    HOME="$home" PATH=/usr/bin:/bin LC_ALL=C \
    GIT_INDEX_FILE="$index_file" \
    DOTFILES_REMOTE="$remote" DOTFILES_GIT_DIR="$home/.cfg" DOTFILES_WORK_TREE="$home" \
    XDG_STATE_HOME="$home/.state" DOTFILES_SKIP_PLATFORM_CHECK=1 \
    "$bootstrap" "$@" > "$output" 2>&1
  status=$?
  set -e
  BOOTSTRAP_STATUS=$status
  BOOTSTRAP_OUTPUT=$(/bin/cat "$output")
}

run_bootstrap_from_source() {
  local home=$1
  local remote=$2
  local source=$3
  local source_ref=$4
  shift 4
  local output="$home.bootstrap-output"
  local status

  set +e
  if [[ $source_ref == UNSET ]]; then
    /usr/bin/env -i \
      HOME="$home" PATH=/usr/bin:/bin LC_ALL=C \
      DOTFILES_REMOTE="$remote" DOTFILES_SOURCE="$source" DOTFILES_GIT_DIR="$home/.cfg" DOTFILES_WORK_TREE="$home" \
      XDG_STATE_HOME="$home/.state" DOTFILES_SKIP_PLATFORM_CHECK=1 \
      "$bootstrap" "$@" > "$output" 2>&1
  else
    /usr/bin/env -i \
      HOME="$home" PATH=/usr/bin:/bin LC_ALL=C \
      DOTFILES_REMOTE="$remote" DOTFILES_SOURCE="$source" DOTFILES_SOURCE_REF="$source_ref" \
      DOTFILES_GIT_DIR="$home/.cfg" DOTFILES_WORK_TREE="$home" \
      XDG_STATE_HOME="$home/.state" DOTFILES_SKIP_PLATFORM_CHECK=1 \
      "$bootstrap" "$@" > "$output" 2>&1
  fi
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
assert_eq origin "$(/usr/bin/git --git-dir="$clean_home/.cfg" config --get branch.main.remote)" 'fresh bootstrap branch remote'
assert_eq refs/heads/main "$(/usr/bin/git --git-dir="$clean_home/.cfg" config --get branch.main.merge)" 'fresh bootstrap branch merge ref'
clean_head=$(fixture_git --git-dir="$clean_home/.cfg" rev-parse HEAD)
assert_eq "$clean_head" "$(fixture_git --git-dir="$clean_home/.cfg" rev-parse refs/remotes/origin/main)" \
  'fresh bootstrap initializes origin tracking ref without fetching'
assert_eq "$clean_head" "$(fixture_git --git-dir="$clean_home/.cfg" rev-parse '@{upstream}')" \
  'fresh bootstrap creates a resolvable upstream'
assert_contains 'platform check skipped by explicit test override' "$BOOTSTRAP_OUTPUT" 'test-only platform warning'
assert_absent "$clean_home/.config/git/config.local"
assert_absent "$clean_home/.config/git/allowed_signers.local"
assert_absent "$clean_home/.config/zsh/.zshrc.local"
assert_absent "$clean_home/.config/tmux-sessionizer/tmux-sessionizer.local.conf"
assert_contains "/bin/cp -- $clean_home/.config/dotfiles/templates/gitconfig.local.example $clean_home/.config/git/config.local" \
  "$BOOTSTRAP_OUTPUT" 'git identity copy instruction'
assert_contains 'allowed_signers.local' "$BOOTSTRAP_OUTPUT" 'allowed signers copy instruction'
assert_contains "/bin/cp -- $clean_home/.config/dotfiles/templates/zshrc.local.example $clean_home/.config/zsh/.zshrc.local" \
  "$BOOTSTRAP_OUTPUT" 'zsh copy instruction'
assert_contains 'tmux-sessionizer.local.conf' "$BOOTSTRAP_OUTPUT" 'tmux-sessionizer local config copy instruction'
[[ $BOOTSTRAP_OUTPUT != *brew* ]] || fail 'bootstrap must not install programs'

legacy_home="$TEST_ROOT/legacy-home"
/bin/mkdir "$legacy_home"
printf '[user]\n  name = Legacy Fixture\n' > "$legacy_home/.gitconfig.local"
legacy_before=$(/usr/bin/shasum -a 256 "$legacy_home/.gitconfig.local")
run_bootstrap "$legacy_home" "$REMOTE" --yes
[[ $BOOTSTRAP_STATUS -ne 0 ]] || fail 'legacy-only bootstrap must require migration'
assert_contains "/bin/mv -- $legacy_home/.gitconfig.local $legacy_home/.config/git/config.local" \
  "$BOOTSTRAP_OUTPUT" 'legacy bootstrap move guidance'
assert_eq "$legacy_before" "$(/usr/bin/shasum -a 256 "$legacy_home/.gitconfig.local")" \
  'legacy bootstrap preserves local bytes'
assert_absent "$legacy_home/.config/git/config.local"

legacy_both_home="$TEST_ROOT/legacy-both-home"
/bin/mkdir -p "$legacy_both_home/.config/git"
printf 'legacy\n' > "$legacy_both_home/.gitconfig.local"
printf 'active\n' > "$legacy_both_home/.config/git/config.local"
run_bootstrap "$legacy_both_home" "$REMOTE" --yes
[[ $BOOTSTRAP_STATUS -ne 0 ]] || fail 'both-exist bootstrap must require manual comparison'
assert_contains 'Compare both files, then remove the legacy path manually' "$BOOTSTRAP_OUTPUT" \
  'bootstrap both-exist guidance'
assert_not_contains "/bin/mv -- $legacy_both_home/.gitconfig.local" "$BOOTSTRAP_OUTPUT" \
  'bootstrap overwrite prevention'
assert_eq legacy "$(<"$legacy_both_home/.gitconfig.local")" 'bootstrap preserves legacy value'
assert_eq active "$(<"$legacy_both_home/.config/git/config.local")" 'bootstrap preserves active value'

legacy_dry_home="$TEST_ROOT/legacy-dry-home"
/bin/mkdir "$legacy_dry_home"
printf 'legacy dry run\n' > "$legacy_dry_home/.zshrc.local"
legacy_dry_before=$(snapshot_tree "$legacy_dry_home")
run_bootstrap "$legacy_dry_home" "$REMOTE" --dry-run
[[ $BOOTSTRAP_STATUS -ne 0 ]] || fail 'legacy dry-run must require migration'
assert_contains "/bin/mv -- $legacy_dry_home/.zshrc.local $legacy_dry_home/.config/zsh/.zshrc.local" \
  "$BOOTSTRAP_OUTPUT" 'legacy dry-run move guidance'
assert_contains 'Dry run complete; no changes made.' "$BOOTSTRAP_OUTPUT" 'legacy dry-run completion'
assert_eq "$legacy_dry_before" "$(snapshot_tree "$legacy_dry_home")" 'legacy dry-run changes nothing'
assert_absent "$legacy_dry_home/.cfg"

fresh_hostile_home="$TEST_ROOT/fresh-hostile-index-home"
fresh_external_index="$TEST_ROOT/fresh-hostile.index"
/bin/mkdir "$fresh_hostile_home"
run_bootstrap_with_index_file "$fresh_hostile_home" "$REMOTE" "$fresh_external_index" --yes
assert_eq 0 "$BOOTSTRAP_STATUS" "fresh bootstrap ignores hostile external index: $BOOTSTRAP_OUTPUT"
assert_absent "$fresh_external_index"
assert_eq '' "$(fixture_git --git-dir="$fresh_hostile_home/.cfg" --work-tree="$fresh_hostile_home" status --short)" \
  'fresh bootstrap leaves the real repository status clean'

staged_home="$TEST_ROOT/staged-existing-home"
/bin/cp -R "$clean_home" "$staged_home"
staged_blob=$(printf 'unique staged bytes not in worktree\n' | fixture_git --git-dir="$staged_home/.cfg" hash-object -w --stdin)
fixture_git --git-dir="$staged_home/.cfg" --work-tree="$staged_home" update-index \
  --cacheinfo "100755,$staged_blob,tracked.txt"
fixture_git --git-dir="$staged_home/.cfg" --work-tree="$staged_home" update-index --force-remove .config/dotfiles/check
staged_index_before=$(/usr/bin/shasum -a 256 "$staged_home/.cfg/index")
staged_cached_before=$(fixture_git --git-dir="$staged_home/.cfg" --work-tree="$staged_home" diff --cached --binary HEAD --)
staged_before=$(snapshot_tree "$staged_home")
run_bootstrap "$staged_home" "$REMOTE" --yes
[[ $BOOTSTRAP_STATUS -ne 0 ]] || fail 'existing repository staged changes must reject bootstrap'
assert_contains 'staged' "$BOOTSTRAP_OUTPUT" 'staged rejection is clear'
assert_eq "$staged_index_before" "$(/usr/bin/shasum -a 256 "$staged_home/.cfg/index")" \
  'staged rejection preserves index bytes'
assert_eq "$staged_cached_before" \
  "$(fixture_git --git-dir="$staged_home/.cfg" --work-tree="$staged_home" diff --cached --binary HEAD --)" \
  'staged rejection preserves cached diff'
assert_eq "$staged_before" "$(snapshot_tree "$staged_home")" \
  'staged rejection preserves worktree, repository, and backup state'

unstaged_home="$TEST_ROOT/unstaged-existing-home"
/bin/cp -R "$clean_home" "$unstaged_home"
printf 'unstaged bytes\n' >> "$unstaged_home/tracked.txt"
unstaged_before=$(snapshot_tree "$unstaged_home")
run_bootstrap "$unstaged_home" "$REMOTE" --yes
[[ $BOOTSTRAP_STATUS -ne 0 ]] || fail 'existing repository unstaged changes must still reject bootstrap'
assert_contains 'checkout is unsafe' "$BOOTSTRAP_OUTPUT" 'unstaged rejection remains clear'
assert_eq "$unstaged_before" "$(snapshot_tree "$unstaged_home")" \
  'unstaged rejection preserves worktree, repository, and backup state'

hostile_clean_index="$TEST_ROOT/hostile-clean.index"
fixture_git_with_index "$hostile_clean_index" --git-dir="$staged_home/.cfg" read-tree HEAD
hostile_clean_before=$(/usr/bin/shasum -a 256 "$hostile_clean_index")
run_bootstrap_with_index_file "$staged_home" "$REMOTE" "$hostile_clean_index" --yes
[[ $BOOTSTRAP_STATUS -ne 0 ]] || fail 'hostile clean alternate index must not bypass real staged rejection'
assert_contains 'staged' "$BOOTSTRAP_OUTPUT" 'real staged state wins over hostile clean alternate index'
assert_eq "$hostile_clean_before" "$(/usr/bin/shasum -a 256 "$hostile_clean_index")" \
  'rejected bootstrap leaves hostile clean alternate index unchanged'
assert_eq "$staged_index_before" "$(/usr/bin/shasum -a 256 "$staged_home/.cfg/index")" \
  'hostile clean alternate index cannot redirect staged-state validation'

hostile_dirty_home="$TEST_ROOT/hostile-dirty-index-home"
/bin/cp -R "$clean_home" "$hostile_dirty_home"
hostile_dirty_index="$TEST_ROOT/hostile-dirty.index"
fixture_git_with_index "$hostile_dirty_index" --git-dir="$hostile_dirty_home/.cfg" read-tree HEAD
hostile_dirty_blob=$(printf 'hostile alternate-only bytes\n' | fixture_git --git-dir="$hostile_dirty_home/.cfg" hash-object -w --stdin)
fixture_git_with_index "$hostile_dirty_index" --git-dir="$hostile_dirty_home/.cfg" update-index \
  --cacheinfo "100644,$hostile_dirty_blob,tracked.txt"
hostile_dirty_before=$(/usr/bin/shasum -a 256 "$hostile_dirty_index")
run_bootstrap_with_index_file "$hostile_dirty_home" "$REMOTE" "$hostile_dirty_index" --yes
assert_eq 0 "$BOOTSTRAP_STATUS" "clean real index ignores hostile dirty alternate: $BOOTSTRAP_OUTPUT"
assert_eq "$hostile_dirty_before" "$(/usr/bin/shasum -a 256 "$hostile_dirty_index")" \
  'successful bootstrap leaves hostile dirty alternate index unchanged'
assert_eq '' "$(fixture_git --git-dir="$hostile_dirty_home/.cfg" --work-tree="$hostile_dirty_home" status --short)" \
  'clean real repository remains clean under hostile dirty alternate index'
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
run_bootstrap_from_source "$source_pinned_home" "$REMOTE" "$reviewed_clone/.git" "$reviewed_head" --dry-run
assert_eq 0 "$BOOTSTRAP_STATUS" "source-pinned dry-run succeeds: $BOOTSTRAP_OUTPUT"
assert_eq "$source_pinned_before" "$(snapshot_tree "$source_pinned_home")" 'source-pinned dry-run changes nothing'
assert_absent "$source_pinned_home/.cfg"
assert_not_contains remote-advance.txt "$BOOTSTRAP_OUTPUT" 'source-pinned dry-run does not inspect final remote advance'
printf 'source clone commit B\n' > "$reviewed_clone/reviewed.txt"
printf 'source clone only B\n' > "$reviewed_clone/source-clone-advance.txt"
fixture_git -C "$reviewed_clone" add reviewed.txt source-clone-advance.txt
fixture_git -C "$reviewed_clone" -c user.name='Bootstrap Test' -c user.email=bootstrap@example.invalid \
  -c commit.gpgSign=false commit -qm 'source clone advances to B'
source_head_b=$(fixture_git -C "$reviewed_clone" rev-parse HEAD)
[[ $reviewed_head != "$source_head_b" ]] || fail 'reviewed source clone must advance after dry-run'
run_bootstrap_from_source "$source_pinned_home" "$REMOTE" "$reviewed_clone/.git" "$reviewed_head" --yes
assert_eq 0 "$BOOTSTRAP_STATUS" "source-pinned bootstrap succeeds: $BOOTSTRAP_OUTPUT"
assert_eq 'reviewed commit A' "$(<"$source_pinned_home/reviewed.txt")" 'source-pinned checkout uses reviewed commit'
assert_absent "$source_pinned_home/remote-advance.txt"
assert_absent "$source_pinned_home/source-clone-advance.txt"
assert_eq "$reviewed_head" "$(fixture_git --git-dir="$source_pinned_home/.cfg" rev-parse HEAD)" 'dry-run and actual placement use the reviewed source HEAD'
assert_eq "$REMOTE" "$(fixture_git --git-dir="$source_pinned_home/.cfg" config --get remote.origin.url)" 'source-pinned installation resets origin to final remote'

source_unpinned_home="$TEST_ROOT/source-unpinned-home"
/bin/mkdir "$source_unpinned_home"
run_bootstrap_from_source "$source_unpinned_home" "$REMOTE" "$reviewed_clone/.git" UNSET --yes
assert_eq 0 "$BOOTSTRAP_STATUS" "source-only bootstrap succeeds: $BOOTSTRAP_OUTPUT"
assert_eq 'source clone commit B' "$(<"$source_unpinned_home/reviewed.txt")" \
  'DOTFILES_SOURCE without a ref preserves source HEAD behavior'
assert_eq "$source_head_b" "$(fixture_git --git-dir="$source_unpinned_home/.cfg" rev-parse HEAD)" \
  'source-only bootstrap installs current source HEAD'

invalid_source_home="$TEST_ROOT/invalid-source-home"
/bin/mkdir "$invalid_source_home"
invalid_source_before=$(snapshot_tree "$invalid_source_home")
run_bootstrap_from_source "$invalid_source_home" "$REMOTE" "$TEST_ROOT/missing-reviewed-source" UNSET --dry-run
[[ $BOOTSTRAP_STATUS -ne 0 ]] || fail 'missing DOTFILES_SOURCE must fail without falling back to the final remote'
assert_contains 'bare clone failed' "$BOOTSTRAP_OUTPUT" 'missing DOTFILES_SOURCE failure is clear'
assert_eq "$invalid_source_before" "$(snapshot_tree "$invalid_source_home")" 'invalid DOTFILES_SOURCE leaves worktree unchanged'
assert_absent "$invalid_source_home/.cfg"

for invalid_ref in main 0000000000000000000000000000000000000000; do
  invalid_ref_home="$TEST_ROOT/invalid-ref-malformed"
  [[ $invalid_ref == main ]] || invalid_ref_home="$TEST_ROOT/invalid-ref-missing"
  /bin/mkdir "$invalid_ref_home"
  invalid_ref_before=$(snapshot_tree "$invalid_ref_home")
  run_bootstrap_from_source "$invalid_ref_home" "$REMOTE" "$reviewed_clone/.git" "$invalid_ref" --yes
  [[ $BOOTSTRAP_STATUS -ne 0 ]] || fail "invalid DOTFILES_SOURCE_REF must fail: $invalid_ref"
  assert_contains 'DOTFILES_SOURCE_REF' "$BOOTSTRAP_OUTPUT" 'invalid source ref failure is clear'
  assert_eq "$invalid_ref_before" "$(snapshot_tree "$invalid_ref_home")" 'invalid source ref leaves worktree unchanged'
  assert_absent "$invalid_ref_home/.cfg"
  [[ -z $(/usr/bin/find "$invalid_ref_home" -maxdepth 1 -name '.cfg.bootstrap.*' -print -quit) ]] || \
    fail 'invalid source ref cleans candidate and lock'
done

identity_home="$TEST_ROOT/identity-home"
/bin/mkdir "$identity_home"
/bin/mkdir -p "$identity_home/.config/git"
printf '[user]\n  name = Local Fixture\n' > "$identity_home/.config/git/config.local"
run_bootstrap "$identity_home" "$REMOTE" --yes
assert_eq 0 "$BOOTSTRAP_STATUS" 'bootstrap with local identity succeeds'
assert_contains "fixture check from $identity_home/.config/dotfiles/check" "$BOOTSTRAP_OUTPUT" \
  'check runs from the checked-out fixture, not the real home'
assert_contains 'fixture check PATH=/opt/homebrew/bin:/usr/bin:/bin' "$BOOTSTRAP_OUTPUT" \
  'bootstrap check sees the Apple Silicon Homebrew tool path'
assert_absent "$identity_home/.config/git/allowed_signers.local"
assert_absent "$identity_home/.config/zsh/.zshrc.local"
assert_absent "$identity_home/.config/tmux-sessionizer/tmux-sessionizer.local.conf"
assert_contains "/bin/cp -- $identity_home/.config/dotfiles/templates/allowed_signers.local.example $identity_home/.config/git/allowed_signers.local" \
  "$BOOTSTRAP_OUTPUT" 'missing allowed signers template hint with existing identity'
assert_contains "/bin/cp -- $identity_home/.config/dotfiles/templates/zshrc.local.example $identity_home/.config/zsh/.zshrc.local" \
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
