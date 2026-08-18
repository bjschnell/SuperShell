#!/usr/bin/env bash
###############################################################################
#  ⚡ Super Shell — Full Environment Bootstrap for macOS
#
#  Installs everything needed to recreate Brady's shell environment from
#  scratch on a fresh macOS machine, using Homebrew.
#
#  Run: chmod +x install-supershell-macos.sh && ./install-supershell-macos.sh
#
#  Options:
#    --dry-run     Show what would be installed without installing
#    --no-config   Skip config file deployment
###############################################################################

set -euo pipefail

# ─── Flags ──────────────────────────────────────────────────────────────
DRY_RUN=false
NO_CONFIG=false

for arg in "$@"; do
    case "$arg" in
        --dry-run)    DRY_RUN=true ;;
        --no-config)  NO_CONFIG=true ;;
        --help|-h)
            echo "Usage: ./install-supershell-macos.sh [--dry-run] [--no-config]"
            echo "  --dry-run    Show what would be installed"
            echo "  --no-config  Skip deploying config files"
            exit 0
            ;;
    esac
done

# ─── Colors & Helpers ───────────────────────────────────────────────────
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
RED='\033[0;31m'
BOLD='\033[1m'
NC='\033[0m'

info()  { echo -e "${CYAN}[INFO]${NC} $*"; }
ok()    { echo -e "${GREEN}[OK]${NC} $*"; }
warn()  { echo -e "${YELLOW}[WARN]${NC} $*"; }
err()   { echo -e "${RED}[ERR]${NC} $*"; }
section() { echo -e "\n${BOLD}${CYAN}── $* ──${NC}"; }

echo -e "${CYAN}"
cat << 'EOF'
╔══════════════════════════════════════════════════════╗
║  ⚡ Super Shell — Full Environment Bootstrap          ║
║                                                      ║
║  macOS • Fish • Dracula                              ║
╚══════════════════════════════════════════════════════╝
EOF
echo -e "${NC}"

if $DRY_RUN; then
    warn "DRY RUN — nothing will be installed"
    echo ""
fi

###############################################################################
# PACKAGE LISTS
###############################################################################

# ── Foundational — needs to exist before anything else ──────────────────
BREW_FOUNDATION=(
    git                       # version control (Homebrew's newer build)
    fish                      # shell
    neovim                    # editor
    wget                      # fallback fetcher
    curl                      # http client
)

# ── Core shell modernization ────────────────────────────────────────────
BREW_SHELL_CORE=(
    eza                       # ls replacement
    bat                       # cat replacement
    fd                        # find replacement
    fzf                       # fuzzy finder
    zoxide                    # cd replacement
    starship                  # prompt
    ripgrep                   # grep replacement
)

# ── System monitoring & inspection ──────────────────────────────────────
BREW_SYSTEM=(
    btop                      # top replacement (TUI)
    bottom                    # alt system monitor (btm)
    dust                      # visual du replacement
    duf                       # pretty df
    procs                     # modern ps
    bandwhich                 # per-process bandwidth monitor
)

# ── Data wrangling ──────────────────────────────────────────────────────
BREW_DATA=(
    jq                        # JSON processor
    yq                        # YAML processor
    sd                        # sed replacement
    xsv                       # CSV toolkit
    csvlens                   # interactive CSV viewer
)

# ── Git tooling ─────────────────────────────────────────────────────────
BREW_GIT=(
    git-delta                 # syntax-highlighted diffs
    lazygit                   # git TUI
    git-absorb                # auto fixup commits
)

# ── Network & DNS ───────────────────────────────────────────────────────
BREW_NETWORK=(
    xh                        # httpie-style curl
    doggo                     # DNS lookup tool
)

# ── File management ─────────────────────────────────────────────────────
BREW_FILES=(
    yazi                      # terminal file manager
    trash                     # safe rm (moves to macOS Trash)
)

# ── Shell utilities ─────────────────────────────────────────────────────
BREW_SHELL_UTILS=(
    atuin                     # shell history sync/search
    zellij                    # modern tmux alternative
    navi                      # interactive cheatsheet
    tealdeer                  # tldr client (provides 'tldr')
)

# ── Fonts (Homebrew Cask) ───────────────────────────────────────────────
BREW_CASK_FONTS=(
    font-jetbrains-mono-nerd-font   # Nerd Font for eza icons
)

###############################################################################
# INSTALLATION LOGIC
###############################################################################

install_brew_group() {
    local group_name="$1"
    shift
    local pkgs=("$@")

    section "$group_name"

    local missing=()
    for pkg in "${pkgs[@]}"; do
        if brew list --formula "$pkg" &>/dev/null; then
            ok "$pkg"
        else
            missing+=("$pkg")
        fi
    done

    if [ ${#missing[@]} -eq 0 ]; then
        ok "All $group_name packages present"
        return
    fi

    info "Missing: ${missing[*]}"
    if $DRY_RUN; then
        warn "[dry-run] Would install: ${missing[*]}"
    else
        brew install "${missing[@]}" || {
            err "Some packages failed to install. Continuing..."
        }
    fi
}

install_cask_group() {
    local group_name="$1"
    shift
    local pkgs=("$@")

    section "$group_name (Cask)"

    local missing=()
    for pkg in "${pkgs[@]}"; do
        if brew list --cask "$pkg" &>/dev/null; then
            ok "$pkg"
        else
            missing+=("$pkg")
        fi
    done

    if [ ${#missing[@]} -eq 0 ]; then
        ok "All $group_name casks present"
        return
    fi

    info "Missing: ${missing[*]}"
    if $DRY_RUN; then
        warn "[dry-run] Would install cask: ${missing[*]}"
    else
        brew install --cask "${missing[@]}" || {
            err "Some casks failed to install. Continuing..."
        }
    fi
}

# ── Ensure Homebrew is installed ──
section "Checking for Homebrew"
if ! command -v brew &>/dev/null; then
    warn "Homebrew not found"
    if $DRY_RUN; then
        warn "[dry-run] Would install Homebrew from https://brew.sh"
    else
        read -rp "Install Homebrew now? [y/N] " brew_reply
        if [[ "$brew_reply" =~ ^[Yy]$ ]]; then
            /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
            # Load brew into this shell (Apple Silicon vs Intel prefix)
            if [ -x /opt/homebrew/bin/brew ]; then
                eval "$(/opt/homebrew/bin/brew shellenv)"
            elif [ -x /usr/local/bin/brew ]; then
                eval "$(/usr/local/bin/brew shellenv)"
            fi
            ok "Homebrew installed"
        else
            err "Homebrew is required. Aborting."
            exit 1
        fi
    fi
else
    ok "Homebrew: $(brew --version | head -1)"
fi

# ── Refresh Homebrew ──
section "Updating Homebrew"
if $DRY_RUN; then
    warn "[dry-run] Would run: brew update"
else
    brew update
    ok "Homebrew updated"
fi

# ── Install everything ──
install_brew_group "Foundation"         "${BREW_FOUNDATION[@]}"
install_brew_group "Shell Core"         "${BREW_SHELL_CORE[@]}"
install_brew_group "System Monitoring"  "${BREW_SYSTEM[@]}"
install_brew_group "Data Wrangling"     "${BREW_DATA[@]}"
install_brew_group "Git Tooling"        "${BREW_GIT[@]}"
install_brew_group "Network & DNS"      "${BREW_NETWORK[@]}"
install_brew_group "File Management"    "${BREW_FILES[@]}"
install_brew_group "Shell Utilities"    "${BREW_SHELL_UTILS[@]}"

install_cask_group "Fonts"              "${BREW_CASK_FONTS[@]}"

###############################################################################
# POST-INSTALL CONFIGURATION
###############################################################################

section "Post-install setup"

# ── Set fish as default shell ──
if command -v fish &>/dev/null; then
    FISH_PATH="$(brew --prefix)/bin/fish"
    [ -x "$FISH_PATH" ] || FISH_PATH="$(command -v fish)"
    if [ "$SHELL" != "$FISH_PATH" ]; then
        if ! grep -q "^$FISH_PATH\$" /etc/shells 2>/dev/null; then
            info "Adding fish to /etc/shells"
            $DRY_RUN || echo "$FISH_PATH" | sudo tee -a /etc/shells >/dev/null
        fi
        info "Setting fish as default shell"
        $DRY_RUN || chsh -s "$FISH_PATH"
        ok "Default shell set to fish"
    else
        ok "Fish is already default shell"
    fi
fi

# ── Git delta config ──
if command -v delta &>/dev/null && ! $DRY_RUN; then
    git config --global core.pager delta
    git config --global interactive.diffFilter "delta --color-only"
    git config --global delta.navigate true
    git config --global delta.side-by-side true
    git config --global delta.line-numbers true
    git config --global delta.syntax-theme "Dracula"
    git config --global merge.conflictstyle diff3
    git config --global diff.colorMoved default
    ok "Git delta configured (Dracula theme)"
fi

# ── Atuin setup ──
if command -v atuin &>/dev/null && ! $DRY_RUN; then
    atuin import auto 2>/dev/null || true
    ok "Atuin history import attempted"
fi

# ── Zellij default config ──
ZELLIJ_DIR="$HOME/.config/zellij"
if command -v zellij &>/dev/null && [ ! -f "$ZELLIJ_DIR/config.kdl" ] && ! $DRY_RUN; then
    mkdir -p "$ZELLIJ_DIR"
    zellij setup --dump-config > "$ZELLIJ_DIR/config.kdl"
    ok "Zellij default config created"
fi

###############################################################################
# CONFIG FILE DEPLOYMENT
###############################################################################

if ! $NO_CONFIG; then
    section "Config deployment"

    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    FISH_CONFIG_SRC="$SCRIPT_DIR/config.fish"
    FISH_CONFIG_DST="$HOME/.config/fish/config.fish"

    if [ -f "$FISH_CONFIG_SRC" ]; then
        mkdir -p "$HOME/.config/fish"

        if [ -f "$FISH_CONFIG_DST" ]; then
            BACKUP="$FISH_CONFIG_DST.bak.$(date +%Y%m%d_%H%M%S)"
            info "Backing up existing config → $BACKUP"
            $DRY_RUN || cp "$FISH_CONFIG_DST" "$BACKUP"
        fi

        info "Deploying config.fish → $FISH_CONFIG_DST"
        $DRY_RUN || cp "$FISH_CONFIG_SRC" "$FISH_CONFIG_DST"
        ok "Fish config deployed"
    else
        warn "config.fish not found next to this script — skipping"
        warn "Expected at: $FISH_CONFIG_SRC"
    fi

    # Deploy tools.txt reference
    TOOLS_SRC="$SCRIPT_DIR/tools.txt"
    TOOLS_DST="$HOME/.config/fish/tools.txt"
    if [ -f "$TOOLS_SRC" ]; then
        info "Deploying tools.txt → $TOOLS_DST"
        $DRY_RUN || cp "$TOOLS_SRC" "$TOOLS_DST"
        ok "Tools reference deployed"
    fi

    # Deploy the bash companion profile. Not sourced automatically — editing
    # someone's ~/.bash_profile behind their back is worse than a one-line hint.
    BASH_SRC="$SCRIPT_DIR/bash-profile"
    BASH_DST="$HOME/.config/supershell/bash-profile"
    if [ -f "$BASH_SRC" ]; then
        $DRY_RUN || mkdir -p "$HOME/.config/supershell"
        info "Deploying bash-profile → $BASH_DST"
        $DRY_RUN || cp "$BASH_SRC" "$BASH_DST"
        ok "Bash profile deployed"
        if ! grep -qs "supershell/bash-profile" "$HOME/.bash_profile"; then
            info "To use it in bash, add to ~/.bash_profile:"
            info "  source \"\$HOME/.config/supershell/bash-profile\""
        fi
    fi

    # Deploy starship config
    STARSHIP_SRC="$SCRIPT_DIR/starship.toml"
    STARSHIP_DST="$HOME/.config/starship.toml"
    if [ -f "$STARSHIP_SRC" ]; then
        if [ -f "$STARSHIP_DST" ]; then
            BACKUP="$STARSHIP_DST.bak.$(date +%Y%m%d_%H%M%S)"
            info "Backing up existing starship config → $BACKUP"
            $DRY_RUN || cp "$STARSHIP_DST" "$BACKUP"
        fi
        info "Deploying starship.toml → $STARSHIP_DST"
        $DRY_RUN || cp "$STARSHIP_SRC" "$STARSHIP_DST"
        ok "Starship config deployed (Dracula theme)"
    fi

    # Deploy navi cheatsheet
    NAVI_SRC="$SCRIPT_DIR/supershell.cheat"
    NAVI_DST="$HOME/.local/share/navi/cheats/supershell.cheat"
    if [ -f "$NAVI_SRC" ]; then
        mkdir -p "$HOME/.local/share/navi/cheats"
        info "Deploying navi cheatsheet → $NAVI_DST"
        $DRY_RUN || cp "$NAVI_SRC" "$NAVI_DST"
        ok "Navi cheatsheet deployed"
    fi

    # Create notes directory for the note function
    $DRY_RUN || mkdir -p "$HOME/notes"
fi

###############################################################################
# SUMMARY
###############################################################################

echo ""
echo -e "${GREEN}"
cat << 'EOF'
╔══════════════════════════════════════════════════════╗
║  ✅ Super Shell installation complete!                ║
╠══════════════════════════════════════════════════════╣
║                                                      ║
║  What was set up:                                    ║
║  ┌─ Foundation ─────────────────────────────────┐    ║
║  │  git, fish, neovim                            │    ║
║  ├─ Shell ──────────────────────────────────────┤    ║
║  │  eza, bat, fd, fzf, rg, zoxide, starship     │    ║
║  │  atuin, zellij, navi, tldr                    │    ║
║  ├─ System ─────────────────────────────────────┤    ║
║  │  btop, btm, dust, duf, procs, bandwhich      │    ║
║  ├─ Git ────────────────────────────────────────┤    ║
║  │  lazygit, delta, git-absorb                   │    ║
║  ├─ Network ────────────────────────────────────┤    ║
║  │  doggo, xh                                    │    ║
║  ├─ Data ───────────────────────────────────────┤    ║
║  │  jq, yq, sd, xsv, csvlens                    │    ║
║  └─ Font ───────────────────────────────────────┘    ║
║     JetBrains Mono Nerd Font                          ║
║                                                      ║
║  Remaining manual steps:                             ║
║  1. Update bookmark paths in j function              ║
║  2. Open a new terminal (fish is now default)        ║
║  3. Set your terminal font to JetBrainsMono Nerd Font║
║  4. Run 'shelp' to see the quick reference           ║
║                                                      ║
╚══════════════════════════════════════════════════════╝
EOF
echo -e "${NC}"

if $DRY_RUN; then
    warn "This was a dry run — nothing was actually installed"
fi
