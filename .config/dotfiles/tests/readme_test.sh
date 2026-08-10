#!/usr/bin/env bash
set -euo pipefail

script_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
# shellcheck source=test_helpers.sh
source "$script_dir/test_helpers.sh"

work_tree=$(git -C "$script_dir" rev-parse --show-toplevel)
readme=${DOTFILES_README:-"$work_tree/.config/dotfiles/README.md"}

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
[[ ! -e $work_tree/README.md ]] || {
  fail 'repository-root README must remain absent'
  exit 1
}

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
  './dotfiles-bootstrap-tmp/.config/dotfiles/bootstrap --dry-run' \
  './dotfiles-bootstrap-tmp/.config/dotfiles/bootstrap' \
  '/bin/cp -- ~/.config/dotfiles/templates/gitconfig.local.example ~/.gitconfig.local' \
  '/bin/cp -- ~/.config/dotfiles/templates/allowed_signers.local.example ~/.config/git/allowed_signers.local' \
  '/bin/cp -- ~/.config/dotfiles/templates/zshrc.local.example ~/.zshrc.local' \
  '/bin/cp -- ~/.config/dotfiles/templates/tmux-sessionizer.local.conf.example ~/.config/tmux-sessionizer/tmux-sessionizer.local.conf' \
  'config status' \
  'config diff' \
  'config add -- .config/zsh/.zshrc' \
  'config commit -S -m "describe the focused change"' \
  'config status --short --untracked-files=all' \
  '~/.config/dotfiles/check' \
  '~/.config/dotfiles/check --fetch' \
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
  'Dry run complete; no changes made.' \
  'Move all listed conflicts to the one backup directory above? [y/N]' \
  'checkout failure intentionally retains the backup' \
  'Edit every placeholder before use.' \
  'Never commit local values, private material, or company material.' \
  'No `includeIf` or profile switching is used.' \
  'private key is never tracked' \
  'NEVER `config add .`' \
  'local and does not use the network or mutate the bare repository' \
  'updates remote-tracking refs only' \
  'PASS means a required check succeeded' \
  'WARN means an optional tool or dependency needs attention' \
  'FAIL means the check did not pass' \
  'Brew warnings never install anything' \
  'physical company-Mac acceptance is unverified' \
  'no company path, name, email, repository, certificate, or token'; do
  assert_readme_mentions "$guidance"
done

assert_readme_excludes 'BEGIN OPENSSH PRIVATE KEY' 'a private SSH key'
assert_readme_excludes 'ssh-ed25519 AAAA' 'an actual-looking public SSH key'
assert_readme_excludes 'ghp_' 'a GitHub token pattern'
assert_readme_excludes 'github_pat_' 'a GitHub token pattern'

personal_email=$(git -C "$work_tree" config --get user.email || true)
if [[ -n $personal_email ]]; then
  assert_readme_excludes "$personal_email" 'the configured personal email'
fi

printf 'PASS: README documentation policy\n'
