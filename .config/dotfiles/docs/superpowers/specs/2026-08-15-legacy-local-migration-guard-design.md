# Legacy Local Configuration Migration Guard Design

## Goal

Prevent existing Macs from silently losing machine-local Git identity or Zsh behavior after the local files move from `~/.gitconfig.local` and `~/.zshrc.local` to their XDG locations.

## Scope

- Keep both legacy paths ignored so private or company-local values cannot be staged accidentally.
- Detect legacy Git and Zsh local files in `bootstrap` and `check`.
- Never move, copy, merge, delete, or overwrite a machine-local file automatically.
- Print exact, safely quoted migration commands only when the new destination does not exist.
- Require manual comparison when both the legacy and XDG paths exist.
- Document the migration and cover it with behavioral tests.

The XDG locations remain the only active load paths. No permanent fallback loading is added.

## Behavior

The guarded path pairs are:

| Legacy path | Active XDG path |
| --- | --- |
| `~/.gitconfig.local` | `~/.config/git/config.local` |
| `~/.zshrc.local` | `~/.config/zsh/.zshrc.local` |

For each pair:

1. Neither path exists: preserve the current template-copy guidance.
2. Only the XDG path exists: continue normally.
3. Only the legacy path exists: report that it is no longer loaded, print an exact `/bin/mv -- <legacy> <XDG>` command, and fail validation.
4. Both paths exist: report that automatic migration is unsafe, require manual comparison and removal of the legacy file, and fail validation without printing an overwriting move command.

Files and symbolic links both count as existing local configuration. Directories or other special entries at either path are not modified and produce the same manual-action failure.

## Components

### Ignore policy

`.gitignore` retains the two XDG ignores and restores the two legacy ignores. The legacy entries are compatibility safety rules, not supported load paths.

### Bootstrap

After tracked files are placed, `bootstrap` inspects the two path pairs before running `check` or printing ordinary template guidance. A detected legacy path makes the real bootstrap exit nonzero after printing the applicable migration instructions. Dry-run reports the same migration requirement while preserving its no-change guarantee.

### Check

`check` performs the same pair inspection early enough that a legacy Git identity is reported explicitly instead of being reduced to a generic missing-identity failure. It continues the remaining independent checks and returns a nonzero summary.

### Documentation

The README explains that updates from the legacy layout require a one-time manual move. It includes guarded commands that refuse to overwrite an existing XDG destination.

## Error Handling

- Paths are rendered with shell-safe quoting.
- No command is printed that would overwrite an existing destination.
- The tools do not inspect or print local file contents.
- Migration failure does not delete or relocate either file.
- Existing bootstrap conflict backup and recovery behavior remains unchanged.

## Tests

- Ignore tests prove that both legacy and XDG paths remain ignored.
- Bootstrap tests cover legacy-only and legacy-plus-XDG states, exact guidance, nonzero status, and unchanged local file bytes.
- Check tests cover both guarded pairs and distinguish safe move guidance from the both-exist message.
- README tests lock the documented guarded migration commands.
- The complete dotfiles test suite must pass in a normal worktree with real tmux socket permission.

## Acceptance Criteria

- An existing Mac with either legacy file cannot complete bootstrap or check without an explicit migration message.
- No machine-local file is modified automatically.
- A fully migrated Mac retains the current successful behavior.
- New installations retain the current template workflow.
- The live bare work tree remains clean after integration.
