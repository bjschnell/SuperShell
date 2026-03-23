# ⚡ Super Shell

A fully portable, opinionated CLI environment built around modern Rust/Go replacements for classic Unix tools. One script bootstraps the entire setup on a fresh **Arch/CachyOS** or **Windows 11** machine — shell config, tools, theme, cheatsheets, and all.

```
⣿⣿⣿⣿⣿⣿⣿⠿⣛⣩⣴⣾⡿⠃⢀⣠⣾⣿⣿⣿⣿⣿⣿
⣿⣿⣿⣿⡿⣻⣴⣭⣭⣭⣭⣁⠶⣾⣿⣿⣿⣿⣿⣿⣿⣿⣿
⣿⣿⡿⢟⡕⢿⣿⣿⣿⣿⣿⣿⣿⣮⣹⣿⡿⠿⠿⢿⣿⣿⣿
⣿⡟⣴⣿⢶⢾⣿⣿⣿⣿⢟⠛⣿⣿⢿⣿⣿⣿⣷⣶⣮⣍⡛
⣦⣅⢵⣿⣇⣴⣽⣻⣿⣿⣦⣤⣿⣿⣷⡎⣭⣛⠛⠿⠛⠋⠁
⣿⣿⡌⣿⣏⣿⢏⣿⣿⡯⣾⣷⢽⣿⡟⣰⣶⣶⣭⣭⣛⠻⢿
⡹⣿⣿⣬⣿⣷⣿⣿⣿⣿⣾⠿⢿⣛⣘⣛⣻⡛⢿⣿⣿⣿⣶
⣷⣌⠏⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⢿⢸⣿⣿⣿⡿
⣿⣿⢃⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡿⠟⣥⣿⡔⣤⣍⣋⣴
⣿⠏⣾⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣵⡄⣶⡿⠿⢓⣸⣿⣿⣿
⡏⣼⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣄⢺⠶⠹⣿⣿⣿⣿⣿
⡇⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡏⣰⣶⣿⣿⣿⣿⣿⣿
⠷⣙⠿⣿⣿⠿⠿⠛⠻⠿⣿⣿⣿⠟⣱⣿⣿⣿⣿⣿⣿⣿⣿
⣾⣬⣭⣷⣶⣿⣿⣿⣿⣿⣶⣦⡲⠷⡙⣿⣿⣿⣿⣿⣿⣿⣿
```

## What's in the box

Every classic Unix tool gets a modern, faster, more ergonomic replacement — and they're all wired together through `fzf` so you can fuzzy-find your way through everything.

| Classic | Replacement | Why |
|---------|-------------|-----|
| `ls` | [eza](https://github.com/eza-community/eza) | Icons, colors, git integration, tree view |
| `cat` | [bat](https://github.com/sharkdp/bat) | Syntax highlighting, line numbers, git markers |
| `find` | [fd](https://github.com/sharkdp/fd) | Respects .gitignore, sane defaults, fast |
| `grep` | [ripgrep](https://github.com/BurntSushi/ripgrep) | Blazing fast recursive search |
| `cd` | [zoxide](https://github.com/ajeetdsouza/zoxide) | Learns your directories, jump with fragments |
| `du` | [dust](https://github.com/bootandy/dust) | Visual disk usage with bar charts |
| `df` | [duf](https://github.com/muesli/duf) | Pretty disk free with device grouping |
| `ps` | [procs](https://github.com/dalance/procs) | Colored, tree view, keyword search |
| `top` | [btop](https://github.com/aristocratos/btop) | Full TUI system monitor |
| `sed` | [sd](https://github.com/chmln/sd) | Normal regex syntax, no backslash hell |
| `curl` | [xh](https://github.com/ducaale/xh) | HTTPie-style ergonomics, auto JSON |
| `dig` | [doggo](https://github.com/mr-karan/doggo) | DNS lookups with color |
| `rm` | [trash-cli](https://github.com/andreafrancia/trash-cli) | Moves to trash, recoverable (Linux only) |

Plus these tools that don't replace anything — they're just essential:

| Tool | What it does |
|------|-------------|
| [fzf](https://github.com/junegunn/fzf) | Fuzzy finder that glues everything together |
| [lazygit](https://github.com/jesseduffield/lazygit) | Full git TUI — staging, rebasing, conflicts |
| [lazydocker](https://github.com/jesseduffield/lazydocker) | Docker TUI — containers, logs, stats |
| [yazi](https://github.com/sxyazi/yazi) | Terminal file manager with image preview |
| [delta](https://github.com/dandavison/delta) | Syntax-highlighted side-by-side git diffs |
| [atuin](https://github.com/atuinsh/atuin) | SQLite shell history, full-text search, cross-machine sync |
| [zellij](https://github.com/zellij-org/zellij) | Modern tmux — persistent sessions, sane defaults |
| [starship](https://github.com/starship/starship) | Cross-shell prompt with git/docker/language context |
| [navi](https://github.com/denisidoro/navi) | Interactive cheatsheets with fzf integration |
| [git-absorb](https://github.com/tummychow/git-absorb) | Auto-creates fixup commits for the right parent |
| [bandwhich](https://github.com/imsnif/bandwhich) | Per-process bandwidth usage in real time |
| [jq](https://github.com/jqlang/jq) / [yq](https://github.com/mikefarah/yq) | JSON and YAML processing |
| [xsv](https://github.com/BurntSushi/xsv) / [csvlens](https://github.com/YS-L/csvlens) | CSV toolkit and interactive viewer |
| [tldr](https://github.com/dbrgn/tealdeer) | Quick command examples (faster than man pages) |

## Quick start

### Linux (Arch/CachyOS)

```bash
git clone https://github.com/YOUR_USERNAME/supershell.git
cd supershell
chmod +x install-supershell.sh
./install-supershell.sh
```

The script will:
- Refresh pacman and install all packages (official repos + AUR via yay/paru)
- Set fish as your default shell
- Configure git delta with Dracula theme
- Add you to the docker group and enable the docker/tailscale services
- Deploy `config.fish`, `tools.txt`, and the navi cheatsheet to the right locations
- Back up any existing fish config with a timestamp

### Windows 11

```powershell
git clone https://github.com/YOUR_USERNAME/supershell.git
cd supershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
.\install-supershell.ps1
```

Uses winget + scoop. Deploys an equivalent PowerShell 7 profile with all the same aliases, functions, and shortcuts adapted for Windows.

### Flags

Both installers support:

| Flag | Linux | Windows | Effect |
|------|-------|---------|--------|
| Dry run | `--dry-run` | `-DryRun` | Preview what would be installed |
| Minimal | `--minimal` | `-Minimal` | Shell tools only, skip desktop/Docker |
| No config | `--no-config` | `-NoConfig` | Skip deploying config files |

## Custom functions

The config wires all these tools together with fzf-powered functions:

### Search & navigation

| Command | What it does |
|---------|-------------|
| `rgf <pattern>` | Ripgrep → fzf preview → open in nvim at the exact line |
| `nf` | Fuzzy find any file → open in nvim |
| `y` | Yazi file manager (your shell cd's to where you navigate) |
| `z <fragment>` | Zoxide jump — learns your directories over time |
| `j [bookmark]` | Jump to bookmarked directory (fzf picker if no argument) |
| `ss` | Fuzzy SSH host picker from `~/.ssh/config` |

### Git

| Command | What it does |
|---------|-------------|
| `lg` | Lazygit TUI |
| `gbf` | Fuzzy branch switch sorted by recent commit date |
| `gbr` | Show 10 most recently checked-out branches |
| `gfix` | Pick a commit via fzf → create fixup commit |
| `gs` `gd` `gds` `gl` `gla` `gc` `gca` `gp` `gpl` `gb` `gco` `gsw` `gst` `gsp` | Git abbreviations (expand inline on fish) |

### Docker

| Command | What it does |
|---------|-------------|
| `ld` | Lazydocker TUI |
| `dsh` | Fuzzy pick a running container → exec into it |
| `dlf` | Fuzzy pick any container → follow its logs |
| `dps` | Pretty container list (name, status, ports) |
| `dcu` `dcd` `dcr` `dcl` `dcps` | Docker compose shortcuts |

### System

| Command | What it does |
|---------|-------------|
| `ports` | Show all listening ports with process names |
| `psk` | Fuzzy process kill |
| `big [n]` | Show n biggest files/dirs (default 20) |
| `dns <domain>` | DNS lookup (A, AAAA, CNAME, MX) |
| `logtail <service>` | Follow systemd journal with bat syntax highlighting |

### Productivity

| Command | What it does |
|---------|-------------|
| `note` | View scratch notes |
| `note add <text>` | Timestamped quick note |
| `note edit` | Open notes in nvim |
| `clip` / `clipfile` / `clipwd` | Clipboard integration (Wayland wl-clipboard) |

## Three layers of "help me remember"

| Command | What it is | When to use it |
|---------|-----------|---------------|
| `shelp` | Quick reference card | "What was that alias again?" |
| `tools` | Full tool reference with descriptions and links | "What does this tool do? What's the GitHub URL?" |
| `tools <search>` | Filtered tool reference | "Show me everything related to docker" |
| `navi` | Interactive cheatsheet with fzf | "I know what I want to do but forgot the syntax" — picks a command, fills variables, runs it |

## Theme

Everything is themed [Dracula](https://draculatheme.com/) — fzf colors, bat syntax highlighting, git delta, PSReadLine (Windows), and the Pikachu startup art.

The Windows installer also outputs the Dracula color scheme for Windows Terminal settings.

## Repo structure

```
supershell/
├── .github/
│   └── workflows/
│       └── version-bump.yml               # Auto-versioning on PR merge
├── config.fish                            # Fish shell config (Linux)
├── Microsoft.PowerShell_profile.ps1       # PowerShell 7 profile (Windows)
├── tools.txt                              # Full tool reference file
├── supershell.cheat                       # Navi cheatsheet
├── install-supershell.sh                  # Linux installer (Arch/CachyOS)
├── install-supershell.ps1                 # Windows installer (winget + scoop)
├── VERSION                                # Current semver version
├── CHANGELOG.md                           # Auto-generated changelog
├── COMMIT_CONVENTION.md                   # Commit message guide
└── README.md
```

## Versioning

This repo uses [Semantic Versioning](https://semver.org/) with automatic version bumps driven by [Conventional Commits](https://www.conventionalcommits.org/).

When a PR is merged to `main`, a GitHub Action scans the commit messages and:

| Commit prefix | Version bump | Example |
|---------------|-------------|---------|
| `feat:` | **Minor** (1.0.0 → 1.1.0) | `feat: add tldr integration to shelp` |
| `fix:` `docs:` `chore:` `refactor:` `style:` `perf:` `ci:` | **Patch** (1.1.0 → 1.1.1) | `fix: rgf not handling spaces in paths` |
| `feat!:` or any `!` prefix | **Major** (1.1.1 → 2.0.0) | `feat!: rename j function to bm` |

The action updates `VERSION`, prepends to `CHANGELOG.md`, creates a git tag, and publishes a GitHub Release — all automatically. See `COMMIT_CONVENTION.md` for the full guide with examples.
```

## Requirements

**Linux:** Arch-based distro with `pacman`. AUR helper (`yay` or `paru`) needed for some packages — the script warns if missing.

**Windows:** Windows 11 with `winget` (pre-installed). Scoop is auto-installed if missing.

**Both:** A [Nerd Font](https://www.nerdfonts.com/) for icons to render. The Windows installer suggests `CascadiaCode Nerd Font` via winget.

## License

MIT — do whatever you want with it.
