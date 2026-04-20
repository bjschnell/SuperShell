#!/usr/bin/env bash
###############################################################################
#  ⚡ Super Shell — Full Environment Bootstrap for Arch/CachyOS
#  
#  Installs everything needed to recreate Brady's shell environment from
#  scratch on any fresh Arch-based system.
#
#  Run: chmod +x install-supershell.sh && ./install-supershell.sh
#  
#  Options:
#    --dry-run     Show what would be installed without installing
#    --no-config   Skip config file deployment
#    --desktop     Also install desktop/Hyprland packages
###############################################################################

set -euo pipefail

# ─── Flags ──────────────────────────────────────────────────────────────
DRY_RUN=false
NO_CONFIG=false
DESKTOP=false

for arg in "$@"; do
    case "$arg" in
        --dry-run)    DRY_RUN=true ;;
        --no-config)  NO_CONFIG=true ;;
        --desktop)    DESKTOP=true ;;
        --help|-h)
            echo "Usage: ./install-supershell.sh [--dry-run] [--no-config] [--desktop]"
            echo "  --dry-run    Show what would be installed"
            echo "  --no-config  Skip deploying config files"
            echo "  --desktop    Also install desktop/Hyprland packages"
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
║  Arch/CachyOS • Fish • Dracula                       ║
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
PACMAN_FOUNDATION=(
    base-devel                # build tools for AUR
    git                       # version control
    fish                      # shell
    neovim                    # editor
    openssh                   # ssh client/server
    wget                      # fallback fetcher
    curl                      # http client
    unzip                     # archive handling
    man-db                    # man pages
)

# ── Core shell modernization ────────────────────────────────────────────
PACMAN_SHELL_CORE=(
    eza                       # ls replacement
    bat                       # cat replacement
    fd                        # find replacement
    fzf                       # fuzzy finder
    zoxide                    # cd replacement
    starship                  # prompt
    ripgrep                   # grep replacement
)

# ── System monitoring & inspection ──────────────────────────────────────
PACMAN_SYSTEM=(
    btop                      # top replacement (TUI)
    bottom                    # alt system monitor (btm)
)

# ── Data wrangling ──────────────────────────────────────────────────────
PACMAN_DATA=(
    jq                        # JSON processor
    yq                        # YAML processor
)

# ── Git tooling ─────────────────────────────────────────────────────────
PACMAN_GIT=(
    git-delta                 # syntax-highlighted diffs
    lazygit                   # git TUI
)

# ── Network & DNS ───────────────────────────────────────────────────────
PACMAN_NETWORK=(
    doggo                     # DNS lookup tool
    tailscale                 # mesh VPN
)

# ── File management ─────────────────────────────────────────────────────
PACMAN_FILES=(
    yazi                      # terminal file manager
    trash-cli                 # safe rm
)

# ── Terminal multiplexer ────────────────────────────────────────────────
PACMAN_MULTIPLEX=(
    zellij                    # modern tmux alternative
)

# ── Shell utilities ─────────────────────────────────────────────────────
PACMAN_SHELL_UTILS=(
    tldr                      # quick command examples
)

# ── Docker ──────────────────────────────────────────────────────────────
PACMAN_DOCKER=(
    docker
    docker-compose
    docker-buildx
)

# ── Desktop / Hyprland (only with --desktop) ───────────────────────────
PACMAN_DESKTOP=(
    wl-clipboard              # Wayland clipboard (wl-copy/wl-paste)
    hyprland
    hyprpaper                 # wallpaper
    hypridle                  # idle daemon
    hyprlock                  # lock screen
    waybar                    # status bar
    wofi                      # app launcher
    dunst                     # notifications
    grim                      # screenshot
    slurp                     # region select
    swappy                    # screenshot annotation
    xdg-desktop-portal-hyprland
    polkit-kde-agent          # auth agent
    qt5-wayland
    qt6-wayland
    pipewire
    pipewire-pulse
    wireplumber
    brightnessctl
    playerctl
    kitty                     # terminal
)

# ── AUR packages — core tools ──────────────────────────────────────────
AUR_CORE=(
    dust-bin                  # visual du replacement
    duf                       # pretty df
    procs                     # modern ps
    sd                        # sed replacement
    xh                        # httpie-style curl
    xsv                       # CSV toolkit
    csvlens                   # interactive CSV viewer
    lazydocker                # docker TUI
    git-absorb                # auto fixup commits
    atuin                     # shell history sync/search
    navi                      # interactive cheatsheet
    bandwhich                 # per-process bandwidth monitor
)

# ── AUR packages — desktop extras (only with --desktop) ────────────────
AUR_DESKTOP=(
    hyprshot                  # screenshot utility for Hyprland
    swww                      # animated wallpaper daemon
    dracula-gtk-theme-git     # Dracula GTK theme
    dracula-icons-git         # Dracula icon theme
    bibata-cursor-theme       # cursor theme
)

###############################################################################
# INSTALLATION LOGIC
###############################################################################

install_pacman_group() {
    local group_name="$1"
    shift
    local pkgs=("$@")

    section "$group_name"

    local missing=()
    for pkg in "${pkgs[@]}"; do
        if ! pacman -Qi "$pkg" &>/dev/null 2>&1; then
            missing+=("$pkg")
        else
            ok "$pkg"
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
        sudo pacman -S --needed --noconfirm "${missing[@]}" || {
            err "Some packages failed — they may need AUR. Continuing..."
        }
    fi
}

install_aur_group() {
    local group_name="$1"
    shift
    local pkgs=("$@")

    section "$group_name (AUR)"

    if [ -z "${AUR_HELPER:-}" ]; then
        warn "No AUR helper — skipping $group_name"
        return
    fi

    local missing=()
    for pkg in "${pkgs[@]}"; do
        if ! pacman -Qi "$pkg" &>/dev/null 2>&1; then
            missing+=("$pkg")
        else
            ok "$pkg"
        fi
    done

    if [ ${#missing[@]} -eq 0 ]; then
        ok "All $group_name AUR packages present"
        return
    fi

    info "Missing: ${missing[*]}"
    if $DRY_RUN; then
        warn "[dry-run] Would install via $AUR_HELPER: ${missing[*]}"
    else
        $AUR_HELPER -S --needed --noconfirm "${missing[@]}" || {
            err "Some AUR packages failed. You may need to install manually."
        }
    fi
}

# ── Refresh package database ──
section "Syncing package database & upgrading"
if $DRY_RUN; then
    warn "[dry-run] Would run: sudo pacman -Syu"
else
    sudo pacman -Syu --noconfirm
    ok "System upgraded and package database synced"
fi

# ── Detect AUR helper ──
section "Detecting AUR helper"
if command -v yay &>/dev/null; then
    AUR_HELPER="yay"
    ok "AUR helper: yay"
elif command -v paru &>/dev/null; then
    AUR_HELPER="paru"
    ok "AUR helper: paru"
else
    AUR_HELPER=""
    warn "No AUR helper found (yay/paru)"
    warn "Install yay: https://github.com/Jguer/yay"
    warn "AUR packages will be skipped"
fi

# ── Install everything ──
install_pacman_group "Foundation"         "${PACMAN_FOUNDATION[@]}"
install_pacman_group "Shell Core"         "${PACMAN_SHELL_CORE[@]}"
install_pacman_group "System Monitoring"  "${PACMAN_SYSTEM[@]}"
install_pacman_group "Data Wrangling"     "${PACMAN_DATA[@]}"
install_pacman_group "Git Tooling"        "${PACMAN_GIT[@]}"
install_pacman_group "Network & DNS"      "${PACMAN_NETWORK[@]}"
install_pacman_group "File Management"    "${PACMAN_FILES[@]}"
install_pacman_group "Multiplexer"        "${PACMAN_MULTIPLEX[@]}"
install_pacman_group "Shell Utilities"    "${PACMAN_SHELL_UTILS[@]}"
install_pacman_group "Docker"             "${PACMAN_DOCKER[@]}"

if $DESKTOP; then
    install_pacman_group "Desktop / Hyprland" "${PACMAN_DESKTOP[@]}"
fi

install_aur_group "Core Tools"  "${AUR_CORE[@]}"

if $DESKTOP; then
    install_aur_group "Desktop Extras" "${AUR_DESKTOP[@]}"
fi

###############################################################################
# POST-INSTALL CONFIGURATION
###############################################################################

section "Post-install setup"

# ── Set fish as default shell ──
if command -v fish &>/dev/null; then
    FISH_PATH=$(which fish)
    if [ "$SHELL" != "$FISH_PATH" ]; then
        if ! grep -q "$FISH_PATH" /etc/shells; then
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

# ── Docker group & service ──
if command -v docker &>/dev/null; then
    if ! groups | grep -q docker; then
        info "Adding $USER to docker group"
        $DRY_RUN || sudo usermod -aG docker "$USER"
        ok "Added to docker group (re-login to take effect)"
    else
        ok "Already in docker group"
    fi
    if ! systemctl is-enabled docker &>/dev/null; then
        info "Enabling docker service"
        $DRY_RUN || sudo systemctl enable --now docker
        ok "Docker service enabled"
    else
        ok "Docker service already enabled"
    fi
fi

# ── Tailscale ──
if command -v tailscale &>/dev/null; then
    if ! systemctl is-enabled tailscaled &>/dev/null; then
        info "Enabling tailscaled service"
        $DRY_RUN || sudo systemctl enable --now tailscaled
        ok "Tailscale daemon enabled"
    else
        ok "Tailscale daemon already enabled"
    fi
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

# ── Nerd Font (required for eza icons) ──
section "Nerd Font check"
if fc-list 2>/dev/null | grep -qi "nerd"; then
    ok "Nerd Font detected"
else
    warn "No Nerd Font found — eza icons will render as broken squares"
    info "Install one with: sudo pacman -S ttf-jetbrains-mono-nerd"
    info "Or browse: https://www.nerdfonts.com/"
    if ! $DRY_RUN; then
        read -rp "Install JetBrains Mono Nerd Font now? [y/N] " font_reply
        if [[ "$font_reply" =~ ^[Yy]$ ]]; then
            sudo pacman -S --needed --noconfirm ttf-jetbrains-mono-nerd
            ok "JetBrains Mono Nerd Font installed"
        else
            warn "Skipping font install — icons may not display correctly"
        fi
    fi
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
║  │  git, fish, neovim, base-devel, openssh      │    ║
║  ├─ Shell ──────────────────────────────────────┤    ║
║  │  eza, bat, fd, fzf, rg, zoxide, starship     │    ║
║  │  atuin, zellij, navi, tldr                    │    ║
║  ├─ System ─────────────────────────────────────┤    ║
║  │  btop, btm, dust, duf, procs, bandwhich      │    ║
║  ├─ Git ────────────────────────────────────────┤    ║
║  │  lazygit, delta, git-absorb                   │    ║
║  ├─ Docker ─────────────────────────────────────┤    ║
║  │  docker, compose, buildx, lazydocker          │    ║
║  ├─ Network ────────────────────────────────────┤    ║
║  │  tailscale, doggo, xh                         │    ║
║  ├─ Data ───────────────────────────────────────┤    ║
║  │  jq, yq, sd, xsv, csvlens                    │    ║
║  └─ Desktop (with --desktop) ───────────────────┘    ║
║     hyprland, waybar, pipewire, Dracula theme        ║
║                                                      ║
║  Remaining manual steps:                             ║
║  1. Update bookmark paths in j function              ║
║  2. Log out & back in (docker group + fish default)  ║
║  3. Run 'tailscale up' if first time                 ║
║  4. Run 'shelp' to see the quick reference           ║
║                                                      ║
╚══════════════════════════════════════════════════════╝
EOF
echo -e "${NC}"

if $DRY_RUN; then
    warn "This was a dry run — nothing was actually installed"
fi
