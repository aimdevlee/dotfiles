#!/bin/bash
set -euo pipefail

script_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
source "$script_dir/test_helpers.sh"

work_tree=$(/usr/bin/git -C "$script_dir" rev-parse --show-toplevel)
check_script="$work_tree/.config/dotfiles/check"
lib_script="$work_tree/.config/dotfiles/lib.sh"
bootstrap_script="$work_tree/.config/dotfiles/bootstrap"

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

assert_file_absent() {
  local path=$1
  local message=$2

  [[ ! -e $path ]] || fail "$message: unexpected path [$path]"
}

make_runtime_path() {
  local fixture=$1
  local bin_dir="$fixture/bin"
  local tool

  mkdir -p "$bin_dir"
  for tool in awk basename dirname find grep mkdir sed shasum ssh-keygen uname zsh; do
    if [[ -x /usr/bin/$tool ]]; then
      ln -s "/usr/bin/$tool" "$bin_dir/$tool"
    elif [[ -x /bin/$tool ]]; then
      ln -s "/bin/$tool" "$bin_dir/$tool"
    fi
  done

  printf '%s\n' \
    '#!/bin/bash' \
    ': > "${DOTFILES_TEST_HOSTILE_PATH_MARKER:?}"' \
    'exec /usr/bin/git "$@"' > "$bin_dir/git"
  printf '%s\n' \
    '#!/bin/bash' \
    ': > "${DOTFILES_TEST_HOSTILE_PATH_MARKER:?}"' \
    'exec /bin/bash "$@"' > "$bin_dir/bash"
  chmod +x "$bin_dir/git" "$bin_dir/bash"
}

make_optional_tool_wrappers() {
  local fixture=$1
  local bin_dir="$fixture/bin"

  : > "$fixture/optional-tools.log"
  printf '%s\n' \
    '#!/bin/bash' \
    'wrapper_dir=$(cd -P -- "${0%/*}" && pwd)' \
    'log=${wrapper_dir%/bin}/optional-tools.log' \
    '[[ -L $XDG_CONFIG_HOME/nvim ]] || exit 91' \
    '[[ -f $XDG_DATA_HOME/nvim/lazy/lazy.nvim/lua/lazy/init.lua ]] || exit 93' \
    'printf "nvim|%s|HOME=%s\n" "$*" "${HOME:-}" >> "$log"' \
    'if /usr/bin/grep -q "INVALID_NVIM_FIXTURE" "$XDG_CONFIG_HOME/nvim/init.lua"; then' \
    '  case " $* " in *"vim.v.errmsg"*"cquit"*) exit 1 ;; *) exit 0 ;; esac' \
    'fi' \
    'if /usr/bin/grep -q "NVIM_DIAGNOSTIC_FIXTURE" "$XDG_CONFIG_HOME/nvim/init.lua"; then' \
    '  printf "Error detected while processing fixture\n" >&2' \
    'fi' \
    'exit 0' > "$bin_dir/nvim"
  printf '%s\n' \
    '#!/bin/bash' \
    'wrapper_dir=$(cd -P -- "${0%/*}" && pwd)' \
    'log=${wrapper_dir%/bin}/optional-tools.log' \
    'printf "tmux|%s|HOME=%s|XDG_CONFIG_HOME=%s|XDG_STATE_HOME=%s|XDG_CACHE_HOME=%s|ZDOTDIR=%s|TMUX_TMPDIR=%s|SHELL=%s|PATH=%s|TERM=%s\n" "$*" "${HOME:-}" "${XDG_CONFIG_HOME:-}" "${XDG_STATE_HOME:-}" "${XDG_CACHE_HOME:-}" "${ZDOTDIR:-}" "${TMUX_TMPDIR:-}" "${SHELL:-}" "${PATH:-}" "${TERM:-}" >> "$log"' \
    'case " $* " in *" new-session "*) "${SHELL:-/bin/sh}" -c ":"; exit $? ;; esac' \
    'case " $* " in *" source-file "*)' \
    '  config_file=' \
    '  for argument in "$@"; do config_file=$argument; done' \
    '  /usr/bin/grep -q "unknown-fixture-command" "$config_file" && exit 1' \
    '  exit 0' \
    ';; esac' \
    'exit 0' > "$bin_dir/tmux"
  printf '%s\n' \
    '#!/bin/bash' \
    'wrapper_dir=$(cd -P -- "${0%/*}" && pwd)' \
    'log=${wrapper_dir%/bin}/optional-tools.log' \
    'printf "gitleaks|%s\n" "$*" >> "$log"' \
    'exit 0' > "$bin_dir/gitleaks"
  printf '%s\n' \
    '#!/bin/bash' \
    'wrapper_dir=$(cd -P -- "${0%/*}" && pwd)' \
    'log=${wrapper_dir%/bin}/optional-tools.log' \
    'printf "brew|%s|%s\n" "${HOMEBREW_NO_AUTO_UPDATE:-}" "$*" >> "$log"' \
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

run_sanitized_git() {
  local fixture_home=$1
  shift

  /usr/bin/env -i \
    HOME="$fixture_home" \
    XDG_CONFIG_HOME="$fixture_home/.config" \
    PATH=/usr/bin:/bin \
    LC_ALL=C \
    TMPDIR="$TEST_ROOT/git-tmp" \
    GIT_CONFIG_NOSYSTEM=1 \
    /usr/bin/git -c core.hooksPath=/dev/null "$@"
}

fixture_source_git() {
  local fixture=$1
  shift

  run_sanitized_git "$fixture/git-home" -C "$fixture/source" "$@"
}

configure_signing_repo() {
  local fixture=$1
  local public_key=$2

  fixture_source_git "$fixture" config user.name 'Sensitive Fixture Name'
  fixture_source_git "$fixture" config user.email 'sensitive-fixture@example.invalid'
  fixture_source_git "$fixture" config user.signingKey "$public_key"
  fixture_source_git "$fixture" config gpg.format ssh
  fixture_source_git "$fixture" config commit.gpgSign true
}

make_fixture() {
  local name=$1
  local fixture="$TEST_ROOT/$name"
  local home="$fixture/home"
  local source_repo="$fixture/source"
  local remote_repo="$fixture/remote.git"
  local public_key

  case $name in
    ''|*/*) return 1 ;;
  esac
  FIXTURE=$fixture
  mkdir -p "$TEST_ROOT/git-tmp" "$fixture/git-home" "$home/.ssh" "$source_repo"
  /usr/bin/ssh-keygen -q -t ed25519 -N '' -f "$home/.ssh/id_ed25519"
  public_key=$(awk '{print $2}' "$home/.ssh/id_ed25519.pub")
  write_common_config "$home"
  write_local_config "$home"
  printf 'sensitive-fixture@example.invalid ssh-ed25519 %s fixture-comment\n' "$public_key" \
    > "$home/.config/git/allowed_signers.local"

  run_sanitized_git "$fixture/git-home" init -q -b main "$source_repo"
  configure_signing_repo "$fixture" "$home/.ssh/id_ed25519.pub"
  mkdir -p "$source_repo/.config/zsh" "$source_repo/.config/nvim" "$source_repo/.config/tmux" \
    "$source_repo/.config/tmux-sessionizer" "$source_repo/.config/dotfiles/tests" "$source_repo/.local/bin"
  printf '.cfg/\n' > "$source_repo/.gitignore"
  printf 'export FIXTURE=1\n' > "$source_repo/.zshenv"
  printf 'typeset -g FIXTURE_PROFILE=1\n' > "$source_repo/.zprofile"
  printf 'typeset -g FIXTURE_RC=1\n' > "$source_repo/.zshrc"
  printf 'typeset -g FIXTURE=1\n' > "$source_repo/.config/zsh/.zshrc"
  printf 'vim.g.fixture = true\n' > "$source_repo/.config/nvim/init.lua"
  printf 'set -g status off\n' > "$source_repo/.config/tmux/tmux.conf"
  printf '#!/bin/bash\nprintf "fixture bootstrap\\n"\n' > "$source_repo/.config/dotfiles/bootstrap"
  printf '#!/usr/bin/env bash\nprintf "fixture test runner\\n"\n' > "$source_repo/.config/dotfiles/tests/run"
  printf '#!/usr/bin/env bash\nprintf "fixture\\n"\n' > "$source_repo/.local/bin/tmux-sessionizer"
  chmod +x "$source_repo/.config/dotfiles/bootstrap" "$source_repo/.config/dotfiles/tests/run" \
    "$source_repo/.local/bin/tmux-sessionizer"
  fixture_source_git "$fixture" add .
  fixture_source_git "$fixture" commit -S -q -m 'signed fixture head'

  run_sanitized_git "$fixture/git-home" clone --bare -q "$source_repo" "$remote_repo"
  run_sanitized_git "$fixture/git-home" clone --bare -q "$remote_repo" "$home/.cfg"
  run_sanitized_git "$fixture/git-home" --git-dir="$home/.cfg" config remote.origin.fetch '+refs/heads/*:refs/remotes/origin/*'
  run_sanitized_git "$fixture/git-home" --git-dir="$home/.cfg" config branch.main.remote origin
  run_sanitized_git "$fixture/git-home" --git-dir="$home/.cfg" config branch.main.merge refs/heads/main
  run_sanitized_git "$fixture/git-home" --git-dir="$home/.cfg" fetch -q origin
  run_sanitized_git "$fixture/git-home" --git-dir="$home/.cfg" --work-tree="$home" checkout -q -f main

  make_runtime_path "$fixture"
}

make_bootstrapped_fixture() {
  local fixture="$TEST_ROOT/bootstrap-real-check"
  local home="$fixture/home"
  local source_repo="$fixture/source"
  local remote_repo="$fixture/remote.git"
  local public_key
  local bootstrap_output="$fixture.bootstrap-output"
  local bootstrap_status

  FIXTURE=$fixture
  mkdir -p "$TEST_ROOT/git-tmp" "$fixture/git-home" "$home/.ssh" "$source_repo"
  /usr/bin/ssh-keygen -q -t ed25519 -N '' -f "$home/.ssh/id_ed25519"
  public_key=$(awk '{print $2}' "$home/.ssh/id_ed25519.pub")
  write_common_config "$home"
  write_local_config "$home"
  printf 'sensitive-fixture@example.invalid ssh-ed25519 %s fixture-comment\n' "$public_key" \
    > "$home/.config/git/allowed_signers.local"

  run_sanitized_git "$fixture/git-home" init -q -b main "$source_repo"
  configure_signing_repo "$fixture" "$home/.ssh/id_ed25519.pub"
  mkdir -p "$source_repo/.config/dotfiles/tests" "$source_repo/.config/git" "$source_repo/.config/nvim" \
    "$source_repo/.config/tmux" "$source_repo/.config/tmux-sessionizer" "$source_repo/.config/zsh" \
    "$source_repo/.local/bin"
  cp "$bootstrap_script" "$source_repo/.config/dotfiles/bootstrap"
  cp "$check_script" "$source_repo/.config/dotfiles/check"
  cp "$lib_script" "$source_repo/.config/dotfiles/lib.sh"
  printf '%s\n' \
    '[user]' \
    '  useConfigOnly = true' \
    '[include]' \
    '  path = ~/.gitconfig.local' \
    '[gpg]' \
    '  format = ssh' \
    '[commit]' \
    '  gpgsign = true' > "$source_repo/.config/git/config"
  printf '.cfg/\n' > "$source_repo/.gitignore"
  printf 'export FIXTURE=1\n' > "$source_repo/.zshenv"
  printf 'typeset -g FIXTURE_PROFILE=1\n' > "$source_repo/.zprofile"
  printf 'typeset -g FIXTURE_RC=1\n' > "$source_repo/.zshrc"
  printf 'typeset -g FIXTURE=1\n' > "$source_repo/.config/zsh/.zshrc"
  printf 'vim.g.fixture = true\n' > "$source_repo/.config/nvim/init.lua"
  printf 'set -g status off\n' > "$source_repo/.config/tmux/tmux.conf"
  printf '#!/usr/bin/env bash\nprintf "fixture test runner\\n"\n' > "$source_repo/.config/dotfiles/tests/run"
  printf '#!/usr/bin/env bash\nprintf "fixture\\n"\n' > "$source_repo/.local/bin/tmux-sessionizer"
  chmod +x "$source_repo/.config/dotfiles/bootstrap" "$source_repo/.config/dotfiles/check" \
    "$source_repo/.config/dotfiles/tests/run" "$source_repo/.local/bin/tmux-sessionizer"
  fixture_source_git "$fixture" add .
  fixture_source_git "$fixture" commit -S -q -m 'signed bootstrap check fixture head'
  run_sanitized_git "$fixture/git-home" clone --bare -q "$source_repo" "$remote_repo"

  set +e
  /usr/bin/env -i \
    HOME="$home" \
    PATH=/usr/bin:/bin \
    LC_ALL=C \
    TMPDIR="$TEST_ROOT/git-tmp" \
    DOTFILES_REMOTE="$remote_repo" \
    DOTFILES_SOURCE="$remote_repo" \
    DOTFILES_GIT_DIR="$home/.cfg" \
    DOTFILES_WORK_TREE="$home" \
    XDG_STATE_HOME="$home/.state" \
    DOTFILES_SKIP_PLATFORM_CHECK=1 \
    "$bootstrap_script" --yes > "$bootstrap_output" 2>&1
  bootstrap_status=$?
  set -e
  assert_zero "$bootstrap_status" "real bootstrap before real check: $(cat "$bootstrap_output")"

  make_runtime_path "$fixture"
  make_optional_tool_wrappers "$fixture"
}

run_check() {
  local fixture=$1
  shift
  local home="$fixture/home"
  local output="$fixture.check-output"
  local status

  mkdir -p "$TEST_ROOT/run-cwd"
  set +e
  (
    cd "$TEST_ROOT/run-cwd" || exit 1
    env -i \
      HOME="$home" \
      XDG_CONFIG_HOME="$home/.config" \
      PATH="$fixture/bin" \
      LC_ALL=C \
      TMPDIR="${DOTFILES_TEST_TMPDIR:-${TMPDIR:-/tmp}}" \
      DOTFILES_GIT_DIR="$home/.cfg" \
      DOTFILES_WORK_TREE="$home" \
      DOTFILES_SKIP_PLATFORM_CHECK=1 \
      DOTFILES_TEST_HOSTILE_PATH_MARKER="$fixture/hostile-path-marker" \
      DOTFILES_TEST_OPTIONAL_LOG="$fixture/optional-tools.log" \
      DOTFILES_TEST_EXPECTED_NVIM_CONFIG="$home/.config/nvim/init.lua" \
      SHELL="${DOTFILES_TEST_SHELL:-/bin/sh}" \
      ZDOTDIR="${DOTFILES_TEST_ZDOTDIR:-$TEST_ROOT/no-zdotdir}" \
      DOTFILES_TEST_ZDOT_MARKER="${DOTFILES_TEST_ZDOT_MARKER:-$TEST_ROOT/no-zdot-marker}" \
      TERM=xterm-256color \
      "$check_script" "$@"
  ) > "$output" 2>&1
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
    DOTFILES_TEST_HOSTILE_PATH_MARKER="$fixture/hostile-path-marker" \
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

  run_sanitized_git "$home" --git-dir="$home/.cfg" --work-tree="$home" "$@"
}

snapshot_fixture() {
  local fixture=$1
  local destination=$2

  (
    cd "$fixture"
    find . -type f -print | LC_ALL=C sort | while IFS= read -r path; do
      shasum -a 256 "$path"
    done
    run_sanitized_git "$fixture/git-home" --git-dir="$fixture/home/.cfg" show-ref
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

if make_fixture ''; then
  fail 'fixture creation accepted an empty fixture name'
fi

ambient_hooks="$TEST_ROOT/ambient-hooks"
ambient_config="$TEST_ROOT/ambient.gitconfig"
ambient_hook_marker="$TEST_ROOT/ambient-hook-ran"
mkdir -p "$ambient_hooks"
printf '%s\n' '#!/bin/bash' ': > "${DOTFILES_TEST_AMBIENT_HOOK_MARKER:?}"' > "$ambient_hooks/pre-commit"
chmod +x "$ambient_hooks/pre-commit"
printf '%s\n' '[core]' "  hooksPath = $ambient_hooks" '[user]' '  name = Ambient Attacker' > "$ambient_config"
GIT_CONFIG_GLOBAL="$ambient_config" \
  DOTFILES_TEST_AMBIENT_HOOK_MARKER="$ambient_hook_marker" \
  make_fixture ambient-hooks
ambient_fixture=$FIXTURE
assert_file_absent "$ambient_hook_marker" 'fixture creation executed an ambient Git hook'

make_fixture missing-identity
missing_identity_fixture=$FIXTURE
rm "$missing_identity_fixture/home/.gitconfig.local"
run_check "$missing_identity_fixture"
assert_nonzero "$CHECK_STATUS" 'missing local identity check'
assert_contains 'FAIL:' "$CHECK_OUTPUT" 'missing identity result'
assert_not_contains 'Sensitive Fixture Name' "$CHECK_OUTPUT" 'identity name redaction'
assert_not_contains 'sensitive-fixture@example.invalid' "$CHECK_OUTPUT" 'identity email redaction'
assert_file_absent "$missing_identity_fixture/hostile-path-marker" 'missing-identity check invoked hostile PATH bash/git'

make_fixture complete
complete_fixture=$FIXTURE
run_check "$complete_fixture"
assert_zero "$CHECK_STATUS" 'complete fixture check'
assert_contains 'PASS:' "$CHECK_OUTPUT" 'complete fixture pass output'
assert_contains 'WARN:' "$CHECK_OUTPUT" 'platform skip warning'
assert_contains '0 FAIL' "$CHECK_OUTPUT" 'complete fixture summary'
assert_not_contains 'Sensitive Fixture Name' "$CHECK_OUTPUT" 'complete identity name redaction'
assert_not_contains 'sensitive-fixture@example.invalid' "$CHECK_OUTPUT" 'complete identity email redaction'
assert_file_absent "$complete_fixture/hostile-path-marker" 'complete check invoked hostile PATH bash/git'

make_fixture default-no-fetch
default_fixture=$FIXTURE
snapshot_fixture "$default_fixture" "$TEST_ROOT/default.before"
run_check "$default_fixture"
snapshot_fixture "$default_fixture" "$TEST_ROOT/default.after"
assert_zero "$CHECK_STATUS" 'read-only default check'
assert_file_absent "$default_fixture/hostile-path-marker" 'default mode invoked hostile PATH bash/git'
assert_eq "$(cat "$TEST_ROOT/default.before")" "$(cat "$TEST_ROOT/default.after")" 'default mode mutated fixture files or refs'

make_bootstrapped_fixture
bootstrapped_fixture=$FIXTURE
bootstrapped_head=$(fixture_git "$bootstrapped_fixture" rev-parse HEAD)
assert_eq origin "$(fixture_git "$bootstrapped_fixture" config --get branch.main.remote)" \
  'real bootstrap configures branch remote without fixture seeding'
assert_eq refs/heads/main "$(fixture_git "$bootstrapped_fixture" config --get branch.main.merge)" \
  'real bootstrap configures branch merge without fixture seeding'
assert_eq "$bootstrapped_head" "$(fixture_git "$bootstrapped_fixture" rev-parse refs/remotes/origin/main)" \
  'real bootstrap initializes upstream remote-tracking ref without fetching'
run_check "$bootstrapped_fixture"
assert_zero "$CHECK_STATUS" 'fresh real bootstrap passes real default check'
assert_contains 'PASS: upstream is configured' "$CHECK_OUTPUT" 'fresh real bootstrap upstream configuration result'
assert_contains 'ahead 0' "$CHECK_OUTPUT" 'fresh real bootstrap upstream ahead result'
assert_contains 'behind 0' "$CHECK_OUTPUT" 'fresh real bootstrap upstream behind result'

make_fixture fetch-only
fetch_fixture=$FIXTURE
printf 'local branch change\n' >> "$fetch_fixture/home/.zshenv"
fixture_git "$fetch_fixture" add .zshenv
fixture_git "$fetch_fixture" commit -S -q -m 'local signed change'
printf 'remote branch change\n' >> "$fetch_fixture/source/.zshenv"
fixture_source_git "$fetch_fixture" add .zshenv
fixture_source_git "$fetch_fixture" commit -S -q -m 'remote signed change'
fixture_source_git "$fetch_fixture" push -q "$fetch_fixture/remote.git" main
head_before=$(fixture_git "$fetch_fixture" rev-parse HEAD)
remote_tracking_before=$(fixture_git "$fetch_fixture" rev-parse refs/remotes/origin/main)
run_check "$fetch_fixture"
assert_zero "$CHECK_STATUS" 'diverged fixture default check'
assert_eq "$remote_tracking_before" "$(fixture_git "$fetch_fixture" rev-parse refs/remotes/origin/main)" 'default mode updated remote-tracking ref'
assert_file_absent "$fetch_fixture/hostile-path-marker" 'diverged default mode invoked hostile PATH bash/git'
run_check "$fetch_fixture" --fetch
assert_zero "$CHECK_STATUS" 'fetch mode check'
assert_contains 'ahead 1' "$CHECK_OUTPUT" 'fetch mode ahead report'
assert_contains 'behind 1' "$CHECK_OUTPUT" 'fetch mode behind report'
assert_eq "$head_before" "$(fixture_git "$fetch_fixture" rev-parse HEAD)" 'fetch mode integrated commits'
assert_file_absent "$fetch_fixture/hostile-path-marker" 'fetch mode invoked hostile PATH bash/git'

make_fixture fetch-recreates-upstream
missing_upstream_ref_fixture=$FIXTURE
fixture_git "$missing_upstream_ref_fixture" update-ref -d refs/remotes/origin/main
run_check "$missing_upstream_ref_fixture" --fetch
assert_zero "$CHECK_STATUS" 'fetch recreates missing upstream remote-tracking ref'
assert_contains 'PASS: upstream is configured' "$CHECK_OUTPUT" 'configured upstream before fetch'
assert_contains 'ahead 0' "$CHECK_OUTPUT" 'recreated upstream ahead report'
assert_contains 'behind 0' "$CHECK_OUTPUT" 'recreated upstream behind report'
fixture_git "$missing_upstream_ref_fixture" rev-parse --verify refs/remotes/origin/main >/dev/null

make_fixture signer-errors
signer_fixture=$FIXTURE
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

make_fixture signer-comment-confusion
comment_key_fixture=$FIXTURE
/usr/bin/ssh-keygen -q -t ed25519 -N '' -f "$comment_key_fixture/comment-key-b"
key_a=$(awk '{print $2}' "$comment_key_fixture/home/.ssh/id_ed25519.pub")
key_b=$(awk '{print $2}' "$comment_key_fixture/comment-key-b.pub")
printf 'signed by key B\n' >> "$comment_key_fixture/home/.zshenv"
fixture_git "$comment_key_fixture" add .zshenv
fixture_git "$comment_key_fixture" -c user.signingKey="$comment_key_fixture/comment-key-b.pub" commit -S -q -m 'signed by key B'
printf 'sensitive-fixture@example.invalid ssh-ed25519 %s misleading-comment ssh-ed25519 %s\n' "$key_b" "$key_a" \
  > "$comment_key_fixture/home/.config/git/allowed_signers.local"
run_check "$comment_key_fixture"
assert_nonzero "$CHECK_STATUS" 'allowed signer trailing-comment confusion check'
assert_contains 'FAIL: allowed signer does not match the effective identity and public key' "$CHECK_OUTPUT" \
  'allowed signer trailing-comment mismatch result'

make_fixture dirty
dirty_fixture=$FIXTURE
printf 'unstaged change\n' >> "$dirty_fixture/home/.zshenv"
printf 'staged change\n' >> "$dirty_fixture/home/.config/zsh/.zshrc"
fixture_git "$dirty_fixture" add .config/zsh/.zshrc
printf 'unrelated secret\n' > "$dirty_fixture/home/unrelated-untracked-secret"
run_check "$dirty_fixture"
assert_nonzero "$CHECK_STATUS" 'tracked and staged changes check'
assert_contains 'FAIL:' "$CHECK_OUTPUT" 'dirty result'
assert_not_contains 'unrelated-untracked-secret' "$CHECK_OUTPUT" 'untracked path enumeration'
assert_not_contains 'unrelated secret' "$CHECK_OUTPUT" 'untracked value enumeration'

make_fixture syntax-targets
syntax_fixture=$FIXTURE
printf 'if\n' >> "$syntax_fixture/home/.zprofile"
run_check "$syntax_fixture"
assert_nonzero "$CHECK_STATUS" 'root Zsh profile syntax check'
assert_contains 'FAIL: a tracked Zsh file failed syntax checking' "$CHECK_OUTPUT" 'root Zsh profile syntax result'
fixture_git "$syntax_fixture" checkout -- .zprofile
printf 'if\n' >> "$syntax_fixture/home/.local/bin/tmux-sessionizer"
run_check "$syntax_fixture"
assert_nonzero "$CHECK_STATUS" 'canonical tmux-sessionizer syntax check'
assert_contains 'FAIL: a tracked dotfiles Bash script failed syntax checking' "$CHECK_OUTPUT" 'canonical tmux-sessionizer syntax result'
fixture_git "$syntax_fixture" checkout -- .local/bin/tmux-sessionizer
printf 'if\n' >> "$syntax_fixture/home/.config/dotfiles/tests/run"
run_check "$syntax_fixture"
assert_nonzero "$CHECK_STATUS" 'extensionless dotfiles runner syntax check'
assert_contains 'FAIL: a tracked dotfiles Bash script failed syntax checking' "$CHECK_OUTPUT" 'extensionless runner syntax result'
fixture_git "$syntax_fixture" checkout -- .config/dotfiles/tests/run
printf 'if\n' >> "$syntax_fixture/home/.config/dotfiles/bootstrap"
run_check "$syntax_fixture"
assert_nonzero "$CHECK_STATUS" 'extensionless bootstrap syntax check'
assert_contains 'FAIL: a tracked dotfiles Bash script failed syntax checking' "$CHECK_OUTPUT" 'extensionless bootstrap syntax result'

make_fixture untracked
untracked_fixture=$FIXTURE
printf 'unrelated secret\n' > "$untracked_fixture/home/unrelated-untracked-secret"
run_check "$untracked_fixture"
assert_zero "$CHECK_STATUS" 'unrelated untracked file check'
assert_not_contains 'unrelated-untracked-secret' "$CHECK_OUTPUT" 'untracked file output'

make_fixture optional-tools
optional_fixture=$FIXTURE
make_optional_tool_wrappers "$optional_fixture"
printf 'brew "fixture"\n' > "$optional_fixture/home/.Brewfile"
malicious_zdotdir="$TEST_ROOT/malicious-zdotdir"
malicious_zdot_marker="$TEST_ROOT/malicious-zdot-ran"
mkdir -p "$malicious_zdotdir"
printf '%s\n' ': > "${DOTFILES_TEST_ZDOT_MARKER:?}"' > "$malicious_zdotdir/.zshenv"
DOTFILES_TEST_SHELL=/bin/zsh DOTFILES_TEST_ZDOTDIR="$malicious_zdotdir" \
  DOTFILES_TEST_ZDOT_MARKER="$malicious_zdot_marker" run_check "$optional_fixture"
assert_zero "$CHECK_STATUS" 'optional tool success and warning checks'
assert_file_absent "$malicious_zdot_marker" 'tmux startup executed inherited malicious ZDOTDIR'
optional_log=$(cat "$optional_fixture/optional-tools.log")
assert_contains 'nvim|-i NONE --headless' "$optional_log" 'nvim isolated invocation'
assert_contains 'vim.v.errmsg' "$optional_log" 'nvim startup error guard invocation'
assert_contains 'cquit' "$optional_log" 'nvim startup error guard exits nonzero'
assert_contains 'tmux|-S /tmp/dc-tmux.' "$optional_log" 'tmux explicit short socket invocation'
assert_contains '-f /dev/null new-session -d -s dotfiles-check-' "$optional_log" 'tmux safe detached session invocation'
assert_contains 'source-file' "$optional_log" 'tmux explicitly sources tracked config'
assert_contains 'kill-server' "$optional_log" 'tmux cleanup invocation'
assert_contains 'SHELL=/bin/sh' "$optional_log" 'tmux controlled shell environment'
assert_contains 'PATH=/usr/bin:/bin' "$optional_log" 'tmux controlled PATH environment'
assert_contains 'TMUX_TMPDIR=' "$optional_log" 'tmux isolated socket directory environment'
nvim_home=$(/usr/bin/awk -F'|' '$1 == "nvim" { sub(/^HOME=/, "", $3); print $3; exit }' "$optional_fixture/optional-tools.log")
tmux_home=$(/usr/bin/awk -F'|' '$1 == "tmux" && $2 ~ /new-session/ { sub(/^HOME=/, "", $3); print $3; exit }' \
  "$optional_fixture/optional-tools.log")
tmux_socket=$(/usr/bin/awk -F'|' '$1 == "tmux" && $2 ~ /new-session/ { split($2, args, " "); print args[2]; exit }' \
  "$optional_fixture/optional-tools.log")
[[ $tmux_socket == /tmp/dc-tmux.*/s ]] || fail "tmux socket is not rooted in a guarded short /tmp directory: [$tmux_socket]"
[[ ${#tmux_socket} -lt 100 ]] || fail "tmux socket path is too long: [${#tmux_socket}]"
assert_file_absent "${nvim_home%/home}" 'nvim isolated state cleanup'
assert_file_absent "${tmux_home%/home}" 'tmux isolated state cleanup'
assert_file_absent "${tmux_socket%/s}" 'tmux short socket directory cleanup'
assert_contains 'trap cleanup_runtime_state EXIT' "$(cat "$check_script")" 'EXIT cleanup trap structure'
assert_contains "trap 'handle_signal 130' INT" "$(cat "$check_script")" 'INT cleanup trap structure'
assert_contains "trap 'handle_signal 143' TERM" "$(cat "$check_script")" 'TERM cleanup trap structure'
assert_contains "gitleaks|git --no-banner --redact=100 --log-level warn $optional_fixture/home/.cfg" "$optional_log" 'gitleaks redacted invocation'
assert_contains "brew|1|bundle check --file=$optional_fixture/home/.Brewfile" "$optional_log" 'brew no-update invocation'
assert_contains 'WARN: Brewfile dependencies are not fully satisfied' "$CHECK_OUTPUT" 'unsatisfied Brewfile warning'

printf 'this is not valid lua -- INVALID_NVIM_FIXTURE\n' > "$optional_fixture/home/.config/nvim/init.lua"
run_check "$optional_fixture"
assert_nonzero "$CHECK_STATUS" 'fake nvim startup error check'
assert_contains 'FAIL: nvim headless startup failed' "$CHECK_OUTPUT" 'fake nvim startup error result'
fixture_git "$optional_fixture" checkout -- .config/nvim/init.lua
printf 'vim.g.fixture = true -- NVIM_DIAGNOSTIC_FIXTURE\n' > "$optional_fixture/home/.config/nvim/init.lua"
run_check "$optional_fixture"
assert_nonzero "$CHECK_STATUS" 'fake nvim error diagnostic check'
assert_contains 'FAIL: nvim headless startup failed' "$CHECK_OUTPUT" 'fake nvim diagnostic result'
fixture_git "$optional_fixture" checkout -- .config/nvim/init.lua

printf 'unknown-fixture-command\n' > "$optional_fixture/home/.config/tmux/tmux.conf"
run_check "$optional_fixture"
assert_nonzero "$CHECK_STATUS" 'fake tmux tracked config error check'
assert_contains 'FAIL: tmux tracked config failed to load' "$CHECK_OUTPUT" 'fake tmux tracked config error result'
fixture_git "$optional_fixture" checkout -- .config/tmux/tmux.conf

real_nvim=
for candidate in /opt/homebrew/bin/nvim /usr/local/bin/nvim /usr/bin/nvim; do
  if [[ -x $candidate ]]; then
    real_nvim=$candidate
    break
  fi
done
if [[ -n $real_nvim ]]; then
  make_fixture real-nvim-startup
  real_nvim_fixture=$FIXTURE
  ln -sf "$real_nvim" "$real_nvim_fixture/bin/nvim"
  run_check "$real_nvim_fixture"
  assert_zero "$CHECK_STATUS" 'real nvim valid isolated startup check'
  printf 'this is not valid lua -- INVALID_NVIM_FIXTURE\n' > "$real_nvim_fixture/home/.config/nvim/init.lua"
  run_check "$real_nvim_fixture"
  assert_nonzero "$CHECK_STATUS" 'real nvim invalid init must fail although plain headless exits zero'
  assert_contains 'FAIL: nvim headless startup failed' "$CHECK_OUTPUT" 'real nvim invalid init result'
fi

real_tmux=
for candidate in /opt/homebrew/bin/tmux /usr/local/bin/tmux /usr/bin/tmux; do
  if [[ -x $candidate ]]; then
    real_tmux=$candidate
    break
  fi
done
if [[ -n $real_tmux ]]; then
  make_fixture real-tmux-long-tmp
  real_tmux_fixture=$FIXTURE
  ln -sf "$real_tmux" "$real_tmux_fixture/bin/tmux"
  long_tmux_tmp="$TEST_ROOT/long-macos-style-tmp/aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"
  mkdir -p "$long_tmux_tmp"
  short_tmux_before=$(/usr/bin/find /tmp -maxdepth 1 -type d -name 'dc-tmux.*' -print | LC_ALL=C sort)
  DOTFILES_TEST_TMPDIR="$long_tmux_tmp" run_check "$real_tmux_fixture"
  assert_zero "$CHECK_STATUS" 'real tmux with long macOS TMPDIR check'
  assert_contains 'PASS: tmux loads tracked config on an isolated socket' "$CHECK_OUTPUT" 'real tmux config load result'
  short_tmux_after=$(/usr/bin/find /tmp -maxdepth 1 -type d -name 'dc-tmux.*' -print | LC_ALL=C sort)
  assert_eq "$short_tmux_before" "$short_tmux_after" 'real tmux left a short socket directory'
  printf 'unknown-fixture-command\n' > "$real_tmux_fixture/home/.config/tmux/tmux.conf"
  DOTFILES_TEST_TMPDIR="$long_tmux_tmp" run_check "$real_tmux_fixture"
  assert_nonzero "$CHECK_STATUS" 'real tmux unknown tracked command check'
  assert_contains 'FAIL: tmux tracked config failed to load' "$CHECK_OUTPUT" 'real tmux unknown tracked command result'
fi

make_fixture "wrapper-'; : > wrapper-injected; #"
wrapper_injection_fixture=$FIXTURE
make_optional_tool_wrappers "$wrapper_injection_fixture"
malicious_tmp="$TEST_ROOT/tmp-'; : > tmp-injected; #"
mkdir -p "$malicious_tmp"
run_check "$wrapper_injection_fixture"
assert_file_absent "$TEST_ROOT/run-cwd/wrapper-injected" 'generated wrapper executed interpolated fixture source'
DOTFILES_TEST_TMPDIR="$malicious_tmp" run_check "$optional_fixture"
assert_zero "$CHECK_STATUS" 'quoted TMPDIR check'
assert_file_absent "$TEST_ROOT/run-cwd/tmp-injected" 'TMPDIR text executed as shell source'

make_fixture hostile
hostile_fixture=$FIXTURE
run_hostile_check "$hostile_fixture"
assert_zero "$CHECK_STATUS" 'hostile Git config sanitization'
assert_not_contains 'Hostile Name' "$CHECK_OUTPUT" 'hostile identity name redaction'
assert_not_contains 'hostile@example.invalid' "$CHECK_OUTPUT" 'hostile identity email redaction'
assert_not_contains 'parameters@example.invalid' "$CHECK_OUTPUT" 'parameter identity email redaction'
run_hostile_check "$hostile_fixture" 08
assert_zero "$CHECK_STATUS" 'noncanonical hostile Git config count sanitization'
run_hostile_check "$hostile_fixture" 999999999999999999999999999
assert_zero "$CHECK_STATUS" 'huge hostile Git config count sanitization'

run_check "$complete_fixture" --unknown
assert_nonzero "$CHECK_STATUS" 'unknown argument check'
run_check "$complete_fixture" --fetch --help
assert_nonzero "$CHECK_STATUS" 'multiple argument check'
run_check "$complete_fixture" --help
assert_zero "$CHECK_STATUS" 'help argument check'
assert_contains 'Usage:' "$CHECK_OUTPUT" 'help output'

printf 'PASS: dotfiles checks\n'
