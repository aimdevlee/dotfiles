# Portable dotfiles

## Purpose and support

This is common portable configuration for personal and company Apple Silicon Macs. It is installed as a bare ~/.cfg repository with HOME as its work tree; personal and company identity local to each machine stays local. Tracked files contain only the shared baseline.

## Scope and prerequisites

`bootstrap` does not install Homebrew, packages, or apps; does not manage private SSH keys; does not fetch unless `check --fetch` is requested; and does not commit, push, or run Git garbage collection. The first placement does need network access to obtain the temporary normal clone; bootstrap then clones the reviewed local source and never runs a separate `git fetch`.

Before starting, use a Darwin arm64 (Apple Silicon) Mac with `/usr/bin/git`, a writable non-symlink HOME directory, SSH access to the remote, and enough disk space for a bare repository and backups. This project supports Darwin arm64 only; it does not claim success on other platforms.

## First placement

The bootstrap script is itself inside the work tree it will place. Solve that catch-22 with a separate, temporary, normal clone or copy; do not run unknown remote output directly. Do not pipe remote code to a shell.

```sh
git clone git@github.com:aimdevlee/dotfiles.git dotfiles-bootstrap-tmp
bootstrap_source=$(cd -- dotfiles-bootstrap-tmp && pwd)
reviewed_head=$(git -C "$bootstrap_source" rev-parse HEAD)
git -C "$bootstrap_source" status --short
DOTFILES_SOURCE="$bootstrap_source/.git" DOTFILES_SOURCE_REF="$reviewed_head" DOTFILES_REMOTE="git@github.com:aimdevlee/dotfiles.git" "$bootstrap_source/.config/dotfiles/bootstrap" --dry-run
DOTFILES_SOURCE="$bootstrap_source/.git" DOTFILES_SOURCE_REF="$reviewed_head" DOTFILES_REMOTE="git@github.com:aimdevlee/dotfiles.git" "$bootstrap_source/.config/dotfiles/bootstrap"
```

Record `reviewed_head` and inspect the clone and dry-run output first. `DOTFILES_SOURCE_REF` must be the full commit OID reviewed in the temporary clone; both bootstrap invocations require that exact commit to remain present in `DOTFILES_SOURCE` and install its content even if the source branch advances between invocations. If `DOTFILES_SOURCE_REF` is omitted, each invocation uses the current symbolic HEAD of `DOTFILES_SOURCE` and does not claim reviewed-commit pinning. The installed bare repository's final `origin` is the GitHub URL in `DOTFILES_REMOTE`. The second command is interactive: review every listed conflict and answer the confirmation prompt only when the proposed backup moves are correct. The temporary clone is not deleted automatically; clean it up manually after confirming the new placement works.

## Conflicts and recovery

Dry run makes zero changes and ends with `Dry run complete; no changes made.` A real run moves each conflicting tracked destination beneath `$HOME/.local/state/dotfiles/backups/<timestamp-pid>/` and asks `Move all listed conflicts to the one backup directory above? [y/N]` before moving anything.

If checkout fails after moves, the checkout failure intentionally retains the backup. Use the exact relative paths and backup path printed by bootstrap. Resolve the destination first; do not overwrite it. For the tracked example `.config/zsh/.zshrc`:

```sh
backup_dir="$HOME/.local/state/dotfiles/backups/<timestamp-pid>"
relative_path=".config/zsh/.zshrc"
source="$backup_dir/$relative_path"
destination="$HOME/$relative_path"
if [[ -e "$destination" || -L "$destination" ]]; then
  printf '%s\n' 'STOP: destination exists; compare it or move it separately before recovery.'
else
  /bin/mkdir -p -- "$(/usr/bin/dirname -- "$destination")"
  /bin/mv -- "$source" "$destination"
fi
```

Backups are intentionally retained; inspect them before any manual cleanup.

## Migrating legacy local files

Older installations may still have machine-local Git or Zsh settings at the legacy HOME paths. The active paths are under `~/.config`. Run these guarded commands once after reviewing both path pairs. The safety rule is that bootstrap and check never move legacy local files automatically.

```sh
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

When both paths exist, compare their contents and merge any needed values into the active XDG file. Remove the legacy file only after confirming the active configuration is complete.

## Local files and templates

These files are machine-local: `~/.config/git/config.local`, `~/.config/git/allowed_signers.local`, `~/.config/zsh/.zshrc.local`, and `~/.config/tmux-sessionizer/tmux-sessionizer.local.conf`. Create them only from the tracked templates. Every command below preserves an existing file and prints a skip instead of copying over it:

```sh
if [[ ! -e "$HOME/.config/git/config.local" && ! -L "$HOME/.config/git/config.local" ]]; then
  /bin/cp -- "$HOME/.config/dotfiles/templates/gitconfig.local.example" "$HOME/.config/git/config.local"
else
  printf '%s\n' 'SKIP: ~/.config/git/config.local already exists'
fi
if [[ ! -e "$HOME/.config/git/allowed_signers.local" && ! -L "$HOME/.config/git/allowed_signers.local" ]]; then
  /bin/cp -- "$HOME/.config/dotfiles/templates/allowed_signers.local.example" "$HOME/.config/git/allowed_signers.local"
else
  printf '%s\n' 'SKIP: ~/.config/git/allowed_signers.local already exists'
fi
if [[ ! -e "$HOME/.config/zsh/.zshrc.local" && ! -L "$HOME/.config/zsh/.zshrc.local" ]]; then
  /bin/cp -- "$HOME/.config/dotfiles/templates/zshrc.local.example" "$HOME/.config/zsh/.zshrc.local"
else
  printf '%s\n' 'SKIP: ~/.config/zsh/.zshrc.local already exists'
fi
if [[ ! -e "$HOME/.config/tmux-sessionizer/tmux-sessionizer.local.conf" && ! -L "$HOME/.config/tmux-sessionizer/tmux-sessionizer.local.conf" ]]; then
  /bin/cp -- "$HOME/.config/dotfiles/templates/tmux-sessionizer.local.conf.example" "$HOME/.config/tmux-sessionizer/tmux-sessionizer.local.conf"
else
  printf '%s\n' 'SKIP: ~/.config/tmux-sessionizer/tmux-sessionizer.local.conf already exists'
fi
```

Edit every placeholder before use. Put personal values on a personal Mac and company values on a company Mac. Never commit local values, private material, or company material. No `includeIf` or profile switching is used.

## SSH signing

The tracked Git configuration expects the public signing key at `~/.ssh/id_ed25519.pub`; the corresponding private key is never tracked or managed here. The local allowed-signers file uses one signer per line in this form:

```text
principal[,principal...] ssh-ed25519 PUBLIC_KEY [comment]
```

After editing the local templates, verify only local configuration and signatures immediately, without relying on a fresh shell:

```sh
/usr/bin/git --git-dir="$HOME/.cfg" --work-tree="$HOME" config --global --includes --show-origin --get user.signingKey
/usr/bin/git --git-dir="$HOME/.cfg" --work-tree="$HOME" config --global --includes --show-origin --get gpg.ssh.allowedSignersFile
/usr/bin/git --git-dir="$HOME/.cfg" --work-tree="$HOME" verify-commit HEAD
```

Local Git signature verification is distinct from any hosting-service badge or web verification.

## Daily workflow

Open a new terminal to load the shell configuration. If continuing in the current shell, define the alias and move to HOME before using relative paths:

```sh
alias config='/usr/bin/git --git-dir="$HOME/.cfg" --work-tree="$HOME"'
cd "$HOME"
```

Use the bare-repository alias for deliberate changes:

```sh
config status
config diff
config add -- .config/zsh/.zshrc
config commit -S -m "describe the focused change"
```

NEVER `config add .`; HOME has many unrelated files. Audit untracked files explicitly when needed:

```sh
config status --short --untracked-files=all
```

## Validation

Run the local validation after placing and editing local files:

```sh
~/.config/dotfiles/check
~/.config/dotfiles/check --fetch
```

`check` without `--fetch` is local and does not use the network or mutate the bare repository. `check --fetch` updates remote-tracking refs and normal Git fetch metadata and may fetch tags, but never integrates the work tree or current branch; it reports ahead/behind status. Use it when a remote refresh is intended. PASS means a required check succeeded. WARN means an optional tool or dependency needs attention. FAIL means the check did not pass. Brew warnings never install anything.

The tracked `~/.Brewfile` is the shared baseline for personal and company Macs. The ignored `~/.Brewfile.local` contains packages specific to one machine. The local Brewfile is optional; `check` validates it independently when present and silently skips it when absent. Package installation remains manual:

```sh
brew bundle install --file="$HOME/.Brewfile"
brew bundle install --file="$HOME/.Brewfile.local"
```

Run only the command for a file whose declared packages you intend to install on that Mac.

## Re-run and company boundary

For a safe re-run, start with the dry run again. A matching existing bare repository with unchanged tracked files can be placed repeatedly; differing tracked destinations stop for review rather than being overwritten. Recover with the retained backup commands above instead of resetting HOME.

No company path, name, email, repository, certificate, or token belongs in tracked common configuration, templates, or logs. Keep all such material in ignored local files.

## Development and acceptance

Run the development suite only from a temporary normal development clone or worktree, not from the installed bare HOME work tree:

```sh
cd "$bootstrap_source"
.config/dotfiles/tests/run
```

Installed users run `check`; they do not run the development suite. Physical company-Mac acceptance is unverified until the user runs dry-run, interactive bootstrap, and `check` on that Mac.
