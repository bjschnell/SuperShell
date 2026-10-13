#!/usr/bin/env bash
###############################################################################
#  ⚡ Super Shell — Full Environment Bootstrap for Arch / Debian / Ubuntu
#  
#  Installs everything needed to recreate Brady's shell environment from
#  scratch on a fresh Arch-based (pacman + AUR) or Debian/Ubuntu-based
#  (apt + Homebrew) system. The distro is detected from /etc/os-release.
#
#  Run: chmod +x install-supershell.sh && ./install-supershell.sh
#  
#  Options:
#    --dry-run     Show what would be installed without installing
#    --no-config   Skip config file deployment
#    --desktop     Also install desktop/Hyprland packages (Hyprland: Arch only)
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
║  Arch • Debian • Ubuntu • Fish • Dracula             ║
╚══════════════════════════════════════════════════════╝
EOF
echo -e "${NC}"

if $DRY_RUN; then
    warn "DRY RUN — nothing will be installed"
    echo ""
fi

# ─── Distro detection ───────────────────────────────────────────────────
# ID_LIKE catches derivatives (CachyOS/EndeavourOS/Manjaro → arch,
# Mint/Pop!_OS → ubuntu → debian) without listing every one by name.
if [ -r /etc/os-release ]; then
    # shellcheck disable=SC1091
    . /etc/os-release
fi
DISTRO_NAME="${PRETTY_NAME:-${ID:-unknown}}"
case " ${ID:-} ${ID_LIKE:-} " in
    *" arch "*)                 DISTRO="arch" ;;
    *" debian "*|*" ubuntu "*)  DISTRO="debian" ;;
    *)
        err "Unsupported distro: $DISTRO_NAME"
        err "Supported: Arch-based (pacman) and Debian/Ubuntu-based (apt)"
        exit 1
        ;;
esac
info "Detected $DISTRO_NAME → using $([ "$DISTRO" = arch ] && echo "pacman + AUR" || echo "apt + Homebrew")"

###############################################################################
# PACKAGE LISTS
###############################################################################

# ═══ Arch (pacman + AUR) ════════════════════════════════════════════════

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
    github-cli                # gh — GitHub PRs/issues/releases from the terminal
    glab                      # GitLab CLI — MRs/issues/pipelines
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

# ═══ Debian / Ubuntu (apt + Homebrew) ═══════════════════════════════════
# apt only carries the system layer. Most of the modern tools are missing
# from apt, stale (Ubuntu 22.04 ships neovim 0.6 and fzf 0.29), renamed
# (bat → batcat, fd → fdfind) or a different program entirely (apt's yq is
# the Python one). Homebrew has all of them, current, under their real names.

# ── Foundation — also everything Homebrew's installer needs ─────────────
APT_FOUNDATION=(
    build-essential           # compilers (Homebrew requirement)
    procps                    # ps & co (Homebrew requirement)
    file                      # (Homebrew requirement)
    git                       # version control
    fish                      # shell — from apt so the login shell never depends on brew
    openssh-client            # ssh client
    wget                      # fallback fetcher
    curl                      # http client
    unzip                     # archive handling
    xz-utils                  # Nerd Font archives are .tar.xz
    man-db                    # man pages
    ca-certificates           # https for third-party apt repos
    gnupg                     # repo signing keys
    fontconfig                # fc-list / fc-cache for the Nerd Font check
)

# ── Tools apt ships fine on every supported release ─────────────────────
APT_TOOLS=(
    btop                      # top replacement (TUI)
    ripgrep                   # grep replacement
    jq                        # JSON processor
    trash-cli                 # safe rm
)

# ── Desktop (only with --desktop) — Hyprland itself stays Arch-only ─────
APT_DESKTOP=(
    wl-clipboard              # Wayland clipboard (wl-copy/wl-paste)
)

# ── Homebrew formulae — everything apt lacks or gets wrong ──────────────
# xsv is absent: Homebrew disabled it (unmaintained upstream).
BREW_TOOLS=(
    neovim                    # editor (apt's is too old for modern configs)
    eza                       # ls replacement
    bat                       # cat replacement
    fd                        # find replacement
    fzf                       # fuzzy finder
    zoxide                    # cd replacement
    starship                  # prompt
    bottom                    # alt system monitor (btm)
    dust                      # visual du replacement
    duf                       # pretty df
    procs                     # modern ps
    bandwhich                 # per-process bandwidth monitor
    yq                        # YAML processor (mikefarah's, same as Arch)
    sd                        # sed replacement
    csvlens                   # interactive CSV viewer
    git-delta                 # syntax-highlighted diffs
    lazygit                   # git TUI
    git-absorb                # auto fixup commits
    gh                        # GitHub CLI
    glab                      # GitLab CLI
    doggo                     # DNS lookup tool
    xh                        # httpie-style curl
    yazi                      # terminal file manager
    zellij                    # modern tmux alternative
    atuin                     # shell history sync/search
    navi                      # interactive cheatsheet
    tealdeer                  # tldr — quick command examples
    lazydocker                # docker TUI
)

# Docker's own apt repo — distro docker.io lacks the compose/buildx plugins
# on older releases (Debian 12 still ships compose v1).
DOCKER_APT_PKGS=(
    docker-ce
    docker-ce-cli
    containerd.io
    docker-buildx-plugin
    docker-compose-plugin
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

install_apt_group() {
    local group_name="$1"
    shift
    local pkgs=("$@")

    section "$group_name"

    local missing=()
    for pkg in "${pkgs[@]}"; do
        if dpkg-query -W -f='${Status}' "$pkg" 2>/dev/null | grep -q "install ok installed"; then
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
        sudo DEBIAN_FRONTEND=noninteractive apt-get install -y "${missing[@]}" || {
            err "Some apt packages failed. Continuing..."
        }
    fi
}

install_brew_group() {
    local group_name="$1"
    shift
    local pkgs=("$@")

    section "$group_name (Homebrew)"

    if ! command -v brew &>/dev/null && ! $DRY_RUN; then
        warn "Homebrew unavailable — skipping $group_name"
        return
    fi

    # One `brew list` instead of one per formula — each call costs ~0.5s.
    local installed=""
    command -v brew &>/dev/null && installed=$(brew list --formula -1 2>/dev/null || true)

    local missing=()
    for pkg in "${pkgs[@]}"; do
        if grep -qx "$pkg" <<< "$installed"; then
            ok "$pkg"
        else
            missing+=("$pkg")
        fi
    done

    if [ ${#missing[@]} -eq 0 ]; then
        ok "All $group_name formulae present"
        return
    fi

    info "Missing: ${missing[*]}"
    if $DRY_RUN; then
        warn "[dry-run] Would install via brew: ${missing[*]}"
    else
        brew install "${missing[@]}" || {
            err "Some formulae failed. You may need to install manually."
        }
    fi
}

# Puts an existing Homebrew on PATH for the rest of this script. Checks the
# default prefix and the single-user fallback the installer may have used.
load_homebrew() {
    local b
    for b in /home/linuxbrew/.linuxbrew/bin/brew "$HOME/.linuxbrew/bin/brew"; do
        if [ -x "$b" ]; then
            eval "$("$b" shellenv)"
            return 0
        fi
    done
    return 1
}

ensure_homebrew() {
    section "Homebrew"
    if command -v brew &>/dev/null || load_homebrew; then
        ok "Homebrew: $(command -v brew)"
        return
    fi
    if [ "$(id -u)" -eq 0 ]; then
        err "Homebrew refuses to run as root — re-run this script as your normal user"
        return
    fi
    info "Installing Homebrew (needs sudo to create /home/linuxbrew)..."
    if $DRY_RUN; then
        warn "[dry-run] Would run the Homebrew installer from https://brew.sh"
        return
    fi
    # NONINTERACTIVE skips the "press RETURN" prompt; it uses `sudo -n`, which
    # works because the apt steps above already cached sudo credentials.
    sudo -v
    NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" || true
    if load_homebrew; then
        ok "Homebrew installed"
    else
        err "Homebrew install failed — Homebrew packages will be skipped"
    fi
}

install_docker_apt() {
    section "Docker (download.docker.com)"
    if command -v docker &>/dev/null; then
        ok "docker already installed ($(command -v docker))"
        return
    fi
    # Derivatives (Mint, Pop!_OS) carry their own VERSION_CODENAME; Docker
    # publishes for the Ubuntu base, which they expose as UBUNTU_CODENAME.
    local repo_os="debian" codename="${VERSION_CODENAME:-}"
    if [ -n "${UBUNTU_CODENAME:-}" ]; then
        repo_os="ubuntu"
        codename="$UBUNTU_CODENAME"
    fi
    if [ -z "$codename" ]; then
        err "Can't determine release codename — skipping Docker"
        return
    fi
    if $DRY_RUN; then
        warn "[dry-run] Would add the Docker apt repo ($repo_os $codename) and install: ${DOCKER_APT_PKGS[*]}"
        return
    fi
    sudo install -m 0755 -d /etc/apt/keyrings
    sudo curl -fsSL "https://download.docker.com/linux/$repo_os/gpg" -o /etc/apt/keyrings/docker.asc
    sudo chmod a+r /etc/apt/keyrings/docker.asc
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/$repo_os $codename stable" \
        | sudo tee /etc/apt/sources.list.d/docker.list >/dev/null
    if sudo apt-get update && sudo DEBIAN_FRONTEND=noninteractive apt-get install -y "${DOCKER_APT_PKGS[@]}"; then
        ok "Docker installed"
    else
        err "Docker install failed — is $repo_os/$codename published at download.docker.com?"
    fi
}

install_tailscale_apt() {
    section "Tailscale"
    if command -v tailscale &>/dev/null; then
        ok "tailscale already installed"
        return
    fi
    if $DRY_RUN; then
        warn "[dry-run] Would run: curl -fsSL https://tailscale.com/install.sh | sh"
        return
    fi
    # Tailscale's script adds their apt repo for the detected release.
    curl -fsSL https://tailscale.com/install.sh | sh || err "Tailscale install failed"
}

if [ "$DISTRO" = arch ]; then
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
else
    # ── Refresh package database ──
    section "Syncing package database & upgrading"
    if $DRY_RUN; then
        warn "[dry-run] Would run: sudo apt-get update && sudo apt-get upgrade"
    else
        sudo apt-get update
        sudo DEBIAN_FRONTEND=noninteractive apt-get upgrade -y
        ok "System upgraded and package database synced"
    fi

    install_apt_group "Foundation"  "${APT_FOUNDATION[@]}"
    install_apt_group "Tools (apt)" "${APT_TOOLS[@]}"

    if $DESKTOP; then
        install_apt_group "Desktop" "${APT_DESKTOP[@]}"
        warn "Hyprland and the desktop theme packages are Arch-only — skipped"
    fi

    install_docker_apt
    install_tailscale_apt

    ensure_homebrew
    install_brew_group "Core Tools" "${BREW_TOOLS[@]}"
    info "xsv isn't available on Debian/Ubuntu (Homebrew disabled it) — csvlens covers viewing"
fi

# ── Claude Code CLI (official installer — auto-updates, not AUR-lagged) ──
section "Claude Code CLI"
if command -v claude &>/dev/null; then
    ok "Claude Code CLI already installed"
else
    info "Installing Claude Code CLI..."
    if $DRY_RUN; then
        warn "[dry-run] Would run: curl -fsSL https://claude.ai/install.sh | bash"
    else
        curl -fsSL https://claude.ai/install.sh | bash
        if [ -x "$HOME/.local/bin/claude" ] || command -v claude &>/dev/null; then
            ok "Claude Code CLI installed"
        else
            err "Claude Code CLI install may have failed — check output above"
        fi
    fi
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
        # sudo: plain chsh prompts for the password again (and fails under
        # curl | bash); the credentials are already cached from the installs.
        $DRY_RUN || sudo chsh -s "$FISH_PATH" "$USER"
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

# ── gh / glab auth status ──
if command -v gh &>/dev/null; then
    if gh auth status &>/dev/null; then
        ok "gh already authenticated"
    else
        warn "gh installed but not authenticated — run 'gh auth login'"
    fi
fi
if command -v glab &>/dev/null; then
    if glab auth status &>/dev/null; then
        ok "glab already authenticated"
    else
        warn "glab installed but not authenticated — run 'glab auth login'"
    fi
fi
if command -v claude &>/dev/null; then
    if claude auth status &>/dev/null; then
        ok "Claude Code already authenticated"
    else
        warn "Claude Code installed but not logged in — run 'claude' and follow the login prompt"
    fi
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
    if [ "$DISTRO" = arch ]; then
        info "Install one with: sudo pacman -S ttf-jetbrains-mono-nerd"
    else
        info "Install one from: https://github.com/ryanoasis/nerd-fonts/releases"
    fi
    info "Or browse: https://www.nerdfonts.com/"
    # `set -e` + a non-TTY stdin (curl | bash) made a failed read abort the
    # whole script here, before any config was deployed.
    if ! $DRY_RUN && [ -t 0 ]; then
        font_reply=""
        read -rp "Install JetBrains Mono Nerd Font now? [y/N] " font_reply || true
        if [[ "$font_reply" =~ ^[Yy]$ ]]; then
            if [ "$DISTRO" = arch ]; then
                sudo pacman -S --needed --noconfirm ttf-jetbrains-mono-nerd
            else
                # Not packaged for apt, and Homebrew's font casks are macOS-only.
                FONT_DIR="$HOME/.local/share/fonts/JetBrainsMonoNerd"
                mkdir -p "$FONT_DIR"
                curl -fsSL https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.tar.xz \
                    | tar -xJ -C "$FONT_DIR"
                fc-cache -f "$FONT_DIR" >/dev/null
            fi
            ok "JetBrains Mono Nerd Font installed"
        else
            warn "Skipping font install — icons may not display correctly"
        fi
    elif ! $DRY_RUN; then
        warn "Non-interactive stdin — skipping the font prompt"
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

    # Deploy the bash companion profile. Not sourced automatically — editing
    # someone's .bashrc behind their back is worse than a one-line hint.
    BASH_SRC="$SCRIPT_DIR/bash-profile"
    BASH_DST="$HOME/.config/supershell/bash-profile"
    if [ -f "$BASH_SRC" ]; then
        $DRY_RUN || mkdir -p "$HOME/.config/supershell"
        info "Deploying bash-profile → $BASH_DST"
        $DRY_RUN || cp "$BASH_SRC" "$BASH_DST"
        ok "Bash profile deployed"
        if ! grep -qs "supershell/bash-profile" "$HOME/.bashrc"; then
            info "To use it in bash, add to ~/.bashrc:"
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
║  │  git, fish, neovim, base-devel, openssh      │    ║
║  ├─ Shell ──────────────────────────────────────┤    ║
║  │  eza, bat, fd, fzf, rg, zoxide, starship     │    ║
║  │  atuin, zellij, navi, tldr                    │    ║
║  ├─ System ─────────────────────────────────────┤    ║
║  │  btop, btm, dust, duf, procs, bandwhich      │    ║
║  ├─ Git ────────────────────────────────────────┤    ║
║  │  lazygit, delta, git-absorb, gh, glab         │    ║
║  ├─ AI ──────────────────────────────────────────┤    ║
║  │  Claude Code CLI                                │    ║
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
║  4. Run 'gh auth login' / 'glab auth login' if not   ║
║     already authenticated                             ║
║  5. Run 'claude' and log in if first time             ║
║  6. Run 'shelp' to see the quick reference           ║
║                                                      ║
╚══════════════════════════════════════════════════════╝
EOF
echo -e "${NC}"

if $DRY_RUN; then
    warn "This was a dry run — nothing was actually installed"
fi
