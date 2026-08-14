#!/usr/bin/env bash
set -euo pipefail

script_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
source "$script_dir/test_helpers.sh"

expected_work_tree=$(git -C "$script_dir" rev-parse --show-toplevel)
expected_repo_dir=$(git -C "$expected_work_tree" rev-parse --absolute-git-dir)

canonical_path() {
  (cd -P -- "$1" && pwd)
}

assert_auto_runner_context() {
  local actual_work_tree=$1
  local actual_repo_dir=$2

  [[ -n $actual_work_tree && -n $actual_repo_dir ]] || fail 'runner context is unset'
  assert_eq "$(canonical_path "$expected_work_tree")" "$(canonical_path "$actual_work_tree")" 'runner work tree' || return 1
  actual_repo_dir=$(git -C "$actual_work_tree" --git-dir="$actual_repo_dir" --work-tree="$actual_work_tree" rev-parse --absolute-git-dir) || return 1
  assert_eq "$(canonical_path "$expected_repo_dir")" "$(canonical_path "$actual_repo_dir")" 'runner git dir'
}

assert_explicit_runner_context() {
  local supplied_work_tree=$1
  local supplied_repo_dir=$2
  local derived_work_tree
  local derived_repo_dir
  local resolved_repo_dir

  [[ -n $supplied_work_tree && -n $supplied_repo_dir ]] || fail 'explicit runner context is unset'
  derived_work_tree=$(git -C "$supplied_work_tree" rev-parse --show-toplevel) || return 1
  assert_eq "$(canonical_path "$derived_work_tree")" "$(canonical_path "$supplied_work_tree")" 'explicit runner work tree' || return 1
  derived_repo_dir=$(git -C "$derived_work_tree" rev-parse --absolute-git-dir) || return 1
  resolved_repo_dir=$(git -C "$supplied_work_tree" --git-dir="$supplied_repo_dir" --work-tree="$supplied_work_tree" rev-parse --absolute-git-dir) || return 1
  assert_eq "$(canonical_path "$derived_repo_dir")" "$(canonical_path "$resolved_repo_dir")" 'explicit runner git dir'
}

case ${DOTFILES_TEST_CONTEXT_MODE:-} in
  auto) assert_auto_runner_context "$DOTFILES_WORK_TREE" "$DOTFILES_GIT_DIR" ;;
  explicit) assert_explicit_runner_context "$DOTFILES_WORK_TREE" "$DOTFILES_GIT_DIR" ;;
  *) fail 'runner context mode is unset or invalid' ;;
esac

if assert_auto_runner_context "$expected_work_tree" "$expected_work_tree" 2>/dev/null; then
  fail 'runner context accepted an incorrect git directory'
fi

(
  DOTFILES_WORK_TREE=/explicit/work-tree
  DOTFILES_GIT_DIR=/explicit/git-dir
  setup_dotfiles_test_context "$script_dir"
  assert_eq /explicit/work-tree "$DOTFILES_WORK_TREE" 'explicit work tree override'
  assert_eq /explicit/git-dir "$DOTFILES_GIT_DIR" 'explicit git dir override'
)

temp_base=${TMPDIR:-/tmp}
anchor=$(mktemp -d "$temp_base/dotfiles-test.anchor.XXXXXXXX")
outside=$(mktemp -d "$temp_base/dotfiles-outside.XXXXXXXX")

cleanup() {
  rm -rf -- "$anchor" "$outside"
}
trap cleanup EXIT

: > "$outside/.dotfiles-test-root"
: > "$outside/sentinel"
TEST_ROOT="$anchor/../$(basename "$outside")"
export TEST_ROOT

if cleanup_test_root 2>/dev/null; then
  fail 'cleanup_test_root accepted a traversal path'
fi

[[ -f $outside/sentinel ]] || fail 'cleanup_test_root traversed outside its test root'

make_test_root
valid_root=$TEST_ROOT
cleanup_test_root
[[ ! -e $valid_root ]] || fail 'cleanup_test_root did not remove a valid test root'

make_test_root
explicit_clone="$TEST_ROOT/explicit-clone"
init_fixture_repo
git clone -q "$TEST_ROOT/remote.git" "$explicit_clone"
assert_explicit_runner_context "$explicit_clone" "$explicit_clone/.git"
if assert_explicit_runner_context "$explicit_clone" "$expected_repo_dir" 2>/dev/null; then
  fail 'explicit runner context accepted a mismatched git directory'
fi
cleanup_test_root

make_test_root
ambient_work_tree="$TEST_ROOT/ambient-repo"
ambient_config="$TEST_ROOT/global.gitconfig"
ambient_excludes="$TEST_ROOT/global-excludes"
git init -q "$ambient_work_tree"
: > "$ambient_work_tree/.gitignore"
printf '.ambient-secret\n' > "$ambient_excludes"
git config -f "$ambient_config" core.excludesFile "$ambient_excludes"
if DOTFILES_GIT_DIR="$ambient_work_tree/.git" \
  DOTFILES_WORK_TREE="$ambient_work_tree" \
  GIT_CONFIG_GLOBAL="$ambient_config" \
  assert_ignored_by_worktree_policy "$ambient_work_tree/.git" "$ambient_work_tree" .ambient-secret >/dev/null 2>&1; then
  fail 'ignore_test accepted an ambient global exclude'
fi
cleanup_test_root

copy_zsh_startup_fixture() {
  local fixture_home=$1
  local missing_brew=$2

  mkdir -p "$fixture_home/.config/zsh" "$fixture_home/.cache" "$fixture_home/.local/share" "$fixture_home/.local/state"
  cp "$expected_work_tree/.zshenv" "$fixture_home/.zshenv"
  sed "s|/opt/homebrew/bin/brew|$missing_brew|g" \
    "$expected_work_tree/.config/zsh/.zprofile" > "$fixture_home/.config/zsh/.zprofile"
  printf '\nPATH=/usr/bin:/bin\nexport PATH\n' >> "$fixture_home/.config/zsh/.zprofile"
  cp "$expected_work_tree/.config/zsh/.zshrc" "$fixture_home/.config/zsh/.zshrc"
}

run_isolated_zsh_startup() {
  local fixture_home=$1
  local stdout_file=$2
  local stderr_file=$3
  local command=$4

  env -i \
    HOME="$fixture_home" \
    PATH=/usr/bin:/bin \
    /bin/zsh -lic "$command" >"$stdout_file" 2>"$stderr_file"
}

make_test_root
zsh_home="$TEST_ROOT/home"
zsh_stdout="$TEST_ROOT/zsh.stdout"
zsh_stderr="$TEST_ROOT/zsh.stderr"
missing_brew="$TEST_ROOT/no-optional-tools/brew"
copy_zsh_startup_fixture "$zsh_home" "$missing_brew"
no_optional_tools_command='for tool in brew eza fzf zoxide oh-my-posh direnv mise; do
  if (( $+commands[$tool] )); then
    print -u2 -- "unexpected optional tool: $tool"
    exit 1
  fi
done
print shell-loaded'

if ! run_isolated_zsh_startup "$zsh_home" "$zsh_stdout" "$zsh_stderr" "$no_optional_tools_command"; then
  fail "isolated zsh startup failed: $(cat "$zsh_stderr")"
fi
assert_eq 'shell-loaded' "$(cat "$zsh_stdout")" 'isolated zsh startup marker'
assert_eq '' "$(cat "$zsh_stderr")" 'isolated zsh startup stderr'

printf "export DOTFILES_LOCAL_LOADED=yes\nalias config='local-config'\n" > "$zsh_home/.config/zsh/.zshrc.local"
if ! run_isolated_zsh_startup "$zsh_home" "$zsh_stdout" "$zsh_stderr" 'print "$DOTFILES_LOCAL_LOADED"'; then
  fail "isolated local override startup failed: $(cat "$zsh_stderr")"
fi
assert_eq yes "$(cat "$zsh_stdout")" 'local zsh override'
assert_eq '' "$(cat "$zsh_stderr")" 'local zsh override stderr'
if ! run_isolated_zsh_startup "$zsh_home" "$zsh_stdout" "$zsh_stderr" 'print -r -- "$aliases[config]"'; then
  fail "isolated local override order startup failed: $(cat "$zsh_stderr")"
fi
assert_eq local-config "$(cat "$zsh_stdout")" 'local zsh override order'
assert_eq '' "$(cat "$zsh_stderr")" 'local zsh override order stderr'
cleanup_test_root

sessionizer="$expected_work_tree/.local/bin/tmux-sessionizer"
common_sessionizer_config="$expected_work_tree/.config/tmux-sessionizer/tmux-sessionizer.conf"
duplicate_sessionizer='.config/tmux-sessionizer/tmux-sessionizer'

assert_eq '.local/bin/tmux-sessionizer' "$(git -C "$expected_work_tree" ls-files --stage -- .local/bin/tmux-sessionizer | awk '{print $4}')" \
  'canonical tmux-sessionizer is tracked'
assert_eq 100755 "$(git -C "$expected_work_tree" ls-files --stage -- .local/bin/tmux-sessionizer | awk '{print $1}')" \
  'canonical tmux-sessionizer is executable'
tracked_sessionizers=()
while IFS=$'\t' read -r staged_entry staged_path; do
  [[ ${staged_entry%% *} == 100755 && ${staged_path##*/} == tmux-sessionizer ]] && tracked_sessionizers+=("$staged_path")
done < <(git -C "$expected_work_tree" ls-files --stage)
assert_eq '.local/bin/tmux-sessionizer' "${tracked_sessionizers[*]}" 'only canonical tmux-sessionizer executable is tracked'
if git -C "$expected_work_tree" ls-files --error-unmatch -- "$duplicate_sessionizer" >/dev/null 2>&1; then
  fail 'duplicate tmux-sessionizer executable remains tracked'
fi
[[ ! -e "$expected_work_tree/$duplicate_sessionizer" ]] || fail 'duplicate tmux-sessionizer executable remains present'
/bin/bash -n "$sessionizer" || fail 'canonical tmux-sessionizer fails Bash syntax checking'
assert_eq '# Define TS_SEARCH_PATHS in tmux-sessionizer.local.conf for machine-specific project roots.
TS_SEARCH_PATHS=()' "$(cat "$common_sessionizer_config")" 'common tmux-sessionizer config'
if git -C "$expected_work_tree" grep -n -E '(^|[^[:alnum:]_])(/Users/|~/|\$HOME/Developer)' -- .config/tmux-sessionizer/tmux-sessionizer.conf >/dev/null 2>&1; then
  fail 'common tmux-sessionizer config contains a personal path'
fi

expected_local_template='# Machine-local private tool initialization.
# Keep secrets out of this example and out of the dotfiles repository.
# source "$HOME/.config/company/shell.zsh"'
assert_eq "$expected_local_template" "$(cat "$expected_work_tree/.config/dotfiles/templates/zshrc.local.example")" 'local zsh template'

expected_sessionizer_template='# Machine-local project roots for tmux-sessionizer.
TS_SEARCH_PATHS=("$HOME/Developer:1")'
assert_eq "$expected_sessionizer_template" \
  "$(cat "$expected_work_tree/.config/dotfiles/templates/tmux-sessionizer.local.conf.example")" \
  'local tmux-sessionizer template'

make_test_root
if ! git -C "$expected_work_tree" check-ignore -v --no-index -- .config/tmux-sessionizer/tmux-sessionizer.local.conf > "$TEST_ROOT/sessionizer-ignore"; then
  fail 'tmux-sessionizer local config is not ignored'
fi
ignore_source=$(cut -f1 "$TEST_ROOT/sessionizer-ignore")
[[ $ignore_source == .gitignore:* ]] || fail "tmux-sessionizer local config must match root .gitignore, got [$ignore_source]"

sessionizer_home="$TEST_ROOT/sessionizer home"
sessionizer_bin="$TEST_ROOT/bin"
sessionizer_stdout="$TEST_ROOT/sessionizer.stdout"
sessionizer_stderr="$TEST_ROOT/sessionizer.stderr"
mkdir -p "$sessionizer_home/.config/tmux-sessionizer" "$sessionizer_bin" "$sessionizer_home/fallback project/.git"
cp "$common_sessionizer_config" "$sessionizer_home/.config/tmux-sessionizer/tmux-sessionizer.conf"
printf '#!/usr/bin/env bash\nif [[ $1 == list-sessions ]]; then exit 0; fi\nexit 1\n' > "$sessionizer_bin/tmux"
chmod +x "$sessionizer_bin/tmux"

if ! env -i HOME="$sessionizer_home" XDG_CONFIG_HOME="$sessionizer_home/.config" PATH="$sessionizer_bin:/usr/bin:/bin" \
  "$sessionizer" --version > "$sessionizer_stdout" 2> "$sessionizer_stderr"; then
  fail "tmux-sessionizer --version without local config failed: $(cat "$sessionizer_stderr")"
fi
assert_eq 'tmux-sessionizer version 0.1.0' "$(cat "$sessionizer_stdout")" 'tmux-sessionizer version without local config'
assert_eq '' "$(cat "$sessionizer_stderr")" 'tmux-sessionizer version stderr without local config'

mkdir "$sessionizer_home/.config/tmux-sessionizer/tmux-sessionizer.local.conf"
if ! env -i HOME="$sessionizer_home" XDG_CONFIG_HOME="$sessionizer_home/.config" PATH="$sessionizer_bin:/usr/bin:/bin" \
  "$sessionizer" --version > "$sessionizer_stdout" 2> "$sessionizer_stderr"; then
  fail "tmux-sessionizer --version with a local config directory failed: $(cat "$sessionizer_stderr")"
fi
assert_eq 'tmux-sessionizer version 0.1.0' "$(cat "$sessionizer_stdout")" 'tmux-sessionizer ignores local config directories'
assert_eq '' "$(cat "$sessionizer_stderr")" 'tmux-sessionizer local config directory stderr'
rmdir "$sessionizer_home/.config/tmux-sessionizer/tmux-sessionizer.local.conf"

mkfifo "$sessionizer_home/.config/tmux-sessionizer/tmux-sessionizer.local.conf"
env -i HOME="$sessionizer_home" XDG_CONFIG_HOME="$sessionizer_home/.config" PATH="$sessionizer_bin:/usr/bin:/bin" \
  "$sessionizer" --version > "$sessionizer_stdout" 2> "$sessionizer_stderr" &
sessionizer_pid=$!
sleep 1
if kill -0 "$sessionizer_pid" 2>/dev/null; then
  kill "$sessionizer_pid" 2>/dev/null || true
  wait "$sessionizer_pid" 2>/dev/null || true
  fail 'tmux-sessionizer blocked while reading a local config FIFO'
fi
if ! wait "$sessionizer_pid"; then
  fail "tmux-sessionizer --version with a local config FIFO failed: $(cat "$sessionizer_stderr")"
fi
assert_eq 'tmux-sessionizer version 0.1.0' "$(cat "$sessionizer_stdout")" 'tmux-sessionizer ignores local config FIFOs'
assert_eq '' "$(cat "$sessionizer_stderr")" 'tmux-sessionizer local config FIFO stderr'
rm "$sessionizer_home/.config/tmux-sessionizer/tmux-sessionizer.local.conf"

if ! env -i HOME="$sessionizer_home" XDG_CONFIG_HOME="$sessionizer_home/.config" PATH="$sessionizer_bin:/usr/bin:/bin" \
  "$sessionizer" --list > "$sessionizer_stdout" 2> "$sessionizer_stderr"; then
  fail "tmux-sessionizer fallback listing failed: $(cat "$sessionizer_stderr")"
fi
assert_contains '    ~/fallback project' "$(cat "$sessionizer_stdout")" 'tmux-sessionizer safe HOME fallback search root'
assert_eq '' "$(cat "$sessionizer_stderr")" 'tmux-sessionizer fallback listing stderr'

mkdir -p "$sessionizer_home/projects with spaces/first project/.git" "$sessionizer_home/second root/second project/.git"
printf '%s\n' 'TS_SEARCH_PATHS=("$HOME/projects with spaces:1" "$HOME/second root:1")' \
  > "$sessionizer_home/.config/tmux-sessionizer/tmux-sessionizer.local.conf"
if ! env -i HOME="$sessionizer_home" XDG_CONFIG_HOME="$sessionizer_home/.config" PATH="$sessionizer_bin:/usr/bin:/bin" \
  "$sessionizer" --list > "$sessionizer_stdout" 2> "$sessionizer_stderr"; then
  fail "tmux-sessionizer local listing failed: $(cat "$sessionizer_stderr")"
fi
assert_eq '    ~/projects with spaces/first project
    ~/second root/second project' "$(cat "$sessionizer_stdout")" \
  'tmux-sessionizer consumes exact local search paths with spaces'
assert_eq '' "$(cat "$sessionizer_stderr")" 'tmux-sessionizer local listing stderr'

mkdir -p "$sessionizer_home/root A/level one/level two/.git" "$sessionizer_home/root B/level one/level two/.git"
printf '%s\n' 'TS_SEARCH_PATHS=("$HOME/root A:2" "$HOME/root B")' \
  > "$sessionizer_home/.config/tmux-sessionizer/tmux-sessionizer.local.conf"
if ! env -i HOME="$sessionizer_home" XDG_CONFIG_HOME="$sessionizer_home/.config" PATH="$sessionizer_bin:/usr/bin:/bin" \
  "$sessionizer" --list > "$sessionizer_stdout" 2> "$sessionizer_stderr"; then
  fail "tmux-sessionizer mixed-depth listing failed: $(cat "$sessionizer_stderr")"
fi
assert_contains '    ~/root A/level one/level two' "$(cat "$sessionizer_stdout")" 'tmux-sessionizer honors suffixed depth'
assert_contains '    ~/root B/level one' "$(cat "$sessionizer_stdout")" 'tmux-sessionizer lists unsuffixed root at default depth'
if [[ $(cat "$sessionizer_stdout") == *'~/root B/level one/level two'* ]]; then
  fail 'tmux-sessionizer leaked the prior entry depth into an unsuffixed root'
fi
assert_eq '' "$(cat "$sessionizer_stderr")" 'tmux-sessionizer mixed-depth listing stderr'

mkdir -p "$sessionizer_home/colon:root/level one/level two/.git" "$sessionizer_home/non-numeric:tail/literal project/.git"
printf '%s\n' 'TS_SEARCH_PATHS=("$HOME/colon:root:2" "$HOME/non-numeric:tail")' \
  > "$sessionizer_home/.config/tmux-sessionizer/tmux-sessionizer.local.conf"
if ! env -i HOME="$sessionizer_home" XDG_CONFIG_HOME="$sessionizer_home/.config" PATH="$sessionizer_bin:/usr/bin:/bin" \
  "$sessionizer" --list > "$sessionizer_stdout" 2> "$sessionizer_stderr"; then
  fail "tmux-sessionizer colon path listing failed: $(cat "$sessionizer_stderr")"
fi
assert_contains '    ~/colon:root/level one/level two' "$(cat "$sessionizer_stdout")" 'tmux-sessionizer parses final numeric colon suffix'
assert_contains '    ~/non-numeric:tail/literal project' "$(cat "$sessionizer_stdout")" 'tmux-sessionizer retains non-numeric colon paths'
assert_eq '' "$(cat "$sessionizer_stderr")" 'tmux-sessionizer colon path listing stderr'

mkdir -p "$sessionizer_home/fallback boundary/deeper project/.git"
printf '%s\n' 'TS_SEARCH_PATHS=()' > "$sessionizer_home/.config/tmux-sessionizer/tmux-sessionizer.local.conf"
if ! env -i HOME="$sessionizer_home" XDG_CONFIG_HOME="$sessionizer_home/.config" PATH="$sessionizer_bin:/usr/bin:/bin" TS_MAX_DEPTH=2 \
  "$sessionizer" --list > "$sessionizer_stdout" 2> "$sessionizer_stderr"; then
  fail "tmux-sessionizer bounded fallback listing failed: $(cat "$sessionizer_stderr")"
fi
assert_contains '    ~/fallback boundary' "$(cat "$sessionizer_stdout")" 'tmux-sessionizer bounded fallback root'
if [[ $(cat "$sessionizer_stdout") == *'~/fallback boundary/deeper project'* ]]; then
  fail 'tmux-sessionizer fallback inherited TS_MAX_DEPTH'
fi
assert_eq '' "$(cat "$sessionizer_stderr")" 'tmux-sessionizer bounded fallback listing stderr'

mkdir -p "$sessionizer_home/unset boundary/deeper project/.git" "$sessionizer_home/empty scalar boundary/deeper project/.git"
printf '%s\n' 'unset TS_SEARCH_PATHS' > "$sessionizer_home/.config/tmux-sessionizer/tmux-sessionizer.local.conf"
if ! env -i HOME="$sessionizer_home" XDG_CONFIG_HOME="$sessionizer_home/.config" PATH="$sessionizer_bin:/usr/bin:/bin" TS_MAX_DEPTH=2 \
  "$sessionizer" --list > "$sessionizer_stdout" 2> "$sessionizer_stderr"; then
  fail "tmux-sessionizer unset fallback listing failed: $(cat "$sessionizer_stderr")"
fi
assert_contains '    ~/unset boundary' "$(cat "$sessionizer_stdout")" 'tmux-sessionizer unset fallback root'
if [[ $(cat "$sessionizer_stdout") == *'~/unset boundary/deeper project'* ]]; then
  fail 'tmux-sessionizer unset fallback inherited TS_MAX_DEPTH'
fi
assert_eq '' "$(cat "$sessionizer_stderr")" 'tmux-sessionizer unset fallback listing stderr'

printf '%s\n' 'TS_SEARCH_PATHS=""' > "$sessionizer_home/.config/tmux-sessionizer/tmux-sessionizer.local.conf"
if ! env -i HOME="$sessionizer_home" XDG_CONFIG_HOME="$sessionizer_home/.config" PATH="$sessionizer_bin:/usr/bin:/bin" TS_MAX_DEPTH=2 \
  "$sessionizer" --list > "$sessionizer_stdout" 2> "$sessionizer_stderr"; then
  fail "tmux-sessionizer empty scalar fallback listing failed: $(cat "$sessionizer_stderr")"
fi
assert_contains '    ~/empty scalar boundary' "$(cat "$sessionizer_stdout")" 'tmux-sessionizer empty scalar fallback root'
if [[ $(cat "$sessionizer_stdout") == *'~/empty scalar boundary/deeper project'* ]]; then
  fail 'tmux-sessionizer empty scalar fallback inherited TS_MAX_DEPTH'
fi
assert_eq '' "$(cat "$sessionizer_stderr")" 'tmux-sessionizer empty scalar fallback listing stderr'

sessionizer_no_tmux_bin="$TEST_ROOT/no-tmux-bin"
mkdir "$sessionizer_no_tmux_bin"
for command in bash basename find grep sed tr; do
  ln -s "/usr/bin/$command" "$sessionizer_no_tmux_bin/$command"
done
ln -sf /bin/bash "$sessionizer_no_tmux_bin/bash"
if ! env -i HOME="$sessionizer_home" XDG_CONFIG_HOME="$sessionizer_home/.config" PATH="$sessionizer_no_tmux_bin" TMUX=stale \
  "$sessionizer" --list > "$sessionizer_stdout" 2> "$sessionizer_stderr"; then
  fail "tmux-sessionizer stale TMUX listing failed: $(cat "$sessionizer_stderr")"
fi
assert_eq '' "$(cat "$sessionizer_stderr")" 'tmux-sessionizer stale TMUX without tmux stderr'

if ! env -i HOME="$sessionizer_home" XDG_CONFIG_HOME="$sessionizer_home/.config" PATH="$sessionizer_bin:/usr/bin:/bin" \
  "$sessionizer" --help > "$sessionizer_stdout" 2> "$sessionizer_stderr"; then
  fail "tmux-sessionizer help failed: $(cat "$sessionizer_stderr")"
fi
assert_contains '-l, --list       List matching projects without opening fzf' "$(cat "$sessionizer_stdout")" 'tmux-sessionizer list help'
assert_eq '' "$(cat "$sessionizer_stderr")" 'tmux-sessionizer help stderr'
cleanup_test_root

printf 'PASS: shell helpers\n'
