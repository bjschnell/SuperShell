<#
.SYNOPSIS
    ⚡ Super Shell — Full Environment Bootstrap for Windows 11

.DESCRIPTION
    Installs everything needed to recreate Brady's shell environment on Windows.
    Uses winget (primary) and scoop (for tools not in winget).

    Run from an ELEVATED PowerShell 7 prompt:
        Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
        .\install-supershell.ps1

.PARAMETER DryRun
    Show what would be installed without installing.

.PARAMETER NoConfig
    Skip deploying the PowerShell profile.

.PARAMETER Minimal
    Only install core shell tools, skip Docker Desktop and extras.
#>

param(
    [switch]$DryRun,
    [switch]$NoConfig,
    [switch]$Minimal
)

$ErrorActionPreference = "Continue"

# ─── Colors & Helpers ───────────────────────────────────────────────────
function Write-Info    { param($msg) Write-Host "[INFO] $msg" -ForegroundColor Cyan }
function Write-Ok      { param($msg) Write-Host "[OK]   $msg" -ForegroundColor Green }
function Write-Warn    { param($msg) Write-Host "[WARN] $msg" -ForegroundColor Yellow }
function Write-Err     { param($msg) Write-Host "[ERR]  $msg" -ForegroundColor Red }
function Write-Section { param($msg) Write-Host "`n── $msg ──" -ForegroundColor Cyan }

Write-Host @"

╔══════════════════════════════════════════════════════╗
║  ⚡ Super Shell — Windows 11 Bootstrap                ║
║                                                      ║
║  PowerShell 7 • Dracula • Windows Terminal           ║
╚══════════════════════════════════════════════════════╝

"@ -ForegroundColor Cyan

if ($DryRun) {
    Write-Warn "DRY RUN — nothing will be installed"
    Write-Host ""
}

###############################################################################
# PACKAGE LISTS
#
# Format: @{ Id = "winget.package.id"; Name = "display name" }
# Use Scoop for anything not in winget (marked separately)
###############################################################################

# ── Foundation ──────────────────────────────────────────────────────────
$WingetFoundation = @(
    @{ Id = "Microsoft.PowerShell";       Name = "PowerShell 7" }
    @{ Id = "Microsoft.WindowsTerminal";  Name = "Windows Terminal" }
    @{ Id = "Git.Git";                    Name = "Git" }
    @{ Id = "Neovim.Neovim";             Name = "Neovim" }
    @{ Id = "OpenSSH.OpenSSH";           Name = "OpenSSH" }
)

# ── Core shell modernization ───────────────────────────────────────────
$WingetShellCore = @(
    @{ Id = "eza-community.eza";          Name = "eza (ls)" }
    @{ Id = "sharkdp.bat";               Name = "bat (cat)" }
    @{ Id = "sharkdp.fd";                Name = "fd (find)" }
    @{ Id = "junegunn.fzf";              Name = "fzf" }
    @{ Id = "ajeetdsouza.zoxide";        Name = "zoxide (cd)" }
    @{ Id = "Starship.Starship";         Name = "Starship prompt" }
    @{ Id = "BurntSushi.ripgrep.MSVC";   Name = "ripgrep (grep)" }
)

# ── System monitoring ──────────────────────────────────────────────────
$WingetSystem = @(
    @{ Id = "aristocratos.btop4win";     Name = "btop" }
    @{ Id = "ClementTsang.bottom";       Name = "bottom (btm)" }
)

# ── Data wrangling ─────────────────────────────────────────────────────
$WingetData = @(
    @{ Id = "jqlang.jq";                 Name = "jq" }
    @{ Id = "MikeFarah.yq";              Name = "yq" }
)

# ── Git tooling ────────────────────────────────────────────────────────
$WingetGit = @(
    @{ Id = "dandavison.delta";          Name = "delta (git pager)" }
    @{ Id = "JesseDuffield.lazygit";     Name = "lazygit" }
)

# ── Network ────────────────────────────────────────────────────────────
$WingetNetwork = @(
    @{ Id = "tailscale.tailscale";       Name = "Tailscale" }
    @{ Id = "ducaale.xh";               Name = "xh (curl)" }
)

# ── File management ────────────────────────────────────────────────────
$WingetFiles = @(
    @{ Id = "sxyazi.yazi";               Name = "yazi" }
)

# ── Shell utilities ────────────────────────────────────────────────────
$WingetShellUtils = @(
    @{ Id = "dbrgn.tealdeer";            Name = "tldr" }
)

# ── Docker (skipped with -Minimal) ────────────────────────────────────
$WingetDocker = @(
    @{ Id = "Docker.DockerDesktop";      Name = "Docker Desktop" }
)

# ── Scoop-only packages (not in winget or better via scoop) ────────────
$ScoopCore = @(
    "dust"            # visual du
    "duf"             # pretty df
    "procs"           # modern ps
    "sd"              # sed replacement
    "xsv"             # CSV toolkit
    "lazydocker"      # docker TUI
    "navi"            # interactive cheatsheet
    "doggo"           # DNS lookup
    "atuin"           # shell history
)

# These may or may not be in scoop — install what's available
$ScoopExtras = @(
    "csvlens"         # interactive CSV viewer
    "git-absorb"      # auto fixup commits
    "bandwhich"       # per-process bandwidth
    "zellij"          # multiplexer
)

###############################################################################
# INSTALLATION LOGIC
###############################################################################

function Install-WingetGroup {
    param(
        [string]$GroupName,
        [array]$Packages
    )

    Write-Section $GroupName

    foreach ($pkg in $Packages) {
        # Check if already installed
        $installed = winget list --id $pkg.Id --accept-source-agreements 2>$null |
            Select-String $pkg.Id
        
        if ($installed) {
            Write-Ok "$($pkg.Name)"
        } else {
            Write-Info "Installing $($pkg.Name)..."
            if (-not $DryRun) {
                winget install --id $pkg.Id --accept-package-agreements --accept-source-agreements --silent 2>$null
                if ($LASTEXITCODE -eq 0) {
                    Write-Ok "$($pkg.Name) installed"
                } else {
                    Write-Err "Failed to install $($pkg.Name) — may need manual install"
                }
            } else {
                Write-Warn "[dry-run] Would install: $($pkg.Name) ($($pkg.Id))"
            }
        }
    }
}

function Install-ScoopGroup {
    param(
        [string]$GroupName,
        [array]$Packages
    )

    Write-Section "$GroupName (Scoop)"

    if (-not (Get-Command scoop -ErrorAction SilentlyContinue)) {
        Write-Warn "Scoop not installed — skipping $GroupName"
        return
    }

    foreach ($pkg in $Packages) {
        $installed = scoop list $pkg 2>$null | Select-String $pkg
        if ($installed) {
            Write-Ok $pkg
        } else {
            Write-Info "Installing $pkg..."
            if (-not $DryRun) {
                scoop install $pkg 2>$null
                if ($LASTEXITCODE -eq 0) {
                    Write-Ok "$pkg installed"
                } else {
                    Write-Err "Failed: $pkg — may not be in current buckets"
                }
            } else {
                Write-Warn "[dry-run] Would install via scoop: $pkg"
            }
        }
    }
}

# ── Ensure scoop is available ──
Write-Section "Package manager setup"

if (Get-Command winget -ErrorAction SilentlyContinue) {
    Write-Ok "winget available"
} else {
    Write-Err "winget not found — install App Installer from the Microsoft Store"
    exit 1
}

if (-not (Get-Command scoop -ErrorAction SilentlyContinue)) {
    Write-Info "Installing Scoop..."
    if (-not $DryRun) {
        Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser -Force
        Invoke-RestMethod -Uri https://get.scoop.sh | Invoke-Expression
    } else {
        Write-Warn "[dry-run] Would install Scoop"
    }
}

# Add scoop extras bucket (many tools live here)
if (Get-Command scoop -ErrorAction SilentlyContinue) {
    Write-Info "Ensuring scoop buckets..."
    if (-not $DryRun) {
        scoop bucket add extras 2>$null
        scoop bucket add main 2>$null
    }
    Write-Ok "Scoop buckets ready"
}

# ── Install everything ──
Install-WingetGroup "Foundation"         $WingetFoundation
Install-WingetGroup "Shell Core"         $WingetShellCore
Install-WingetGroup "System Monitoring"  $WingetSystem
Install-WingetGroup "Data Wrangling"     $WingetData
Install-WingetGroup "Git Tooling"        $WingetGit
Install-WingetGroup "Network"            $WingetNetwork
Install-WingetGroup "File Management"    $WingetFiles
Install-WingetGroup "Shell Utilities"    $WingetShellUtils

if (-not $Minimal) {
    Install-WingetGroup "Docker" $WingetDocker
}

Install-ScoopGroup "Core Tools"  $ScoopCore
Install-ScoopGroup "Extra Tools" $ScoopExtras

###############################################################################
# POST-INSTALL CONFIGURATION
###############################################################################

Write-Section "Post-install setup"

# ── Git delta config ──
if (Get-Command delta -ErrorAction SilentlyContinue) {
    if (-not $DryRun) {
        git config --global core.pager delta
        git config --global interactive.diffFilter "delta --color-only"
        git config --global delta.navigate $true
        git config --global delta.side-by-side $true
        git config --global delta.line-numbers $true
        git config --global delta.syntax-theme "Dracula"
        git config --global merge.conflictstyle diff3
        git config --global diff.colorMoved default
    }
    Write-Ok "Git delta configured (Dracula theme)"
}

# ── Atuin setup ──
if (Get-Command atuin -ErrorAction SilentlyContinue) {
    if (-not $DryRun) {
        atuin import auto 2>$null
    }
    Write-Ok "Atuin history import attempted"
}

###############################################################################
# PROFILE DEPLOYMENT
###############################################################################

if (-not $NoConfig) {
    Write-Section "Profile deployment"

    $ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
    $ProfileSrc = Join-Path $ScriptDir "Microsoft.PowerShell_profile.ps1"
    $ProfileDir = Split-Path -Parent $PROFILE
    $ProfileDst = $PROFILE

    if (Test-Path $ProfileSrc) {
        # Ensure profile directory exists
        if (-not (Test-Path $ProfileDir)) {
            Write-Info "Creating profile directory: $ProfileDir"
            if (-not $DryRun) {
                New-Item -ItemType Directory -Path $ProfileDir -Force | Out-Null
            }
        }

        # Backup existing profile
        if (Test-Path $ProfileDst) {
            $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
            $backup = "$ProfileDst.bak.$timestamp"
            Write-Info "Backing up existing profile → $backup"
            if (-not $DryRun) {
                Copy-Item $ProfileDst $backup
            }
        }

        Write-Info "Deploying profile → $ProfileDst"
        if (-not $DryRun) {
            Copy-Item $ProfileSrc $ProfileDst -Force
        }
        Write-Ok "PowerShell profile deployed"
    } else {
        Write-Warn "Microsoft.PowerShell_profile.ps1 not found next to this script"
        Write-Warn "Expected at: $ProfileSrc"
    }

    # Deploy tools.txt reference
    $ToolsSrc = Join-Path $ScriptDir "tools.txt"
    $ToolsDir = Join-Path $env:USERPROFILE ".config\supershell"
    $ToolsDst = Join-Path $ToolsDir "tools.txt"
    if (Test-Path $ToolsSrc) {
        if (-not (Test-Path $ToolsDir)) {
            if (-not $DryRun) {
                New-Item -ItemType Directory -Path $ToolsDir -Force | Out-Null
            }
        }
        Write-Info "Deploying tools.txt → $ToolsDst"
        if (-not $DryRun) {
            Copy-Item $ToolsSrc $ToolsDst -Force
        }
        Write-Ok "Tools reference deployed"
    }

    # Deploy navi cheatsheet
    $NaviSrc = Join-Path $ScriptDir "supershell.cheat"
    $NaviDir = Join-Path $env:APPDATA "navi\cheats"
    $NaviDst = Join-Path $NaviDir "supershell.cheat"
    if (Test-Path $NaviSrc) {
        if (-not (Test-Path $NaviDir)) {
            if (-not $DryRun) {
                New-Item -ItemType Directory -Path $NaviDir -Force | Out-Null
            }
        }
        Write-Info "Deploying navi cheatsheet → $NaviDst"
        if (-not $DryRun) {
            Copy-Item $NaviSrc $NaviDst -Force
        }
        Write-Ok "Navi cheatsheet deployed"
    }

    # Create notes directory
    $notesDir = Join-Path $env:USERPROFILE "notes"
    if (-not (Test-Path $notesDir)) {
        if (-not $DryRun) {
            New-Item -ItemType Directory -Path $notesDir -Force | Out-Null
        }
        Write-Ok "Created ~/notes directory"
    }
}

###############################################################################
# WINDOWS TERMINAL DRACULA THEME
###############################################################################

Write-Section "Windows Terminal theme"

$wtSettingsPath = "$env:LOCALAPPDATA\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json"

if (Test-Path $wtSettingsPath) {
    Write-Info "To apply Dracula theme to Windows Terminal:"
    Write-Host @"

  Add this to your Windows Terminal settings.json under "schemes":

  {
    "name": "Dracula",
    "background": "#282A36",
    "foreground": "#F8F8F2",
    "cursorColor": "#F8F8F2",
    "selectionBackground": "#44475A",
    "black": "#21222C",
    "red": "#FF5555",
    "green": "#50FA7B",
    "yellow": "#F1FA8C",
    "blue": "#BD93F9",
    "purple": "#FF79C6",
    "cyan": "#8BE9FD",
    "white": "#F8F8F2",
    "brightBlack": "#6272A4",
    "brightRed": "#FF6E6E",
    "brightGreen": "#69FF94",
    "brightYellow": "#FFFFA5",
    "brightBlue": "#D6ACFF",
    "brightPurple": "#FF92DF",
    "brightCyan": "#A4FFFF",
    "brightWhite": "#FFFFFF"
  }

  Then set "colorScheme": "Dracula" in your default profile.

"@ -ForegroundColor DarkGray
} else {
    Write-Warn "Windows Terminal settings not found at expected path"
}

###############################################################################
# FONT RECOMMENDATION
###############################################################################

Write-Section "Font setup"
Write-Info "For icons to render correctly, install a Nerd Font:"
Write-Host "  winget install --id=NerdFonts.CascadiaCode" -ForegroundColor DarkGray
Write-Host "  Then set it as your Windows Terminal font." -ForegroundColor DarkGray

###############################################################################
# SUMMARY
###############################################################################

Write-Host @"

╔══════════════════════════════════════════════════════╗
║  ✅ Super Shell (Windows) installation complete!      ║
╠══════════════════════════════════════════════════════╣
║                                                      ║
║  What was set up:                                    ║
║  ┌─ Foundation ─────────────────────────────────┐    ║
║  │  PowerShell 7, Windows Terminal, Git, Neovim  │    ║
║  ├─ Shell ──────────────────────────────────────┤    ║
║  │  eza, bat, fd, fzf, rg, zoxide, starship     │    ║
║  │  atuin, zellij, navi, tldr                    │    ║
║  ├─ System ─────────────────────────────────────┤    ║
║  │  btop, btm, dust, duf, procs                  │    ║
║  ├─ Git ────────────────────────────────────────┤    ║
║  │  lazygit, delta, git-absorb                   │    ║
║  ├─ Docker ─────────────────────────────────────┤    ║
║  │  Docker Desktop, lazydocker                   │    ║
║  ├─ Network ────────────────────────────────────┤    ║
║  │  tailscale, doggo, xh                         │    ║
║  └─ Data ───────────────────────────────────────┘    ║
║     jq, yq, sd, xsv, csvlens                        ║
║                                                      ║
║  Remaining manual steps:                             ║
║  1. Install a Nerd Font (see above)                  ║
║  2. Apply Dracula theme in Windows Terminal           ║
║  3. Update bookmark paths in j function              ║
║  4. Restart terminal for profile to take effect       ║
║  5. Run 'tailscale up' if first time                 ║
║  6. Run 'shelp' to see the quick reference           ║
║                                                      ║
╚══════════════════════════════════════════════════════╝

"@ -ForegroundColor Green

if ($DryRun) {
    Write-Warn "This was a dry run — nothing was actually installed"
}
