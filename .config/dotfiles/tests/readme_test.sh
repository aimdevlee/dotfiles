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
for command in \
  'reviewed_head=$(git -C "$bootstrap_source" rev-parse HEAD)' \
  'DOTFILES_SOURCE="$bootstrap_source/.git" DOTFILES_SOURCE_REF="$reviewed_head" DOTFILES_REMOTE="git@github.com:aimdevlee/dotfiles.git" "$bootstrap_source/.config/dotfiles/bootstrap" --dry-run' \
  'DOTFILES_SOURCE="$bootstrap_source/.git" DOTFILES_SOURCE_REF="$reviewed_head" DOTFILES_REMOTE="git@github.com:aimdevlee/dotfiles.git" "$bootstrap_source/.config/dotfiles/bootstrap"' \
  '~/.config/dotfiles/check' \
  '~/.config/dotfiles/check --fetch' \
  '.config/dotfiles/tests/run'; do
  assert_readme_contains "$command"
done

for guidance in \
  'does not install Homebrew, packages, or apps' \
  'Do not pipe remote code to a shell.' \
  'personal and company identity local to each machine' \
  'Never commit local values, private material, or company material.' \
  'private key is never tracked' \
  'NEVER `config add .`' \
  'bootstrap and check never move legacy local files automatically' \
  'installation remains manual' \
  'no company path, name, email, repository, certificate, or token'; do
  assert_readme_mentions "$guidance"
done

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

printf 'PASS: README documentation policy\n'
