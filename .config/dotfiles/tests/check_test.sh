#!/usr/bin/env bash
set -euo pipefail

script_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
source "$script_dir/test_helpers.sh"

work_tree=$(git -C "$script_dir" rev-parse --show-toplevel)
check_script="$work_tree/.config/dotfiles/check"
lib_script="$work_tree/.config/dotfiles/lib.sh"

make_test_root
trap cleanup_test_root EXIT

assert_not_contains() {
  local needle=$1
  local haystack=$2
  local message=${3:-expected value not to contain substring}

  [[ $haystack != *"$needle"* ]] || fail "$message: unexpectedly found [$needle]"
}

assert_nonzero() {
  local status=$1
  local message=$2

  [[ $status -ne 0 ]] || fail "$message: expected nonzero status"
}

assert_zero() {
  local status=$1
  local message=$2

  [[ $status -eq 0 ]] || fail "$message: expected zero status, got [$status]"
}

assert_file_empty() {
  local path=$1
  local message=$2

  [[ ! -s $path ]] || fail "$message: [$(cat "$path")]"
}

make_runtime_path() {
  local fixture=$1
  local bin_dir="$fixture/bin"
  local tool

  mkdir -p "$bin_dir"
  for tool in awk basename bash dirname find grep mkdir sed shasum ssh-keygen uname zsh; do
    if [[ -x /usr/bin/$tool ]]; then
      ln -s "/usr/bin/$tool" "$bin_dir/$tool"
    elif [[ -x /bin/$tool ]]; then
      ln -s "/bin/$tool" "$bin_dir/$tool"
    fi
  done

  printf '%s\n' \
    '#!/bin/bash' \
    'for argument in "$@"; do' \
    '  if [[ $argument == fetch ]]; then' \
    '    printf "%s\\n" "$*" >> "${DOTFILES_TEST_FETCH_LOG:?}"' \
    '    break' \
    '  fi' \
    'done' \
    'exec /usr/bin/git "$@"' > "$bin_dir/git"
  chmod +x "$bin_dir/git"
}

make_optional_tool_wrappers() {
  local fixture=$1
  local bin_dir="$fixture/bin"
  local log="$fixture/optional-tools.log"

  : > "$log"
  printf '%s\n' \
    '#!/bin/bash' \
    "[[ -L \$XDG_CONFIG_HOME/nvim ]] || exit 91" \
    "[[ \$XDG_CONFIG_HOME/nvim/init.lua -ef '$fixture/home/.config/nvim/init.lua' ]] || exit 92" \
    '[[ -f $XDG_DATA_HOME/nvim/lazy/lazy.nvim/lua/lazy/init.lua ]] || exit 93' \
    "printf 'nvim|%s\\n' \"\$*\" >> '$log'" \
    'exit 0' > "$bin_dir/nvim"
  printf '%s\n' \
    '#!/bin/bash' \
    "printf 'tmux|%s\\n' \"\$*\" >> '$log'" \
    'exit 0' > "$bin_dir/tmux"
  printf '%s\n' \
    '#!/bin/bash' \
    "printf 'gitleaks|%s\\n' \"\$*\" >> '$log'" \
    'exit 0' > "$bin_dir/gitleaks"
  printf '%s\n' \
    '#!/bin/bash' \
    "printf 'brew|%s|%s\\n' \"\${HOMEBREW_NO_AUTO_UPDATE:-}\" \"\$*\" >> '$log'" \
    'exit 1' > "$bin_dir/brew"
  chmod +x "$bin_dir/nvim" "$bin_dir/tmux" "$bin_dir/gitleaks" "$bin_dir/brew"
}

write_common_config() {
  local home=$1

  mkdir -p "$home/.config/git"
  printf '%s\n' \
    '[user]' \
    '  useConfigOnly = true' \
    '[include]' \
    '  path = ~/.gitconfig.local' \
    '[gpg]' \
    '  format = ssh' \
    '[commit]' \
    '  gpgsign = true' > "$home/.config/git/config"
}

write_local_config() {
  local home=$1

  printf '%s\n' \
    '[user]' \
    '  name = Sensitive Fixture Name' \
    '  email = sensitive-fixture@example.invalid' \
    '  signingKey = ~/.ssh/id_ed25519.pub' \
    '[gpg "ssh"]' \
    '  allowedSignersFile = ~/.config/git/allowed_signers.local' > "$home/.gitconfig.local"
}

configure_signing_repo() {
  local repo=$1
  local public_key=$2

  /usr/bin/git -C "$repo" config user.name 'Sensitive Fixture Name'
  /usr/bin/git -C "$repo" config user.email 'sensitive-fixture@example.invalid'
  /usr/bin/git -C "$repo" config user.signingKey "$public_key"
  /usr/bin/git -C "$repo" config gpg.format ssh
  /usr/bin/git -C "$repo" config commit.gpgSign true
}

make_fixture() {
  local name=$1
  local fixture="$TEST_ROOT/$name"
  local home="$fixture/home"
  local source_repo="$fixture/source"
  local remote_repo="$fixture/remote.git"
  local public_key

  mkdir -p "$home/.ssh" "$source_repo"
  /usr/bin/ssh-keygen -q -t ed25519 -N '' -f "$home/.ssh/id_ed25519"
  public_key=$(awk '{print $2}' "$home/.ssh/id_ed25519.pub")
  write_common_config "$home"
  write_local_config "$home"
  printf 'sensitive-fixture@example.invalid ssh-ed25519 %s fixture-comment\n' "$public_key" \
    > "$home/.config/git/allowed_signers.local"

  /usr/bin/git init -q -b main "$source_repo"
  configure_signing_repo "$source_repo" "$home/.ssh/id_ed25519.pub"
  mkdir -p "$source_repo/.config/zsh" "$source_repo/.config/nvim" "$source_repo/.config/tmux" \
    "$source_repo/.config/tmux-sessionizer" "$source_repo/.config/dotfiles/tests" "$source_repo/.local/bin"
  printf '.cfg/\n' > "$source_repo/.gitignore"
  printf 'export FIXTURE=1\n' > "$source_repo/.zshenv"
  printf 'typeset -g FIXTURE_PROFILE=1\n' > "$source_repo/.zprofile"
  printf 'typeset -g FIXTURE_RC=1\n' > "$source_repo/.zshrc"
  printf 'typeset -g FIXTURE=1\n' > "$source_repo/.config/zsh/.zshrc"
  printf 'vim.g.fixture = true\n' > "$source_repo/.config/nvim/init.lua"
  printf 'set -g status off\n' > "$source_repo/.config/tmux/tmux.conf"
  printf '#!/usr/bin/env bash\nprintf "fixture test runner\\n"\n' > "$source_repo/.config/dotfiles/tests/run"
  printf '#!/usr/bin/env bash\nprintf "fixture\\n"\n' > "$source_repo/.config/tmux-sessionizer/tmux-sessionizer"
  printf '#!/usr/bin/env bash\nprintf "fixture\\n"\n' > "$source_repo/.local/bin/tmux-sessionizer"
  chmod +x "$source_repo/.config/dotfiles/tests/run" "$source_repo/.config/tmux-sessionizer/tmux-sessionizer" \
    "$source_repo/.local/bin/tmux-sessionizer"
  /usr/bin/git -C "$source_repo" add .
  /usr/bin/git -C "$source_repo" commit -S -q -m 'signed fixture head'

  /usr/bin/git clone --bare -q "$source_repo" "$remote_repo"
  /usr/bin/git clone --bare -q "$remote_repo" "$home/.cfg"
  /usr/bin/git --git-dir="$home/.cfg" config remote.origin.fetch '+refs/heads/*:refs/remotes/origin/*'
  /usr/bin/git --git-dir="$home/.cfg" config branch.main.remote origin
  /usr/bin/git --git-dir="$home/.cfg" config branch.main.merge refs/heads/main
  /usr/bin/git --git-dir="$home/.cfg" fetch -q origin
  /usr/bin/git --git-dir="$home/.cfg" --work-tree="$home" checkout -q -f main

  make_runtime_path "$fixture"
  : > "$fixture/fetch.log"
  printf '%s\n' "$fixture"
}

run_check() {
  local fixture=$1
  shift
  local home="$fixture/home"
  local output="$fixture.check-output"
  local status

  set +e
  env -i \
    HOME="$home" \
    XDG_CONFIG_HOME="$home/.config" \
    PATH="$fixture/bin" \
    LC_ALL=C \
    TMPDIR="${TMPDIR:-/tmp}" \
    DOTFILES_GIT_DIR="$home/.cfg" \
    DOTFILES_WORK_TREE="$home" \
    DOTFILES_SKIP_PLATFORM_CHECK=1 \
    DOTFILES_TEST_FETCH_LOG="$fixture/fetch.log" \
    "$check_script" "$@" > "$output" 2>&1
  status=$?
  set -e
  CHECK_STATUS=$status
  CHECK_OUTPUT=$(cat "$output")
}

run_hostile_check() {
  local fixture=$1
  local hostile_count=${2:-1}
  local home="$fixture/home"
  local output="$fixture.hostile-output"
  local hostile="$fixture/hostile.gitconfig"
  local status

  printf '%s\n' '[user]' '  name = Hostile Name' '  email = hostile@example.invalid' > "$hostile"
  set +e
  env -i \
    HOME="$home" \
    XDG_CONFIG_HOME="$home/.config" \
    PATH="$fixture/bin" \
    LC_ALL=C \
    TMPDIR="${TMPDIR:-/tmp}" \
    DOTFILES_GIT_DIR="$home/.cfg" \
    DOTFILES_WORK_TREE="$home" \
    DOTFILES_SKIP_PLATFORM_CHECK=1 \
    DOTFILES_TEST_FETCH_LOG="$fixture/fetch.log" \
    GIT_CONFIG="$hostile" \
    GIT_CONFIG_GLOBAL="$hostile" \
    GIT_CONFIG_COUNT="$hostile_count" \
    GIT_CONFIG_KEY_0=user.signingKey \
    GIT_CONFIG_VALUE_0="$fixture/missing-hostile-key.pub" \
    GIT_CONFIG_PARAMETERS="'user.email=parameters@example.invalid'" \
    "$check_script" > "$output" 2>&1
  status=$?
  set -e
  CHECK_STATUS=$status
  CHECK_OUTPUT=$(cat "$output")
}

fixture_git() {
  local fixture=$1
  shift
  local home="$fixture/home"

  env -i \
    HOME="$home" \
    XDG_CONFIG_HOME="$home/.config" \
    PATH=/usr/bin:/bin \
    LC_ALL=C \
    GIT_CONFIG_NOSYSTEM=1 \
    /usr/bin/git --git-dir="$home/.cfg" --work-tree="$home" "$@"
}

snapshot_fixture() {
  local fixture=$1
  local destination=$2

  (
    cd "$fixture"
    find . -type f -print | LC_ALL=C sort | while IFS= read -r path; do
      shasum -a 256 "$path"
    done
    /usr/bin/git --git-dir="$fixture/home/.cfg" show-ref
  ) > "$destination"
}

[[ -r $lib_script ]] || fail 'shared validation library is missing'
(
  # shellcheck disable=SC1090
  source "$lib_script"
  assert_eq 0 "$PASS_COUNT" 'initial pass count'
  assert_eq 0 "$WARN_COUNT" 'initial warning count'
  assert_eq 0 "$FAIL_COUNT" 'initial failure count'
  HOME=/fixture-home
  assert_eq /fixture-home/path "$(expand_home_path '~/path')" 'leading home expansion'
  assert_eq 'prefix~/path' "$(expand_home_path 'prefix~/path')" 'non-leading tilde preservation'
  pass 'library pass' >/dev/null
  warn 'library warning' >/dev/null
  fail_check 'library failure' >/dev/null
  assert_eq 1 "$PASS_COUNT" 'pass count after result'
  assert_eq 1 "$WARN_COUNT" 'warning count after result'
  assert_eq 1 "$FAIL_COUNT" 'failure count after result'
  if summary >/dev/null; then
    fail 'summary succeeded with a recorded failure'
  fi
)

missing_identity_fixture=$(make_fixture missing-identity)
rm "$missing_identity_fixture/home/.gitconfig.local"
run_check "$missing_identity_fixture"
assert_nonzero "$CHECK_STATUS" 'missing local identity check'
assert_contains 'FAIL:' "$CHECK_OUTPUT" 'missing identity result'
assert_not_contains 'Sensitive Fixture Name' "$CHECK_OUTPUT" 'identity name redaction'
assert_not_contains 'sensitive-fixture@example.invalid' "$CHECK_OUTPUT" 'identity email redaction'
assert_file_empty "$missing_identity_fixture/fetch.log" 'default missing-identity check fetched'

complete_fixture=$(make_fixture complete)
run_check "$complete_fixture"
assert_zero "$CHECK_STATUS" 'complete fixture check'
assert_contains 'PASS:' "$CHECK_OUTPUT" 'complete fixture pass output'
assert_contains 'WARN:' "$CHECK_OUTPUT" 'platform skip warning'
assert_contains '0 FAIL' "$CHECK_OUTPUT" 'complete fixture summary'
assert_not_contains 'Sensitive Fixture Name' "$CHECK_OUTPUT" 'complete identity name redaction'
assert_not_contains 'sensitive-fixture@example.invalid' "$CHECK_OUTPUT" 'complete identity email redaction'
assert_file_empty "$complete_fixture/fetch.log" 'default complete check fetched'

default_fixture=$(make_fixture default-no-fetch)
snapshot_fixture "$default_fixture" "$TEST_ROOT/default.before"
run_check "$default_fixture"
snapshot_fixture "$default_fixture" "$TEST_ROOT/default.after"
assert_zero "$CHECK_STATUS" 'read-only default check'
assert_file_empty "$default_fixture/fetch.log" 'default mode invoked fetch'
assert_eq "$(cat "$TEST_ROOT/default.before")" "$(cat "$TEST_ROOT/default.after")" 'default mode mutated fixture files or refs'

fetch_fixture=$(make_fixture fetch-only)
printf 'local branch change\n' >> "$fetch_fixture/home/.zshenv"
fixture_git "$fetch_fixture" add .zshenv
fixture_git "$fetch_fixture" commit -S -q -m 'local signed change'
printf 'remote branch change\n' >> "$fetch_fixture/source/.zshenv"
/usr/bin/git -C "$fetch_fixture/source" add .zshenv
/usr/bin/git -C "$fetch_fixture/source" commit -S -q -m 'remote signed change'
/usr/bin/git -C "$fetch_fixture/source" push -q "$fetch_fixture/remote.git" main
head_before=$(fixture_git "$fetch_fixture" rev-parse HEAD)
remote_tracking_before=$(fixture_git "$fetch_fixture" rev-parse refs/remotes/origin/main)
run_check "$fetch_fixture"
assert_zero "$CHECK_STATUS" 'diverged fixture default check'
assert_eq "$remote_tracking_before" "$(fixture_git "$fetch_fixture" rev-parse refs/remotes/origin/main)" 'default mode updated remote-tracking ref'
assert_file_empty "$fetch_fixture/fetch.log" 'diverged default mode invoked fetch'
run_check "$fetch_fixture" --fetch
assert_zero "$CHECK_STATUS" 'fetch mode check'
assert_contains 'fetch --prune origin' "$(cat "$fetch_fixture/fetch.log")" 'fetch mode invocation'
assert_eq 1 "$(grep -c 'fetch --prune origin' "$fetch_fixture/fetch.log")" 'fetch mode invocation count'
assert_contains 'ahead 1' "$CHECK_OUTPUT" 'fetch mode ahead report'
assert_contains 'behind 1' "$CHECK_OUTPUT" 'fetch mode behind report'
assert_eq "$head_before" "$(fixture_git "$fetch_fixture" rev-parse HEAD)" 'fetch mode integrated commits'

signer_fixture=$(make_fixture signer-errors)
printf '# no usable signer\nmalformed signer line\n' > "$signer_fixture/home/.config/git/allowed_signers.local"
run_check "$signer_fixture"
assert_nonzero "$CHECK_STATUS" 'malformed signer check'
assert_contains 'FAIL:' "$CHECK_OUTPUT" 'malformed signer result'
public_key=$(awk '{print $2}' "$signer_fixture/home/.ssh/id_ed25519.pub")
/usr/bin/ssh-keygen -q -t ed25519 -N '' -f "$signer_fixture/mismatched-key"
mismatched_key=$(awk '{print $2}' "$signer_fixture/mismatched-key.pub")
printf 'sensitive-fixture@example.invalid ssh-ed25519 %s\n' "$mismatched_key" > "$signer_fixture/home/.config/git/allowed_signers.local"
run_check "$signer_fixture"
assert_nonzero "$CHECK_STATUS" 'mismatched signer key check'
printf 'different@example.invalid ssh-ed25519 %s\n' "$public_key" > "$signer_fixture/home/.config/git/allowed_signers.local"
run_check "$signer_fixture"
assert_nonzero "$CHECK_STATUS" 'mismatched signer principal check'
rm "$signer_fixture/home/.ssh/id_ed25519.pub"
run_check "$signer_fixture"
assert_nonzero "$CHECK_STATUS" 'missing public key check'
assert_not_contains "$public_key" "$CHECK_OUTPUT" 'public key redaction'

dirty_fixture=$(make_fixture dirty)
printf 'unstaged change\n' >> "$dirty_fixture/home/.zshenv"
printf 'staged change\n' >> "$dirty_fixture/home/.config/zsh/.zshrc"
fixture_git "$dirty_fixture" add .config/zsh/.zshrc
printf 'unrelated secret\n' > "$dirty_fixture/home/unrelated-untracked-secret"
run_check "$dirty_fixture"
assert_nonzero "$CHECK_STATUS" 'tracked and staged changes check'
assert_contains 'FAIL:' "$CHECK_OUTPUT" 'dirty result'
assert_not_contains 'unrelated-untracked-secret' "$CHECK_OUTPUT" 'untracked path enumeration'
assert_not_contains 'unrelated secret' "$CHECK_OUTPUT" 'untracked value enumeration'

syntax_fixture=$(make_fixture syntax-targets)
printf 'if\n' >> "$syntax_fixture/home/.zprofile"
run_check "$syntax_fixture"
assert_nonzero "$CHECK_STATUS" 'root Zsh profile syntax check'
assert_contains 'FAIL: a tracked Zsh file failed syntax checking' "$CHECK_OUTPUT" 'root Zsh profile syntax result'
fixture_git "$syntax_fixture" checkout -- .zprofile
printf 'if\n' >> "$syntax_fixture/home/.config/dotfiles/tests/run"
run_check "$syntax_fixture"
assert_nonzero "$CHECK_STATUS" 'extensionless dotfiles runner syntax check'
assert_contains 'FAIL: a tracked dotfiles Bash script failed syntax checking' "$CHECK_OUTPUT" 'extensionless runner syntax result'

untracked_fixture=$(make_fixture untracked)
printf 'unrelated secret\n' > "$untracked_fixture/home/unrelated-untracked-secret"
run_check "$untracked_fixture"
assert_zero "$CHECK_STATUS" 'unrelated untracked file check'
assert_not_contains 'unrelated-untracked-secret' "$CHECK_OUTPUT" 'untracked file output'

optional_fixture=$(make_fixture optional-tools)
make_optional_tool_wrappers "$optional_fixture"
printf 'brew "fixture"\n' > "$optional_fixture/home/.Brewfile"
run_check "$optional_fixture"
assert_zero "$CHECK_STATUS" 'optional tool success and warning checks'
optional_log=$(cat "$optional_fixture/optional-tools.log")
assert_contains 'nvim|-i NONE --headless +qa' "$optional_log" 'nvim isolated invocation'
assert_contains 'tmux|-L dotfiles-check-' "$optional_log" 'tmux isolated socket invocation'
assert_contains 'new-session -d -s dotfiles-check-' "$optional_log" 'tmux detached session invocation'
assert_contains 'kill-server' "$optional_log" 'tmux cleanup invocation'
assert_contains "gitleaks|git --no-banner --redact=100 --log-level warn $optional_fixture/home/.cfg" "$optional_log" 'gitleaks redacted invocation'
assert_contains "brew|1|bundle check --file=$optional_fixture/home/.Brewfile" "$optional_log" 'brew no-update invocation'
assert_contains 'WARN: Brewfile dependencies are not fully satisfied' "$CHECK_OUTPUT" 'unsatisfied Brewfile warning'

hostile_fixture=$(make_fixture hostile)
run_hostile_check "$hostile_fixture"
assert_zero "$CHECK_STATUS" 'hostile Git config sanitization'
assert_not_contains 'Hostile Name' "$CHECK_OUTPUT" 'hostile identity name redaction'
assert_not_contains 'hostile@example.invalid' "$CHECK_OUTPUT" 'hostile identity email redaction'
assert_not_contains 'parameters@example.invalid' "$CHECK_OUTPUT" 'parameter identity email redaction'
run_hostile_check "$hostile_fixture" 08
assert_zero "$CHECK_STATUS" 'noncanonical hostile Git config count sanitization'

run_check "$complete_fixture" --unknown
assert_nonzero "$CHECK_STATUS" 'unknown argument check'
run_check "$complete_fixture" --fetch --help
assert_nonzero "$CHECK_STATUS" 'multiple argument check'
run_check "$complete_fixture" --help
assert_zero "$CHECK_STATUS" 'help argument check'
assert_contains 'Usage:' "$CHECK_OUTPUT" 'help output'

printf 'PASS: dotfiles checks\n'
