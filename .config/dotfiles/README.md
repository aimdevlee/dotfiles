# Portable dotfiles

## Purpose and support

This is common portable configuration for personal and company Apple Silicon Macs. It is installed as a bare ~/.cfg repository with HOME as its work tree; personal and company identity local to each machine stays local. Tracked files contain only the shared baseline.

## Scope and prerequisites

`bootstrap` does not install Homebrew, packages, or apps; does not manage private SSH keys; does not fetch unless `check --fetch` is requested; and does not commit, push, or run Git garbage collection. The first placement does need network access because it clones the configured remote; it never runs a separate `git fetch`.

Before starting, use a Darwin arm64 (Apple Silicon) Mac with `/usr/bin/git`, a writable non-symlink HOME directory, SSH access to the remote, and enough disk space for a bare repository and backups. This project supports Darwin arm64 only; it does not claim success on other platforms.

## First placement

The bootstrap script is itself inside the work tree it will place. Solve that catch-22 with a separate, temporary, normal clone or copy; do not run unknown remote output directly. Do not pipe remote code to a shell.

```sh
git clone git@github.com:aimdevlee/dotfiles.git dotfiles-bootstrap-tmp
./dotfiles-bootstrap-tmp/.config/dotfiles/bootstrap --dry-run
./dotfiles-bootstrap-tmp/.config/dotfiles/bootstrap
```

Inspect the clone and dry-run output first. The second command is interactive: review every listed conflict and answer the confirmation prompt only when the proposed backup moves are correct. The temporary clone is not deleted automatically; clean it up manually after confirming the new placement works.

## Conflicts and recovery

Dry run makes zero changes and ends with `Dry run complete; no changes made.` A real run moves each conflicting tracked destination beneath `$HOME/.local/state/dotfiles/backups/<timestamp-pid>/` and asks `Move all listed conflicts to the one backup directory above? [y/N]` before moving anything.

If checkout fails after moves, the checkout failure intentionally retains the backup. Resolve the destination first, then restore each named file from the timestamp printed by bootstrap, for example:

```sh
/bin/mv -- "$HOME/.local/state/dotfiles/backups/<timestamp-pid>/.gitconfig.local" "$HOME/.gitconfig.local"
/bin/mv -- "$HOME/.local/state/dotfiles/backups/<timestamp-pid>/.config/git/allowed_signers.local" "$HOME/.config/git/allowed_signers.local"
/bin/mv -- "$HOME/.local/state/dotfiles/backups/<timestamp-pid>/.zshrc.local" "$HOME/.zshrc.local"
/bin/mv -- "$HOME/.local/state/dotfiles/backups/<timestamp-pid>/.config/tmux-sessionizer/tmux-sessionizer.local.conf" "$HOME/.config/tmux-sessionizer/tmux-sessionizer.local.conf"
```

Backups are intentionally retained; inspect them before any manual cleanup.

## Local files and templates

These files are machine-local: `~/.gitconfig.local`, `~/.config/git/allowed_signers.local`, `~/.zshrc.local`, and `~/.config/tmux-sessionizer/tmux-sessionizer.local.conf`. Create them only from the tracked templates:

```sh
/bin/cp -- ~/.config/dotfiles/templates/gitconfig.local.example ~/.gitconfig.local
/bin/cp -- ~/.config/dotfiles/templates/allowed_signers.local.example ~/.config/git/allowed_signers.local
/bin/cp -- ~/.config/dotfiles/templates/zshrc.local.example ~/.zshrc.local
/bin/cp -- ~/.config/dotfiles/templates/tmux-sessionizer.local.conf.example ~/.config/tmux-sessionizer/tmux-sessionizer.local.conf
```

Edit every placeholder before use. Put personal values on a personal Mac and company values on a company Mac. Never commit local values, private material, or company material. No `includeIf` or profile switching is used.

## SSH signing

The tracked Git configuration expects the public signing key at `~/.ssh/id_ed25519.pub`; the corresponding private key is never tracked or managed here. The local allowed-signers file uses one signer per line in this form:

```text
principal[,principal...] ssh-ed25519 PUBLIC_KEY [comment]
```

After editing the local templates, verify only local configuration and signatures:

```sh
git config --global --includes --show-origin --get user.signingKey
git config --global --includes --show-origin --get gpg.ssh.allowedSignersFile
config verify-commit HEAD
```

Local Git signature verification is distinct from any hosting-service badge or web verification.

## Daily workflow

Use the bare-repository alias from the shell configuration for deliberate changes:

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

`check` without `--fetch` is local and does not use the network or mutate the bare repository. `check --fetch` updates remote-tracking refs only and reports ahead/behind status; use it when a remote refresh is intended. PASS means a required check succeeded. WARN means an optional tool or dependency needs attention. FAIL means the check did not pass. Brew warnings never install anything.

## Re-run and company boundary

For a safe re-run, start with the dry run again. A matching existing bare repository with unchanged tracked files can be placed repeatedly; differing tracked destinations stop for review rather than being overwritten. Recover with the retained backup commands above instead of resetting HOME.

No company path, name, email, repository, certificate, or token belongs in tracked common configuration, templates, or logs. Keep all such material in ignored local files.

## Development and acceptance

Run the development suite from the dotfiles work tree:

```sh
.config/dotfiles/tests/run
```

Physical company-Mac acceptance is unverified until the user runs dry-run, interactive bootstrap, and `check` on that Mac.
