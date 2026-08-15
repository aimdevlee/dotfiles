# Legacy Local Migration Guard Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Detect obsolete `~/.gitconfig.local` and `~/.zshrc.local` files, keep them ignored, and require a safe manual migration to the active XDG paths.

**Architecture:** Add one side-effect-free Bash reporting module shared by `bootstrap` and `check`. Each caller retains its existing control flow and converts a detected legacy path into its own nonzero result; tests exercise the public scripts rather than mocking the helper.

**Tech Stack:** Bash 3.2-compatible shell, Git bare work-tree commands, existing shell test harness.

---

### Task 1: Restore the legacy ignore safety net

**Files:**
- Modify: `.gitignore`
- Modify: `.config/dotfiles/tests/ignore_test.sh`

- [ ] **Step 1: Write the failing ignore test**

Add the two legacy paths beside the active paths in `ignored_paths`:

```bash
  .gitconfig.local
  .zshrc.local
  .config/git/config.local
  .config/zsh/.zshrc.local
```

- [ ] **Step 2: Run the test and verify RED**

Run:

```bash
DOTFILES_WORK_TREE="$PWD" DOTFILES_GIT_DIR="$(git rev-parse --absolute-git-dir)" \
  .config/dotfiles/tests/ignore_test.sh
```

Expected: `FAIL: expected [.gitconfig.local] to be ignored`.

- [ ] **Step 3: Restore compatibility ignores**

Add these rules under the machine-local configuration heading:

```gitignore
# Legacy locations remain ignored until every existing Mac is migrated.
/.gitconfig.local
/.zshrc.local
```

- [ ] **Step 4: Run the ignore test and verify GREEN**

Run:

```bash
DOTFILES_WORK_TREE="$PWD" DOTFILES_GIT_DIR="$(git rev-parse --absolute-git-dir)" \
  .config/dotfiles/tests/ignore_test.sh
```

Expected: `PASS: ignore policy`.

- [ ] **Step 5: Commit the focused change**

```bash
git add .gitignore .config/dotfiles/tests/ignore_test.sh
git commit -m "fix(dotfiles): keep legacy local paths ignored"
```

### Task 2: Add the shared migration reporter and check integration

**Files:**
- Create: `.config/dotfiles/local_migration.sh`
- Modify: `.config/dotfiles/check`
- Modify: `.config/dotfiles/tests/check_test.sh`

- [ ] **Step 1: Add failing check fixtures**

After the existing missing-identity fixture, add fixtures that create a legacy-only Git file, a legacy-only Zsh file, and both legacy plus XDG files. Assert nonzero status, no local contents in output, exact move guidance only for legacy-only state, and the manual comparison message for both-exist state:

```bash
make_fixture legacy-git-only
legacy_git_fixture=$FIXTURE
printf '[user]\n  name = Never Print This\n' > "$legacy_git_fixture/home/.gitconfig.local"
rm "$legacy_git_fixture/home/.config/git/config.local"
run_check "$legacy_git_fixture"
assert_nonzero "$CHECK_STATUS" 'legacy Git config check'
assert_contains 'Legacy machine-local Git config is no longer loaded' "$CHECK_OUTPUT" 'legacy Git diagnosis'
assert_contains "/bin/mv -- $legacy_git_fixture/home/.gitconfig.local $legacy_git_fixture/home/.config/git/config.local" "$CHECK_OUTPUT" 'legacy Git move guidance'
assert_not_contains 'Never Print This' "$CHECK_OUTPUT" 'legacy Git content redaction'

make_fixture legacy-zsh-only
legacy_zsh_fixture=$FIXTURE
printf 'export NEVER_PRINT_THIS=yes\n' > "$legacy_zsh_fixture/home/.zshrc.local"
run_check "$legacy_zsh_fixture"
assert_nonzero "$CHECK_STATUS" 'legacy Zsh config check'
assert_contains 'Legacy machine-local Zsh config is no longer loaded' "$CHECK_OUTPUT" 'legacy Zsh diagnosis'
assert_contains "/bin/mv -- $legacy_zsh_fixture/home/.zshrc.local $legacy_zsh_fixture/home/.config/zsh/.zshrc.local" "$CHECK_OUTPUT" 'legacy Zsh move guidance'
assert_not_contains 'NEVER_PRINT_THIS' "$CHECK_OUTPUT" 'legacy Zsh content redaction'

make_fixture legacy-both-exist
legacy_both_fixture=$FIXTURE
printf '# legacy\n' > "$legacy_both_fixture/home/.zshrc.local"
printf '# active\n' > "$legacy_both_fixture/home/.config/zsh/.zshrc.local"
run_check "$legacy_both_fixture"
assert_nonzero "$CHECK_STATUS" 'legacy and active Zsh config check'
assert_contains 'Compare both files, then remove the legacy path manually' "$CHECK_OUTPUT" 'both-exist guidance'
assert_not_contains "/bin/mv -- $legacy_both_fixture/home/.zshrc.local" "$CHECK_OUTPUT" 'both-exist overwrite prevention'
```

- [ ] **Step 2: Run the check test and verify RED**

Run:

```bash
.config/dotfiles/tests/check_test.sh
```

Expected: the legacy-only fixture unexpectedly succeeds or lacks `Legacy machine-local Git config is no longer loaded`.

- [ ] **Step 3: Implement the shared reporter**

Create `.config/dotfiles/local_migration.sh`:

```bash
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

  report_legacy_local_pair 'Git config' "$work_tree/.gitconfig.local" "$work_tree/.config/git/config.local" && found=1
  report_legacy_local_pair 'Zsh config' "$work_tree/.zshrc.local" "$work_tree/.config/zsh/.zshrc.local" && found=1
  [[ $found -eq 0 ]]
}
```

- [ ] **Step 4: Integrate the reporter into check**

Source the module beside `lib.sh`:

```bash
# shellcheck source=local_migration.sh
source "$script_dir/local_migration.sh"
```

Set `local_migration_script` beside the existing `check_script` and `lib_script` test paths, and copy the module into each fixture source repository when `make_fixture` copies the other dotfiles scripts:

```bash
local_migration_script="$work_tree/.config/dotfiles/local_migration.sh"
cp "$local_migration_script" "$source_repo/.config/dotfiles/local_migration.sh"
```

Add this check before identity validation:

```bash
check_legacy_local_migrations() {
  if report_legacy_local_migrations "$DOTFILES_WORK_TREE"; then
    pass 'legacy machine-local configuration paths are absent'
  else
    fail_check 'legacy machine-local configuration requires manual migration'
  fi
}
```

Call `check_legacy_local_migrations` immediately before `check_identity_and_signing`.

- [ ] **Step 5: Run the check test and verify GREEN**

Run:

```bash
.config/dotfiles/tests/check_test.sh
```

Expected: `PASS: dotfiles checks`.

- [ ] **Step 6: Commit the focused change**

```bash
git add .config/dotfiles/local_migration.sh .config/dotfiles/check .config/dotfiles/tests/check_test.sh
git commit -m "fix(dotfiles): detect legacy local configuration"
```

### Task 3: Guard bootstrap and dry-run without moving local files

**Files:**
- Modify: `.config/dotfiles/bootstrap`
- Modify: `.config/dotfiles/tests/bootstrap_test.sh`

- [ ] **Step 1: Add failing bootstrap fixtures**

Add a legacy-only fixture and a both-exist fixture after the clean bootstrap assertions. Snapshot each local file before bootstrap and assert that bootstrap returns nonzero without changing its bytes:

```bash
legacy_home="$TEST_ROOT/legacy-home"
/bin/mkdir "$legacy_home"
printf '[user]\n  name = Legacy Fixture\n' > "$legacy_home/.gitconfig.local"
legacy_before=$(/usr/bin/shasum -a 256 "$legacy_home/.gitconfig.local")
run_bootstrap "$legacy_home" "$REMOTE" --yes
[[ $BOOTSTRAP_STATUS -ne 0 ]] || fail 'legacy-only bootstrap must require migration'
assert_contains "/bin/mv -- $legacy_home/.gitconfig.local $legacy_home/.config/git/config.local" "$BOOTSTRAP_OUTPUT" 'legacy bootstrap move guidance'
assert_eq "$legacy_before" "$(/usr/bin/shasum -a 256 "$legacy_home/.gitconfig.local")" 'legacy bootstrap preserves local bytes'
assert_absent "$legacy_home/.config/git/config.local"

legacy_both_home="$TEST_ROOT/legacy-both-home"
/bin/mkdir -p "$legacy_both_home/.config/git"
printf 'legacy\n' > "$legacy_both_home/.gitconfig.local"
printf 'active\n' > "$legacy_both_home/.config/git/config.local"
run_bootstrap "$legacy_both_home" "$REMOTE" --yes
[[ $BOOTSTRAP_STATUS -ne 0 ]] || fail 'both-exist bootstrap must require manual comparison'
assert_contains 'Compare both files, then remove the legacy path manually' "$BOOTSTRAP_OUTPUT" 'bootstrap both-exist guidance'
assert_not_contains "/bin/mv -- $legacy_both_home/.gitconfig.local" "$BOOTSTRAP_OUTPUT" 'bootstrap overwrite prevention'
assert_eq legacy "$(<"$legacy_both_home/.gitconfig.local")" 'bootstrap preserves legacy value'
assert_eq active "$(<"$legacy_both_home/.config/git/config.local")" 'bootstrap preserves active value'
```

Add a dry-run assertion using the legacy-only fixture that expects nonzero status, includes `Dry run complete; no changes made.`, and preserves the entire `snapshot_tree`.

- [ ] **Step 2: Run the bootstrap test and verify RED**

Run:

```bash
.config/dotfiles/tests/bootstrap_test.sh
```

Expected: the legacy-only bootstrap returns zero or lacks migration guidance.

- [ ] **Step 3: Source and invoke the shared reporter**

Resolve and source the module next to `bootstrap`, rejecting a missing module:

```bash
script_dir=$(cd -- "$(/usr/bin/dirname -- "${BASH_SOURCE[0]}")" && pwd)
migration_library=$script_dir/local_migration.sh
[[ -f $migration_library && ! -L $migration_library ]] || die 'local migration library is unavailable or unsafe'
# shellcheck source=local_migration.sh
source "$migration_library"
```

For dry-run, report legacy paths before the final message and return nonzero without changing files:

```bash
legacy_migration_status=0
report_legacy_local_migrations "$work_tree_canonical" || legacy_migration_status=$?

if [[ $mode == dry-run ]]; then
  printf 'Dry run complete; no changes made.\n'
  exit "$legacy_migration_status"
fi
```

After checkout and before template hints or `check`, reject the real run when `legacy_migration_status` is nonzero:

```bash
[[ $legacy_migration_status -eq 0 ]] || die 'legacy machine-local configuration requires manual migration'
```

- [ ] **Step 4: Run the bootstrap test and verify GREEN**

Run:

```bash
.config/dotfiles/tests/bootstrap_test.sh
```

Expected: `PASS: bootstrap is conflict-safe, non-destructive, hostile-environment resistant, and idempotent`.

- [ ] **Step 5: Commit the focused change**

```bash
git add .config/dotfiles/bootstrap .config/dotfiles/tests/bootstrap_test.sh
git commit -m "fix(dotfiles): block unsafe legacy local upgrades"
```

### Task 4: Document and lock the one-time migration workflow

**Files:**
- Modify: `.config/dotfiles/README.md`
- Modify: `.config/dotfiles/tests/readme_test.sh`

- [ ] **Step 1: Add failing README contract assertions**

Require the migration heading, both legacy paths, guarded destination checks, exact move commands, and both-exist warning:

```bash
'## Migrating legacy local files'
'if [[ -e "$HOME/.gitconfig.local" || -L "$HOME/.gitconfig.local" ]]; then'
'  /bin/mv -- "$HOME/.gitconfig.local" "$HOME/.config/git/config.local"'
'if [[ -e "$HOME/.zshrc.local" || -L "$HOME/.zshrc.local" ]]; then'
'  /bin/mv -- "$HOME/.zshrc.local" "$HOME/.config/zsh/.zshrc.local"'
'STOP: both legacy and XDG paths exist; compare them before removing the legacy file.'
```

- [ ] **Step 2: Run the README test and verify RED**

Run:

```bash
.config/dotfiles/tests/readme_test.sh
```

Expected: missing `## Migrating legacy local files`.

- [ ] **Step 3: Add guarded README commands**

Document a one-time section before `Local files and templates` with both guarded path pairs:

```bash
if [[ -e "$HOME/.gitconfig.local" || -L "$HOME/.gitconfig.local" ]]; then
  if [[ -e "$HOME/.config/git/config.local" || -L "$HOME/.config/git/config.local" ]]; then
    printf '%s\n' 'STOP: both legacy and XDG paths exist; compare them before removing the legacy file.'
  else
    /bin/mv -- "$HOME/.gitconfig.local" "$HOME/.config/git/config.local"
  fi
fi

if [[ -e "$HOME/.zshrc.local" || -L "$HOME/.zshrc.local" ]]; then
  if [[ -e "$HOME/.config/zsh/.zshrc.local" || -L "$HOME/.config/zsh/.zshrc.local" ]]; then
    printf '%s\n' 'STOP: both legacy and XDG paths exist; compare them before removing the legacy file.'
  else
    /bin/mv -- "$HOME/.zshrc.local" "$HOME/.config/zsh/.zshrc.local"
  fi
fi
```

State that bootstrap and check never perform this move automatically.

- [ ] **Step 4: Run the README test and verify GREEN**

Run:

```bash
.config/dotfiles/tests/readme_test.sh
```

Expected: three `PASS: README documentation policy` lines.

- [ ] **Step 5: Commit the focused change**

```bash
git add .config/dotfiles/README.md .config/dotfiles/tests/readme_test.sh
git commit -m "docs(dotfiles): document legacy local migration"
```

### Task 5: Full verification and integration readiness

**Files:**
- Verify all files changed by Tasks 1-4

- [ ] **Step 1: Run formatting and whitespace validation**

```bash
git diff --check main...HEAD
/bin/bash -n .config/dotfiles/bootstrap .config/dotfiles/check .config/dotfiles/local_migration.sh
```

Expected: no output and status zero.

- [ ] **Step 2: Run the complete suite with real tmux socket permission**

```bash
.config/dotfiles/tests/run
```

Expected:

```text
PASS: ignore policy
PASS: shell helpers
PASS: dotfiles checks
PASS: bootstrap is conflict-safe, non-destructive, hostile-environment resistant, and idempotent
PASS: README documentation policy
```

- [ ] **Step 3: Confirm branch scope and secret safety**

```bash
git status --short --branch
git diff --stat main...HEAD
git diff main...HEAD -- .gitignore .config/dotfiles
```

Expected: only the migration guard, its tests, README, specification, and implementation plan are present; no machine-local file contents appear.

- [ ] **Step 4: Run the live check after integration**

After fast-forwarding `main` and synchronizing the bare index, run:

```bash
~/.config/dotfiles/check
```

Expected: `legacy machine-local configuration paths are absent`, `tracked work-tree files are unchanged`, and `0 FAIL` outside the restricted socket sandbox.
