<#
.SYNOPSIS
    ⚡ Super Shell — Updater (Windows)

.DESCRIPTION
    Pulls the latest configs and deploys them. Deliberately does NOT touch
    system state: no winget/scoop installs, no global git config, no module
    installs, no gsudo config. Those belong to install-supershell.ps1, which
    you run once per machine (or again when new packages land).

    Run from a normal (non-elevated) PowerShell 7 prompt:
        .\update-supershell.ps1

.PARAMETER NoPull
    Deploy the working tree as-is, skip git pull.

.PARAMETER DryRun
    Show what would change without writing anything.

.PARAMETER Force
    Pull even with uncommitted changes in the working tree.
#>

param(
    [switch]$NoPull,
    [switch]$DryRun,
    [switch]$Force
)

$ErrorActionPreference = "Stop"

# ─── Colors & Helpers ───────────────────────────────────────────────────
function Write-Info    { param($msg) Write-Host "[INFO] $msg" -ForegroundColor Cyan }
function Write-Ok      { param($msg) Write-Host "[OK]   $msg" -ForegroundColor Green }
function Write-Warn    { param($msg) Write-Host "[WARN] $msg" -ForegroundColor Yellow }
function Write-Err     { param($msg) Write-Host "[ERR]  $msg" -ForegroundColor Red }
function Write-Section { param($msg) Write-Host "`n── $msg ──" -ForegroundColor Cyan }

Write-Host @"

╔══════════════════════════════════════════════════════╗
║  ⚡ Super Shell — Update                              ║
╚══════════════════════════════════════════════════════╝

"@ -ForegroundColor Cyan

if ($DryRun) { Write-Warn "DRY RUN — nothing will be written" }

# ─── Locate the clone ───────────────────────────────────────────────────
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $ScriptDir

git rev-parse --git-dir *> $null
if ($LASTEXITCODE -ne 0) {
    Write-Err "Not a git repository: $ScriptDir"
    Write-Err "The updater pulls changes, so it needs the cloned repo — not a lone"
    Write-Err "copy of this script. Clone it:"
    Write-Err "  git clone https://github.com/bjschnell/SuperShell.git"
    exit 1
}

$OldRef     = (git rev-parse HEAD).Trim()
$OldVersion = if (Test-Path "VERSION") { (Get-Content VERSION -Raw).Trim() } else { "unknown" }

# ─── Pull ───────────────────────────────────────────────────────────────
if (-not $NoPull) {
    Write-Section "Pulling latest"
    $branch = (git rev-parse --abbrev-ref HEAD).Trim()

    $dirty = git status --porcelain
    if ($dirty) {
        if ($Force) {
            Write-Warn "Working tree is dirty — pulling anyway (-Force)"
        } else {
            Write-Err "Working tree has uncommitted changes:"
            $dirty | ForEach-Object { Write-Host "  $_" }
            Write-Err "Commit or stash them, or re-run with -NoPull / -Force."
            exit 1
        }
    }

    Write-Info "Branch: $branch"
    if ($DryRun) {
        Write-Warn "[dry-run] Would run: git pull --ff-only"
    } else {
        # --ff-only: an updater should never invent a merge commit
        git pull --ff-only
        if ($LASTEXITCODE -ne 0) {
            Write-Err "git pull failed — resolve it and re-run."
            exit 1
        }
    }
} else {
    Write-Info "Skipping git pull (-NoPull)"
}

$NewRef     = (git rev-parse HEAD).Trim()
$NewVersion = if (Test-Path "VERSION") { (Get-Content VERSION -Raw).Trim() } else { "unknown" }

# ─── What changed ───────────────────────────────────────────────────────
if ($OldRef -ne $NewRef) {
    Write-Section "Changes pulled"
    git log --oneline "$OldRef..$NewRef" | ForEach-Object { Write-Host "  $_" }
    if ($OldVersion -ne $NewVersion) {
        Write-Info "Version: $OldVersion → $NewVersion"
    }
} else {
    Write-Info "Repo already at $((git rev-parse --short HEAD).Trim()) — nothing new to pull"
}

# ─── Deploy ─────────────────────────────────────────────────────────────
$script:Changed   = 0
$script:Unchanged = 0

function Deploy-File {
    param([string]$Src, [string]$Dst)

    if (-not (Test-Path $Src)) {
        Write-Warn "not in repo, skipping: $(Split-Path $Src -Leaf)"
        return
    }

    # Only back up when content actually differs — otherwise every run of the
    # updater litters the config dirs with identical .bak files.
    if (Test-Path $Dst) {
        $a = (Get-FileHash $Src).Hash
        $b = (Get-FileHash $Dst).Hash
        if ($a -eq $b) {
            Write-Ok "unchanged  $Dst"
            $script:Unchanged++
            return
        }
    }

    $script:Changed++
    if ($DryRun) {
        Write-Warn "[dry-run] would update $Dst"
        return
    }

    $dir = Split-Path -Parent $Dst
    if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
    if (Test-Path $Dst) {
        Copy-Item $Dst "$Dst.bak.$(Get-Date -Format 'yyyyMMdd_HHmmss')"
    }
    Copy-Item $Src $Dst -Force
    Write-Ok "updated    $Dst"
}

Write-Section "Deploying configs"
Deploy-File (Join-Path $ScriptDir "Microsoft.PowerShell_profile.ps1") $PROFILE
Deploy-File (Join-Path $ScriptDir "tools.txt")        (Join-Path $env:USERPROFILE ".config\supershell\tools.txt")
Deploy-File (Join-Path $ScriptDir "starship.toml")    (Join-Path $env:USERPROFILE ".config\starship.toml")
Deploy-File (Join-Path $ScriptDir "supershell.cheat") (Join-Path $env:APPDATA   "navi\cheats\supershell.cheat")

# ─── Stamp the deployed version ─────────────────────────────────────────
# So a machine can answer "what am I running?" without guessing.
$Stamp = Join-Path $env:USERPROFILE ".config\supershell\VERSION"
if (-not $DryRun) {
    $stampDir = Split-Path -Parent $Stamp
    if (-not (Test-Path $stampDir)) { New-Item -ItemType Directory -Path $stampDir -Force | Out-Null }
    @(
        "version=$NewVersion"
        "commit=$((git rev-parse --short HEAD).Trim())"
        "branch=$((git rev-parse --abbrev-ref HEAD).Trim())"
        "source=$ScriptDir"
        "deployed=$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
    ) | Set-Content $Stamp -Encoding UTF8
    Write-Ok "stamped    $Stamp"
}

# ─── Tool check ─────────────────────────────────────────────────────────
# Config changes sometimes assume a tool the installer added. Check commands,
# not package names, so this stays honest regardless of winget/scoop/manual.
Write-Section "Tool check"

$Required = @('eza', 'bat', 'fd', 'fzf', 'zoxide', 'starship', 'rg', 'nvim', 'git')
$Optional = @('dust', 'duf', 'procs', 'sd', 'xh', 'doggo', 'yazi', 'lazygit',
              'delta', 'lazydocker', 'atuin', 'zellij', 'navi', 'tldr',
              'gh', 'glab', 'claude', 'gsudo')

$missingRequired = $Required | Where-Object { -not (Get-Command $_ -ErrorAction Ignore) }
$missingOptional = $Optional | Where-Object { -not (Get-Command $_ -ErrorAction Ignore) }

if (-not $missingRequired -and -not $missingOptional) {
    Write-Ok "All expected tools present"
} else {
    if ($missingRequired) { Write-Err  "Missing (core):     $($missingRequired -join ', ')" }
    if ($missingOptional) { Write-Warn "Missing (optional): $($missingOptional -join ', ')" }
    Write-Info "Install them with: .\install-supershell.ps1"
}

# ─── Summary ────────────────────────────────────────────────────────────
Write-Section "Summary"
Write-Host "  $script:Changed file(s) updated, $script:Unchanged already current"

if ($DryRun) {
    Write-Warn "Dry run — nothing was written"
} elseif ($script:Changed -gt 0) {
    Write-Info "Open a new terminal to pick up the changes."
    Write-Info "Run 'update-apps' too if the app launcher needs a refresh."
} else {
    Write-Ok "Everything already up to date"
}
