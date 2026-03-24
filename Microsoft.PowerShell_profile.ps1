###############################################################################
#  ⚡ SUPER SHELL — PowerShell 7 Profile (Windows)
#  Brady's hyper-optimized CLI environment — Windows mirror
#
#  Location: $PROFILE (typically ~\Documents\PowerShell\Microsoft.PowerShell_profile.ps1)
#
#  Dependencies (install via winget/scoop — see install-supershell.ps1):
#    Core:     eza bat fd fzf zoxide starship ripgrep
#    System:   btop bottom dust duf procs
#    Data:     jq yq sd xsv
#    Git:      lazygit delta git-absorb
#    Docker:   lazydocker
#    Files:    yazi
#    Network:  xh doggo
#    Shell:    atuin zellij navi tldr
###############################################################################

# ─── ENVIRONMENT ────────────────────────────────────────────────────────
$env:EDITOR = "nvim"
$env:VISUAL = "nvim"
$env:BAT_THEME = "Dracula"
$env:FZF_DEFAULT_COMMAND = "fd --hidden --strip-cwd-prefix --exclude .git"
$env:FZF_DEFAULT_OPTS = @"
--height=60% --layout=reverse --border=rounded --margin=0,1
--preview-window=right:55%:wrap
--bind=ctrl-d:preview-half-page-down,ctrl-u:preview-half-page-up
--bind=ctrl-y:execute-silent(echo {} | Set-Clipboard)
--color=bg+:#44475a,bg:#282a36,spinner:#f1fa8c,hl:#ff79c6
--color=fg:#f8f8f2,header:#ff79c6,info:#bd93f9,pointer:#50fa7b
--color=marker:#f1fa8c,fg+:#f8f8f2,prompt:#bd93f9,hl+:#ff79c6
--color=selected-bg:#44475a
"@

# ─── ALIASES (modern replacements) ─────────────────────────────────────
Set-Alias -Name cat -Value bat -Option AllScope -Force
Set-Alias -Name grep -Value rg -Option AllScope -Force
Set-Alias -Name lg -Value lazygit
Set-Alias -Name ld -Value lazydocker
Set-Alias -Name n -Value nvim
Set-Alias -Name top -Value btop

# ls → eza (can't directly alias 'ls' in PS without removing built-in)
Remove-Item Alias:ls -Force -ErrorAction SilentlyContinue
function ls  { eza --color=always --group-directories-first --icons=always @args }
function ll  { eza -alh --color=always --group-directories-first --icons=always --git @args }
function lt  { eza --tree --level=2 --color=always --group-directories-first --icons=always @args }
function lta { eza --tree --level=3 -a --color=always --group-directories-first --icons=always @args }

# Other modern replacements as functions
function du  { dust @args }
function df  { duf @args }
function dig { doggo @args }

# bat plain mode
function catp { bat -p @args }

# ─── GIT SHORTCUTS ─────────────────────────────────────────────────────
function gs   { git status -sb @args }
function gd   { git diff @args }
function gds  { git diff --staged @args }
function gc   { git commit @args }
function gca  { git commit --amend @args }
function gp   { git push @args }
function gpl  { git pull --rebase @args }
function gl   { git log --oneline --graph --decorate -20 @args }
function gla  { git log --oneline --graph --decorate --all @args }
function gb   { git branch @args }
function gco  { git checkout @args }
function gsw  { git switch @args }
function gst  { git stash @args }
function gsp  { git stash pop @args }

# ─── DOCKER SHORTCUTS ──────────────────────────────────────────────────
function dps  { docker ps --format "table {{.Names}}`t{{.Status}}`t{{.Ports}}" @args }
function dlog { docker logs -f --tail 100 @args }
function dcu  { docker compose up -d @args }
function dcd  { docker compose down @args }
function dcr  { docker compose restart @args }
function dcl  { docker compose logs -f --tail 100 @args }
function dce  { docker compose exec @args }
function dcps { docker compose ps @args }

# ─── WINDOWS SERVICE SHORTCUTS (equivalent to systemctl) ───────────────
function svc      { Get-Service @args }
function svcstart { Start-Service @args }
function svcstop  { Stop-Service @args }
function svcrst   { Restart-Service @args }

# ─── WINGET SHORTCUTS (equivalent to pacman) ───────────────────────────
function wgi  { winget install @args }
function wgs  { winget search @args }
function wgu  { winget upgrade --all @args }
function wgr  { winget uninstall @args }

# ─── FUNCTIONS ──────────────────────────────────────────────────────────

# fd with sane defaults
function fdf { fd.exe --hidden --strip-cwd-prefix @args }

# fzf file picker → open in nvim
function fzf-file {
    $result = fd --hidden --strip-cwd-prefix --exclude .git --type f |
        fzf.exe --preview "bat --color=always --style=numbers --line-range=:500 {}"
    if ($result) { nvim $result }
}
Set-Alias -Name nf -Value fzf-file

# Interactive fzf — opens files in nvim, cd's into directories
function fzf-open {
    $result = fzf.exe --preview "bat --color=always --style=numbers --line-range=:500 {}" @args
    if ($result) {
        if (Test-Path $result -PathType Leaf) {
            nvim $result
        } elseif (Test-Path $result -PathType Container) {
            Set-Location $result
        } else {
            Write-Output $result
        }
    }
}

# Yazi with directory change on exit
function y {
    $tmp = [System.IO.Path]::GetTempFileName()
    yazi @args --cwd-file="$tmp"
    $cwd = Get-Content $tmp -ErrorAction SilentlyContinue
    if ($cwd -and $cwd -ne $PWD.Path) {
        Set-Location $cwd
    }
    Remove-Item $tmp -Force -ErrorAction SilentlyContinue
}

# ─── SEARCH & NAVIGATION SUPERPOWERS ───────────────────────────────────

# rg + fzf → open result in nvim at the exact line
function rgf {
    $result = rg --color=always --line-number --no-heading @args |
        fzf.exe --ansi --delimiter ':' `
            --preview "bat --color=always --highlight-line {2} {1}" `
            --preview-window "right:55%:+{2}-10"
    if ($result) {
        $parts = $result -split ':'
        nvim "+$($parts[1])" $parts[0]
    }
}

# Process search & kill with fzf
function psk {
    $proc = Get-Process | ForEach-Object { "$($_.Id)`t$($_.ProcessName)`t$($_.CPU)" } |
        fzf.exe --header="PID`tName`tCPU"
    if ($proc) {
        $pid = ($proc -split "`t")[0]
        Write-Host "Killing PID $pid" -ForegroundColor Yellow
        Stop-Process -Id $pid -Force
    }
}

# Docker container shell — fzf pick a running container, exec into it
function dsh {
    $container = docker ps --format '{{.Names}}`t{{.Image}}`t{{.Status}}' |
        fzf.exe --header="Select container"
    if ($container) {
        $name = ($container -split "`t")[0].Trim()
        docker exec -it $name sh -c "if command -v bash > /dev/null; then bash; else sh; fi"
    }
}

# Docker logs viewer — fzf pick any container (including stopped)
function dlf {
    $container = docker ps -a --format '{{.Names}}`t{{.Image}}`t{{.Status}}' |
        fzf.exe --header="Select container for logs"
    if ($container) {
        $name = ($container -split "`t")[0].Trim()
        docker logs -f --tail 200 $name
    }
}

# SSH host picker from ~/.ssh/config
function ss {
    $hosts = Select-String -Path "$env:USERPROFILE\.ssh\config" -Pattern "^Host " -ErrorAction SilentlyContinue |
        ForEach-Object { ($_ -split '\s+')[1] } |
        Where-Object { $_ -notmatch '\*' }
    $host = $hosts | fzf.exe --header="SSH to..."
    if ($host) { ssh $host }
}

# Quick file/dir size inspector
function big {
    $count = if ($args[0]) { $args[0] } else { 20 }
    dust -n $count
}

# Quick port check — what's listening where
function ports {
    Get-NetTCPConnection -State Listen |
        Select-Object LocalAddress, LocalPort, OwningProcess,
            @{Name="ProcessName"; Expression={(Get-Process -Id $_.OwningProcess -ErrorAction SilentlyContinue).ProcessName}} |
        Sort-Object LocalPort |
        Format-Table -AutoSize
}

# ─── CLIPBOARD INTEGRATION ─────────────────────────────────────────────

# Pipe anything to clipboard
function clip {
    if ($args.Count -gt 0) {
        Get-Content @args | Set-Clipboard
    } else {
        $input | Set-Clipboard
    }
}

# Copy current path to clipboard
function clipwd {
    $PWD.Path | Set-Clipboard
    Write-Host "Copied: $($PWD.Path)"
}

# Copy file contents to clipboard
function clipfile {
    if (Test-Path $args[0]) {
        Get-Content $args[0] -Raw | Set-Clipboard
        Write-Host "Copied $($args[0]) to clipboard"
    } else {
        Write-Host "File not found: $($args[0])" -ForegroundColor Red
    }
}

# ─── QUICK NOTES & SCRATCH ─────────────────────────────────────────────

function note {
    $notefile = "$env:USERPROFILE\notes\scratch.md"
    if (-not (Test-Path "$env:USERPROFILE\notes")) {
        New-Item -ItemType Directory -Path "$env:USERPROFILE\notes" -Force | Out-Null
    }

    switch ($args[0]) {
        "add" {
            $text = $args[1..($args.Length-1)] -join ' '
            $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm"
            Add-Content $notefile "- [$timestamp] $text"
            Write-Host "📝 Note added"
        }
        "edit" {
            nvim $notefile
        }
        "clear" {
            Set-Content $notefile ""
            Write-Host "🗑️  Notes cleared"
        }
        $null {
            if (Test-Path $notefile) {
                bat $notefile
            } else {
                Write-Host "No notes yet. Use: note add <your note>"
            }
        }
        default {
            # Bare text = quick add
            $text = $args -join ' '
            $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm"
            Add-Content $notefile "- [$timestamp] $text"
            Write-Host "📝 Note added"
        }
    }
}

# ─── TOOLS REFERENCE ────────────────────────────────────────────────────

function tools {
    $toolsFile = "$env:USERPROFILE\.config\supershell\tools.txt"
    if (-not (Test-Path $toolsFile)) {
        Write-Host "tools.txt not found at $toolsFile" -ForegroundColor Red
        return
    }
    if ($args.Count -gt 0) {
        bat $toolsFile | rg -i ($args -join ' ')
    } else {
        bat $toolsFile
    }
}

# ─── CHEATSHEET ─────────────────────────────────────────────────────────

function shelp {
    Write-Host @"

╔══════════════════════════════════════════════════════════════════╗
║  ⚡ SUPER SHELL QUICK REFERENCE (Windows)                        ║
╠══════════════════════════════════════════════════════════════════╣
║                                                                  ║
║  NAVIGATION         │  FILES & SEARCH                            ║
║  ──────────         │  ─────────────                             ║
║  y    → yazi (cd)   │  fzf-open → fuzzy find → open             ║
║  z    → zoxide jump │  rgf  → grep → fzf → nvim at line         ║
║  nf   → fzf → nvim  │  big  → show biggest files/dirs           ║
║  ss   → fzf ssh     │  note → quick scratch notes                ║
║                     │  clip/clipfile/clipwd → clipboard           ║
║                                                                  ║
║  GIT                                                             ║
║  ───                                                             ║
║  gs gd gds gl gla gc gca gp gpl gb gco gsw gst gsp             ║
║  lg → lazygit TUI  │  gbf → fzf branch switch                   ║
║  gbr → recent branches │ gfix → fzf fixup commit                ║
║                                                                  ║
║  DOCKER                                                          ║
║  ──────                                                          ║
║  ld   → lazydocker TUI                                           ║
║  dps  → pretty container list                                    ║
║  dsh  → fzf exec into container                                  ║
║  dlf  → fzf follow container logs                                ║
║  dcu/dcd/dcr/dcl/dcps → compose shortcuts                        ║
║                                                                  ║
║  SYSTEM                                                          ║
║  ──────                                                          ║
║  ports → show listening ports                                    ║
║  psk   → fuzzy process kill                                      ║
║  svc/svcstart/svcstop/svcrst → Windows services                  ║
║  wgi/wgs/wgu/wgr → winget shortcuts                              ║
║                                                                  ║
║  MULTIPLEXER (zellij)                                            ║
║  ────────────────────                                            ║
║  zj → zellij  │  zja → attach  │  zjl → list sessions           ║
║                                                                  ║
╚══════════════════════════════════════════════════════════════════╝

"@
}

# ─── GIT ENHANCEMENTS ──────────────────────────────────────────────────

# Interactive branch switcher
function gbf {
    $branch = git branch --all --sort=-committerdate |
        ForEach-Object { $_.Trim() -replace '^\* ', '' -replace 'remotes/origin/', '' } |
        Where-Object { $_ -notmatch 'HEAD' } |
        Sort-Object -Unique |
        fzf.exe --header="Switch branch"
    if ($branch) {
        git switch $branch 2>$null
        if ($LASTEXITCODE -ne 0) { git checkout $branch }
    }
}

# Show recent branches
function gbr {
    git reflog | Select-String 'checkout: moving' |
        ForEach-Object { ($_ -split ' ')[-1] } |
        Select-Object -Unique |
        Select-Object -First 10
}

# Quick fixup commit
function gfix {
    $commit = git log --oneline -30 |
        fzf.exe --header="Select commit to fixup" |
        ForEach-Object { ($_ -split ' ')[0] }
    if ($commit) {
        git commit --fixup=$commit @args
        Write-Host "Created fixup for $commit — run 'git rebase -i --autosquash' to apply"
    }
}

# ─── DIRECTORY BOOKMARKS ───────────────────────────────────────────────

function j {
    $bookmarks = @{
        "dots"     = "$env:USERPROFILE\.config"
        "nvim"     = "$env:USERPROFILE\AppData\Local\nvim"
        "notes"    = "$env:USERPROFILE\notes"
        "projects" = "$env:USERPROFILE\projects"
        "repos"    = "$env:USERPROFILE\repos"
        "scripts"  = "$env:USERPROFILE\scripts"
        "ssh"      = "$env:USERPROFILE\.ssh"
        # ↑ Add your own bookmarks above
    }

    if (-not $args[0]) {
        $choice = $bookmarks.GetEnumerator() |
            ForEach-Object { "$($_.Key)`t$($_.Value)" } |
            Sort-Object |
            fzf.exe --header="Jump to..."
        if ($choice) {
            $path = ($choice -split "`t")[-1].Trim()
            Set-Location $path
        }
    } elseif ($bookmarks.ContainsKey($args[0])) {
        Set-Location $bookmarks[$args[0]]
    } else {
        Write-Host "Unknown bookmark: $($args[0])" -ForegroundColor Red
    }
}

# ─── NETWORK HELPERS ───────────────────────────────────────────────────

# Quick DNS lookup
function dns {
    if ($args.Count -eq 1) {
        doggo $args[0] A AAAA CNAME MX
    } else {
        doggo @args
    }
}

# ─── PSReadLine (tab completion & history enhancements) ─────────────────

if (Get-Module -ListAvailable -Name PSReadLine) {
    Set-PSReadLineOption -PredictionSource HistoryAndPlugin
    Set-PSReadLineOption -PredictionViewStyle ListView
    Set-PSReadLineOption -EditMode Emacs
    Set-PSReadLineOption -BellStyle None
    Set-PSReadLineKeyHandler -Key Tab -Function MenuComplete
    Set-PSReadLineKeyHandler -Key UpArrow -Function HistorySearchBackward
    Set-PSReadLineKeyHandler -Key DownArrow -Function HistorySearchForward
    Set-PSReadLineKeyHandler -Chord Ctrl+r -Function ReverseSearchHistory

    # Dracula colors for PSReadLine
    Set-PSReadLineOption -Colors @{
        Command            = '#50fa7b'
        Parameter          = '#ffb86c'
        Operator           = '#ff79c6'
        Variable           = '#bd93f9'
        String             = '#f1fa8c'
        Number             = '#bd93f9'
        Type               = '#8be9fd'
        Comment            = '#6272a4'
        Keyword            = '#ff79c6'
        Error              = '#ff5555'
        Selection          = '#44475a'
        InlinePrediction   = '#6272a4'
        ListPrediction     = '#8be9fd'
        Member             = '#f8f8f2'
        ContinuationPrompt = '#f8f8f2'
        Emphasis           = '#ff79c6'
        Default            = '#f8f8f2'
    }
}

# ─── INIT TOOLS ─────────────────────────────────────────────────────────
Invoke-Expression (& { (zoxide init powershell | Out-String) })
Invoke-Expression (& { (starship init powershell | Out-String) })
if (Get-Command atuin -ErrorAction SilentlyContinue) {
    atuin init powershell 2>$null | Invoke-Expression
}

# ─── DRACULA PIKACHU ───────────────────────────────────────────────────
function Show-Pikachu {
    $e = [char]27
    $purple  = "$e[1;38;2;189;147;249m"
    $pink    = "$e[1;38;2;255;121;198m"
    $green   = "$e[1;38;2;80;250;123m"
    $cyan    = "$e[1;38;2;139;233;253m"
    $fg      = "$e[38;2;248;248;242m"
    $comment = "$e[38;2;98;114;164m"
    $r       = "$e[0m"

    Write-Host ""
    Write-Host "${purple}⣿⣿⣿⣿⣿⣿⣿⠿⣛⣩⣴⣾⡿⠃${green}⢀⣠⣾⣿⣿⣿⣿⣿⣿${r}"
    Write-Host "${purple}⣿⣿⣿⣿⡿⣻⣴⣭⣭⣭⣭⣁⠶${green}⣾⣿⣿⣿⣿⣿⣿⣿⣿⣿${r}"
    Write-Host "${purple}⣿⣿⡿⢟⡕⢿⣿⣿⣿⣿⣿⣿⣿${green}⣮⣹⣿⡿⠿⠿⢿⣿⣿⣿${r}"
    Write-Host "${purple}⣿⡟⣴⣿⢶⢾⣿⣿${cyan}⣿⣿⢟⠛⣿⣿${green}⢿⣿⣿⣿⣷⣶⣮⣍⡛${r}"
    Write-Host "${purple}⣦⣅⢵⣿⣇⣴⣽⣻${cyan}⣿⣿⣦⣤⣿⣿${green}⣷⡎⣭⣛⠛⠿⠛⠋⠁${r}"
    Write-Host "${purple}⣿⣿⡌⣿⣏⣿⢏${cyan}⣿⣿⡯⣾⣷⢽⣿${green}⡟⣰⣶⣶⣭⣭⣛⠻⢿${r}"
    Write-Host "${pink}⡹⣿⣿⣬⣿⣷${cyan}⣿⣿⣿⣿⣾⠿⢿⣛${green}⣘⣛⣻⡛⢿⣿⣿⣿⣶${r}"
    Write-Host "${pink}⣷⣌⠏⣿⣿⣿${cyan}⣿⣿⣿⣿⣿⣿⣿⣿${fg}⣿⣿⣿⢿⢸⣿⣿⣿⡿${r}"
    Write-Host "${pink}⣿⣿⢃⣿⣿⣿${cyan}⣿⣿⣿⣿⣿⣿⣿⡿${fg}⠟⣥⣿⡔⣤⣍⣋⣴${r}"
    Write-Host "${pink}⣿⠏⣾⣿⣿⣿⣿⣿${fg}⣿⣿⣿⣿⣿⣵⡄⣶⡿⠿⢓⣸⣿⣿⣿${r}"
    Write-Host "${pink}⡏⣼⣿⣿⣿⣿⣿⣿${fg}⣿⣿⣿⣿⣿⣿⣄⢺⠶⠹⣿⣿⣿⣿⣿${r}"
    Write-Host "${comment}⡇⣿⣿⣿⣿⣿⣿⣿${fg}⣿⣿⣿⣿⣿⣿⡏⣰⣶⣿⣿⣿⣿⣿⣿${r}"
    Write-Host "${comment}⠷⣙⠿⣿⣿⠿⠿⠛${fg}⠻⠿⣿⣿⣿⠟⣱⣿⣿⣿⣿⣿⣿⣿⣿${r}"
    Write-Host "${comment}⣾⣬⣭⣷⣶⣿⣿⣿${fg}⣿⣿⣶⣦⡲⠷⡙⣿⣿⣿⣿⣿⣿⣿⣿${r}"
    Write-Host ""
}

Show-Pikachu
