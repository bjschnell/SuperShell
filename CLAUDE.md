# CLAUDE.md

Guidance for Claude Code (and other agents) working in this repo. SuperShell is
an opinionated, cross-platform CLI environment: modern Rust/Go replacements for
classic Unix tools, wired together through `fzf`, deployed by per-OS installer
and updater scripts.

## The one rule that matters most: keep all three platforms in sync

The installers, updaters, and shell configs come as a **per-OS set**. A change
to one is a change to all of them — make the matching edit across every platform
in the **same PR**.

| Concern | Linux | macOS | Windows |
|---------|-------|-------|---------|
| Installer | `install-supershell.sh` | `install-supershell-macos.sh` | `install-supershell.ps1` |
| Updater | `update-supershell.sh` | `update-supershell-macos.sh` | `update-supershell.ps1` |
| Shell config | `config.fish` | `config.fish` (shared) | `Microsoft.PowerShell_profile.ps1` |

A new flag, a new deployed file, a reworded message, a new tool in the install
list, a changed prompt — mirror it everywhere. If a change genuinely applies to
only one OS, say why in the commit message so the divergence is intentional.

## Conventions to preserve

- **`config.fish` is shared by Linux and macOS.** Guard OS-specific bits at
  runtime with `test (uname) = Darwin` — do not fork the file. Existing examples:
  clipboard backend (`pbcopy`/`wl-copy`/`xclip`), `ports`, `logtail`, the
  package-manager abbreviations.
- **The updaters deploy configs only** — no package installs/upgrades, no `chsh`,
  no services, no fonts. Those belong to the installers, run once per machine.
  The three updaters are meant to be near-identical apart from platform specifics
  (package manager, clipboard backend, `trash-put` vs `trash`, path conventions).
- **Every script supports `--dry-run` / `-DryRun`.** Keep it working; test with it.
- Match the existing house style in each script: the `info/ok/warn/err/section`
  helpers, the banner boxes, and the `--help` text.

## Workflow

- Commits follow Conventional Commits — see `COMMIT_CONVENTION.md`. Merging a PR
  to `main` triggers automatic version bumps via `.github/workflows/version-bump.yml`,
  so the commit *type* (`feat:`/`fix:`/etc.) drives the release — get it right.
- Validate before pushing: `bash -n <script>.sh` for shell scripts, `fish -n
  config.fish` for the fish config.
- Never edit `VERSION` or `CHANGELOG.md` by hand — the workflow owns them.
