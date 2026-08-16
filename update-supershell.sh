#!/usr/bin/env bash
###############################################################################
#  ⚡ Super Shell — Updater (Arch/CachyOS)
#
#  Pulls the latest configs and deploys them. Deliberately does NOT touch
#  system state: no pacman -Syu, no chsh, no docker group, no service enables,
#  no font prompt. Those belong to install-supershell.sh, which you run once
#  per machine (or again when new packages land).
#
#  Run: ./update-supershell.sh [--no-pull] [--dry-run] [--force]
###############################################################################

set -euo pipefail

# ─── Flags ──────────────────────────────────────────────────────────────
NO_PULL=false
DRY_RUN=false
FORCE=false

for arg in "$@"; do
    case "$arg" in
        --no-pull)  NO_PULL=true ;;
        --dry-run)  DRY_RUN=true ;;
        --force)    FORCE=true ;;
        --help|-h)
            cat << 'USAGE'
Usage: ./update-supershell.sh [--no-pull] [--dry-run] [--force]

  --no-pull   Deploy the working tree as-is, skip git pull
  --dry-run   Show what would change without writing anything
  --force     Pull even with uncommitted changes in the working tree

Deploys: config.fish, tools.txt, starship.toml, supershell.cheat, bash-profile
Never touches: packages, default shell, services, groups, git --global config
USAGE
            exit 0
            ;;
        *)
            echo "Unknown option: $arg (try --help)" >&2
            exit 1
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

info()    { echo -e "${CYAN}[INFO]${NC} $*"; }
ok()      { echo -e "${GREEN}[OK]${NC} $*"; }
warn()    { echo -e "${YELLOW}[WARN]${NC} $*"; }
err()     { echo -e "${RED}[ERR]${NC} $*"; }
section() { echo -e "\n${BOLD}${CYAN}── $* ──${NC}"; }

echo -e "${CYAN}"
cat << 'EOF'
╔══════════════════════════════════════════════════════╗
║  ⚡ Super Shell — Update                              ║
╚══════════════════════════════════════════════════════╝
EOF
echo -e "${NC}"

$DRY_RUN && warn "DRY RUN — nothing will be written"

# ─── Locate the clone ───────────────────────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

if ! git rev-parse --git-dir &>/dev/null; then
    err "Not a git repository: $SCRIPT_DIR"
    err "The updater pulls changes, so it needs the cloned repo — not a lone copy"
    err "of this script. Clone it: git clone https://github.com/bjschnell/SuperShell.git"
    exit 1
fi

OLD_REF="$(git rev-parse HEAD)"
OLD_VERSION="$(cat VERSION 2>/dev/null || echo unknown)"

# ─── Pull ───────────────────────────────────────────────────────────────
if ! $NO_PULL; then
    section "Pulling latest"
    BRANCH="$(git rev-parse --abbrev-ref HEAD)"

    if [ -n "$(git status --porcelain)" ]; then
        if $FORCE; then
            warn "Working tree is dirty — pulling anyway (--force)"
        else
            err "Working tree has uncommitted changes:"
            git status --short
            err "Commit or stash them, or re-run with --no-pull / --force."
            exit 1
        fi
    fi

    info "Branch: $BRANCH"
    if $DRY_RUN; then
        warn "[dry-run] Would run: git pull --ff-only"
    else
        # --ff-only: an updater should never invent a merge commit
        git pull --ff-only
    fi
else
    info "Skipping git pull (--no-pull)"
fi

NEW_REF="$(git rev-parse HEAD)"
NEW_VERSION="$(cat VERSION 2>/dev/null || echo unknown)"

# bash reads scripts lazily, so a pull that rewrote THIS file mid-run could
# execute a spliced mix of old and new. Hand off to the new copy instead.
SELF="$(basename "${BASH_SOURCE[0]}")"
if [ "$OLD_REF" != "$NEW_REF" ] && ! git diff --quiet "$OLD_REF" "$NEW_REF" -- "$SELF"; then
    info "The updater itself changed — re-running the new version"
    REEXEC=(--no-pull)
    if $DRY_RUN; then REEXEC+=(--dry-run); fi
    exec "$SCRIPT_DIR/$SELF" "${REEXEC[@]}"
fi

# ─── What changed ───────────────────────────────────────────────────────
if [ "$OLD_REF" != "$NEW_REF" ]; then
    section "Changes pulled"
    git log --oneline "$OLD_REF..$NEW_REF" | sed 's/^/  /'
    if [ "$OLD_VERSION" != "$NEW_VERSION" ]; then
        info "Version: $OLD_VERSION → $NEW_VERSION"
    fi
else
    info "Repo already at $(git rev-parse --short HEAD) — nothing new to pull"
fi

# ─── Deploy ─────────────────────────────────────────────────────────────
CHANGED=0
UNCHANGED=0

deploy() {
    local src="$1" dst="$2"

    if [ ! -f "$src" ]; then
        warn "not in repo, skipping: $(basename "$src")"
        return
    fi

    # Only back up when content actually differs — otherwise every run of the
    # updater litters the config dirs with identical .bak files.
    if [ -f "$dst" ] && cmp -s "$src" "$dst"; then
        ok "unchanged  $dst"
        UNCHANGED=$((UNCHANGED + 1))
        return
    fi

    CHANGED=$((CHANGED + 1))
    if $DRY_RUN; then
        warn "[dry-run] would update $dst"
        return
    fi

    mkdir -p "$(dirname "$dst")"
    if [ -f "$dst" ]; then
        cp "$dst" "$dst.bak.$(date +%Y%m%d_%H%M%S)"
    fi
    cp "$src" "$dst"
    ok "updated    $dst"
}

section "Deploying configs"
deploy "$SCRIPT_DIR/config.fish"      "$HOME/.config/fish/config.fish"
deploy "$SCRIPT_DIR/tools.txt"        "$HOME/.config/fish/tools.txt"
deploy "$SCRIPT_DIR/starship.toml"    "$HOME/.config/starship.toml"
deploy "$SCRIPT_DIR/supershell.cheat" "$HOME/.local/share/navi/cheats/supershell.cheat"
deploy "$SCRIPT_DIR/bash-profile"     "$HOME/.config/supershell/bash-profile"

# ─── Stamp the deployed version ─────────────────────────────────────────
# So a machine can answer "what am I running?" without guessing.
STAMP="$HOME/.config/supershell/VERSION"
if ! $DRY_RUN; then
    mkdir -p "$(dirname "$STAMP")"
    {
        echo "version=$NEW_VERSION"
        echo "commit=$(git rev-parse --short HEAD)"
        echo "branch=$(git rev-parse --abbrev-ref HEAD)"
        echo "source=$SCRIPT_DIR"
        echo "deployed=$(date '+%Y-%m-%d %H:%M:%S')"
    } > "$STAMP"
    ok "stamped    $STAMP"
fi

# ─── Tool check ─────────────────────────────────────────────────────────
# Config changes sometimes assume a tool the installer added. Check commands,
# not package names, so this stays honest regardless of pacman/AUR/manual.
section "Tool check"

REQUIRED=(fish eza bat fd fzf zoxide starship rg nvim git)
OPTIONAL=(dust duf procs sd xh doggo yazi lazygit delta lazydocker \
          atuin zellij navi tldr gh glab claude trash-put)

missing_required=()
missing_optional=()
for c in "${REQUIRED[@]}"; do
    command -v "$c" &>/dev/null || missing_required+=("$c")
done
for c in "${OPTIONAL[@]}"; do
    command -v "$c" &>/dev/null || missing_optional+=("$c")
done

if [ ${#missing_required[@]} -eq 0 ] && [ ${#missing_optional[@]} -eq 0 ]; then
    ok "All expected tools present"
else
    [ ${#missing_required[@]} -gt 0 ] && err "Missing (core):     ${missing_required[*]}"
    [ ${#missing_optional[@]} -gt 0 ] && warn "Missing (optional): ${missing_optional[*]}"
    info "Install them with: ./install-supershell.sh"
fi

# ─── Summary ────────────────────────────────────────────────────────────
section "Summary"
echo -e "  ${GREEN}$CHANGED${NC} file(s) updated, ${CYAN}$UNCHANGED${NC} already current"

if $DRY_RUN; then
    warn "Dry run — nothing was written"
elif [ $CHANGED -gt 0 ]; then
    info "Restart your shell to pick up the changes:  exec fish"
else
    ok "Everything already up to date"
fi
