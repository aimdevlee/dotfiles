#!/usr/bin/env bash
set -euo pipefail

script_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
# shellcheck source=test_helpers.sh
source "$script_dir/test_helpers.sh"

if [[ -n ${DOTFILES_WORK_TREE+x} && -n ${DOTFILES_GIT_DIR+x} ]]; then
  work_tree=$DOTFILES_WORK_TREE
  repo_dir=$DOTFILES_GIT_DIR
elif [[ -n ${DOTFILES_WORK_TREE+x} || -n ${DOTFILES_GIT_DIR+x} ]]; then
  fail 'DOTFILES_WORK_TREE and DOTFILES_GIT_DIR must be supplied together'
  exit 1
else
  work_tree=$(git -C "$script_dir" rev-parse --show-toplevel)
  repo_dir=$(git -C "$work_tree" rev-parse --absolute-git-dir)
fi
readme=${DOTFILES_README:-"$work_tree/.config/dotfiles/README.md"}
runner="$work_tree/.config/dotfiles/tests/run"
identity_sentinel='personal.identity@example.invalid'

assert_readme_contains() {
  local expected=$1

  if ! /usr/bin/grep -Fqx -- "$expected" "$readme"; then
    fail "README is missing required command or heading [$expected]"
    return 1
  fi
}

assert_readme_mentions() {
  local expected=$1

  if ! /usr/bin/grep -Fqi -- "$expected" "$readme"; then
    fail "README is missing required guidance [$expected]"
    return 1
  fi
}

assert_readme_excludes() {
  local prohibited=$1
  local description=$2

  if /usr/bin/grep -Fq -- "$prohibited" "$readme"; then
    fail "README contains $description"
    return 1
  fi
}

[[ -f $readme ]] || {
  fail 'dotfiles README is missing'
  exit 1
}
if /usr/bin/git --git-dir="$repo_dir" --work-tree="$work_tree" ls-files --error-unmatch -- README >/dev/null 2>&1; then
  fail 'repository-root README must remain untracked'
  exit 1
fi
[[ -x $runner ]] || {
  fail 'test runner is missing or not executable'
  exit 1
}
for expected_test in ignore_test.sh shell_test.sh check_test.sh bootstrap_test.sh readme_test.sh; do
  if ! /usr/bin/grep -Fqx -- "  \"$expected_test\"" "$runner"; then
    fail "runner does not require test [$expected_test]"
    exit 1
  fi
done
if /usr/bin/grep -Fq '[[ -x $test_path ]] || continue' "$runner"; then
  fail 'runner silently skips missing or non-executable tests'
  exit 1
fi

for heading in \
  '## Purpose and support' \
  '## Scope and prerequisites' \
  '## First placement' \
  '## Conflicts and recovery' \
  '## Local files and templates' \
  '## SSH signing' \
  '## Daily workflow' \
  '## Validation' \
  '## Re-run and company boundary' \
  '## Development and acceptance'; do
  assert_readme_contains "$heading"
done

for command in \
  'git clone git@github.com:aimdevlee/dotfiles.git dotfiles-bootstrap-tmp' \
  'reviewed_head=$(git -C "$bootstrap_source" rev-parse HEAD)' \
  'DOTFILES_SOURCE="$bootstrap_source/.git" DOTFILES_SOURCE_REF="$reviewed_head" DOTFILES_REMOTE="git@github.com:aimdevlee/dotfiles.git" "$bootstrap_source/.config/dotfiles/bootstrap" --dry-run' \
  'DOTFILES_SOURCE="$bootstrap_source/.git" DOTFILES_SOURCE_REF="$reviewed_head" DOTFILES_REMOTE="git@github.com:aimdevlee/dotfiles.git" "$bootstrap_source/.config/dotfiles/bootstrap"' \
  'if [[ ! -e "$HOME/.config/git/config.local" && ! -L "$HOME/.config/git/config.local" ]]; then' \
  'if [[ ! -e "$HOME/.config/git/allowed_signers.local" && ! -L "$HOME/.config/git/allowed_signers.local" ]]; then' \
  'if [[ ! -e "$HOME/.config/zsh/.zshrc.local" && ! -L "$HOME/.config/zsh/.zshrc.local" ]]; then' \
  'if [[ ! -e "$HOME/.config/tmux-sessionizer/tmux-sessionizer.local.conf" && ! -L "$HOME/.config/tmux-sessionizer/tmux-sessionizer.local.conf" ]]; then' \
  '  /bin/cp -- "$HOME/.config/dotfiles/templates/gitconfig.local.example" "$HOME/.config/git/config.local"' \
  '  /bin/cp -- "$HOME/.config/dotfiles/templates/allowed_signers.local.example" "$HOME/.config/git/allowed_signers.local"' \
  '  /bin/cp -- "$HOME/.config/dotfiles/templates/zshrc.local.example" "$HOME/.config/zsh/.zshrc.local"' \
  '  /bin/cp -- "$HOME/.config/dotfiles/templates/tmux-sessionizer.local.conf.example" "$HOME/.config/tmux-sessionizer/tmux-sessionizer.local.conf"' \
  'cd "$HOME"' \
  'alias config='"'"'/usr/bin/git --git-dir="$HOME/.cfg" --work-tree="$HOME"'"'"'' \
  '/usr/bin/git --git-dir="$HOME/.cfg" --work-tree="$HOME" verify-commit HEAD' \
  'config status' \
  'config diff' \
  'config add -- .config/zsh/.zshrc' \
  'config commit -S -m "describe the focused change"' \
  'config status --short --untracked-files=all' \
  '~/.config/dotfiles/check' \
  '~/.config/dotfiles/check --fetch' \
  'brew bundle install --file="$HOME/.Brewfile"' \
  'brew bundle install --file="$HOME/.Brewfile.local"' \
  '.config/dotfiles/tests/run'; do
  assert_readme_contains "$command"
done

for guidance in \
  'bare ~/.cfg repository with HOME as its work tree' \
  'Apple Silicon Macs' \
  'personal and company identity local to each machine' \
  'does not install Homebrew, packages, or apps' \
  'does not manage private SSH keys' \
  'does not fetch unless `check --fetch` is requested' \
  'does not commit, push, or run Git garbage collection' \
  'Do not pipe remote code to a shell.' \
  'temporary clone is not deleted automatically' \
  'DOTFILES_SOURCE_REF' \
  'Dry run complete; no changes made.' \
  'Move all listed conflicts to the one backup directory above? [y/N]' \
  'checkout failure intentionally retains the backup' \
  'Use the exact relative paths and backup path printed by bootstrap.' \
  'STOP: destination exists; compare it or move it separately before recovery.' \
  'Edit every placeholder before use.' \
  'Never commit local values, private material, or company material.' \
  'No `includeIf` or profile switching is used.' \
  'private key is never tracked' \
  'NEVER `config add .`' \
  'local and does not use the network or mutate the bare repository' \
  'updates remote-tracking refs and normal Git fetch metadata and may fetch tags' \
  'never integrates the work tree or current branch' \
  'PASS means a required check succeeded' \
  'WARN means an optional tool or dependency needs attention' \
  'FAIL means the check did not pass' \
  'Brew warnings never install anything' \
  'The local Brewfile is optional' \
  'installation remains manual' \
  'physical company-Mac acceptance is unverified' \
  'no company path, name, email, repository, certificate, or token'; do
  assert_readme_mentions "$guidance"
done

recovery_path=.config/zsh/.zshrc
if ! /usr/bin/git --git-dir="$repo_dir" --work-tree="$work_tree" ls-files --error-unmatch -- "$recovery_path" >/dev/null 2>&1; then
  fail "README recovery example is not a tracked path [$recovery_path]"
  exit 1
fi
assert_readme_contains 'relative_path=".config/zsh/.zshrc"'
assert_readme_contains 'if [[ -e "$destination" || -L "$destination" ]]; then'
assert_readme_contains '  /bin/mkdir -p -- "$(/usr/bin/dirname -- "$destination")"'
assert_readme_contains '  /bin/mv -- "$source" "$destination"'

assert_readme_excludes 'BEGIN OPENSSH PRIVATE KEY' 'a private SSH key'
assert_readme_excludes 'ssh-ed25519 AAAA' 'an actual-looking public SSH key'
assert_readme_excludes 'ghp_' 'a GitHub token pattern'
assert_readme_excludes 'github_pat_' 'a GitHub token pattern'

assert_readme_excludes "$identity_sentinel" 'the synthetic identity sentinel'

(
  mutation_root=$(mktemp -d "${TMPDIR:-/tmp}/dotfiles-readme-mutation.XXXXXXXX")
  cleanup_mutation() {
    /bin/rm -rf -- "$mutation_root"
  }
  trap cleanup_mutation EXIT
  mutated_readme="$mutation_root/README.md"
  mutation_output="$mutation_root/output"
  /bin/cp -- "$readme" "$mutated_readme"
  printf '%s\n' "$identity_sentinel" >> "$mutated_readme"
  readme=$mutated_readme
  if assert_readme_excludes "$identity_sentinel" 'the synthetic identity sentinel' >"$mutation_output" 2>&1; then
    fail 'README policy accepted the synthetic identity sentinel'
    exit 1
  fi
  if ! /usr/bin/grep -Fq -- 'FAIL: README contains the synthetic identity sentinel' "$mutation_output"; then
    fail 'README policy did not reject the synthetic identity sentinel'
    exit 1
  fi
)

if [[ ${DOTFILES_README_TEST_SIMULATION:-0} != 1 ]]; then
  simulation_root=$(mktemp -d "${TMPDIR:-/tmp}/dotfiles-readme-bare.XXXXXXXX")
  cleanup_simulation() {
    /bin/rm -rf -- "$simulation_root"
  }
  trap cleanup_simulation EXIT
  simulation_home="$simulation_root/home"
  hostile_home="$simulation_root/hostile-home"
  empty_home="$simulation_root/empty-home"
  simulation_source=$(/usr/bin/git --git-dir="$repo_dir" rev-parse --git-common-dir)
  /bin/mkdir -p "$simulation_home/.config/dotfiles/tests" "$hostile_home" "$empty_home"
  printf '%s\n' '[user]' '  email = git@github.com' > "$hostile_home/.gitconfig"
  /usr/bin/git clone --bare -q -- "$simulation_source" "$simulation_home/.cfg"
  /usr/bin/git --git-dir="$simulation_home/.cfg" --work-tree="$simulation_home" checkout -q -f HEAD --
  /bin/cp -- "$readme" "$simulation_home/.config/dotfiles/README.md"
  /bin/cp -- "$runner" "$simulation_home/.config/dotfiles/tests/run"
  for isolated_home in "$hostile_home" "$empty_home"; do
    /usr/bin/env -i \
      HOME="$isolated_home" \
      XDG_CONFIG_HOME="$isolated_home/.config" \
      PATH=/usr/bin:/bin \
      LC_ALL=C \
      DOTFILES_WORK_TREE="$simulation_home" \
      DOTFILES_GIT_DIR="$simulation_home/.cfg" \
      DOTFILES_README="$simulation_home/.config/dotfiles/README.md" \
      DOTFILES_README_TEST_SIMULATION=1 \
      "$script_dir/readme_test.sh"
  done
fi

printf 'PASS: README documentation policy\n'
