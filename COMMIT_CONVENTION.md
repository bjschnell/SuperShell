# Conventional Commits Guide
#
# Format: <type>(<optional scope>): <description>
#
# The version bump is determined automatically from commit messages
# when a PR is merged to main.
#
# ╔════════════════╦═══════════╦══════════════════════════════════════╗
# ║ Type           ║ Bump      ║ When to use                          ║
# ╠════════════════╬═══════════╬══════════════════════════════════════╣
# ║ feat           ║ MINOR     ║ New tool, function, alias, or        ║
# ║                ║           ║ feature added to the config           ║
# ╠════════════════╬═══════════╬══════════════════════════════════════╣
# ║ fix            ║ PATCH     ║ Bug fix in a function or script       ║
# ╠════════════════╬═══════════╬══════════════════════════════════════╣
# ║ docs           ║ PATCH     ║ README, tools.txt, cheatsheet update  ║
# ╠════════════════╬═══════════╬══════════════════════════════════════╣
# ║ chore          ║ PATCH     ║ Cleanup, formatting, maintenance      ║
# ╠════════════════╬═══════════╬══════════════════════════════════════╣
# ║ refactor       ║ PATCH     ║ Restructure without behavior change   ║
# ╠════════════════╬═══════════╬══════════════════════════════════════╣
# ║ style          ║ PATCH     ║ Theme/color/formatting changes        ║
# ╠════════════════╬═══════════╬══════════════════════════════════════╣
# ║ perf           ║ PATCH     ║ Startup speed, lazy loading, etc      ║
# ╠════════════════╬═══════════╬══════════════════════════════════════╣
# ║ ci             ║ PATCH     ║ GitHub Actions / workflow changes     ║
# ╠════════════════╬═══════════╬══════════════════════════════════════╣
# ║ feat!          ║ MAJOR     ║ Breaking change — renamed aliases,    ║
# ║ fix!           ║           ║ removed functions, restructured       ║
# ║ any!           ║           ║ config that needs manual migration     ║
# ╚════════════════╩═══════════╩══════════════════════════════════════╝
#
# Examples:
#
#   feat: add tldr integration to shelp cheatsheet
#   feat(docker): add dstats function for container resource usage
#   fix: rgf not opening files with spaces in path
#   fix(installer): lazygit not found in pacman on older Arch
#   docs: update README with new git functions
#   chore: clean up unused aliases
#   style: update fzf colors to match Dracula spec
#   refactor(installer): split package lists into separate files
#   feat!: rename j function to bm (breaking: muscle memory change)
#
# The highest-priority bump wins when a PR has multiple commits:
#   major > minor > patch
#
# Commits that don't match any conventional prefix are ignored
# (no version bump).
