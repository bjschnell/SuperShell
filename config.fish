###############################################################################
#  ⚡ SUPER SHELL — fish config
#  Brady's hyper-optimized CLI environment
#  
#  Dependencies (install via pacman/yay):
#    Core:     eza bat fd fzf zoxide starship ripgrep
#    System:   btop bottom dust duf procs bandwhich
#    Data:     jq yq sd xsv csvlens
#    Git:      lazygit delta git-absorb
#    Docker:   lazydocker
#    Files:    yazi trash-cli
#    Network:  xh doggo
#    Shell:    atuin zellij navi tldr wl-clipboard
#
#  After installing, run:
#    atuin init fish | source   (first time setup)
#    atuin import auto          (import existing history)
###############################################################################

if status is-interactive

    # ─── ENVIRONMENT ────────────────────────────────────────────────────
    set -gx EDITOR nvim
    set -gx VISUAL nvim
    set -gx MANPAGER "sh -c 'col -bx | bat -l man -p'"  # colorized man pages via bat
    set -gx MANROFFOPT "-c"
    set -gx BAT_THEME "Dracula"
    set -gx FZF_DEFAULT_COMMAND "fd --hidden --strip-cwd-prefix --exclude .git"
    set -gx FZF_DEFAULT_OPTS "\
        --height=60% --layout=reverse --border=rounded --margin=0,1 \
        --preview-window=right:55%:wrap \
        --bind='ctrl-d:preview-half-page-down,ctrl-u:preview-half-page-up' \
        --bind='ctrl-y:execute-silent(echo -n {} | wl-copy)' \
        --color=bg+:#44475a,bg:#282a36,spinner:#f1fa8c,hl:#ff79c6 \
        --color=fg:#f8f8f2,header:#ff79c6,info:#bd93f9,pointer:#50fa7b \
        --color=marker:#f1fa8c,fg+:#f8f8f2,prompt:#bd93f9,hl+:#ff79c6 \
        --color=selected-bg:#44475a"

    # ─── ALIASES (modern replacements) ──────────────────────────────────
    alias sudo='sudo '
    alias ls='eza --color=always --group-directories-first --icons=always'
    alias ll='eza -alh --color=always --group-directories-first --icons=always --git'
    alias lt='eza --tree --level=2 --color=always --group-directories-first --icons=always'
    alias lta='eza --tree --level=3 -a --color=always --group-directories-first --icons=always'
    alias cat='bat'
    alias catp='bat -p'                          # plain mode, no line numbers/header
    alias grep='rg'
    alias du='dust'
    alias df='duf'
    alias ps='procs'
    alias top='btop'
    alias sed='sd'
    alias dig='doggo'
    alias curl='xh'                              # httpie-style ergonomics
    alias rm='trash-put'                          # safe delete — recover with trash-restore
    alias rmreal='/usr/bin/rm'                    # escape hatch for actual rm
    alias lg='lazygit'
    alias ld='lazydocker'
    alias y='yazi_cd'                             # yazi with directory tracking (see below)
    alias n='nvim'
    alias nf='nvim (fzf_file)'                   # fuzzy find then edit
    alias zj='zellij'
    alias zja='zellij attach'
    alias zjl='zellij list-sessions'

    # sunshine
    alias startsunshine='/home/xdx/.config/sunshine/scripts/startup.sh'

    # ─── ABBREVIATIONS (expand inline — better than aliases for complex cmds) ─
    abbr -a gc  'git commit'
    abbr -a gca 'git commit --amend'
    abbr -a gp  'git push'
    abbr -a gpl 'git pull --rebase'
    abbr -a gs  'git status -sb'
    abbr -a gd  'git diff'
    abbr -a gds 'git diff --staged'
    abbr -a gl  'git log --oneline --graph --decorate -20'
    abbr -a gla 'git log --oneline --graph --decorate --all'
    abbr -a gb  'git branch'
    abbr -a gco 'git checkout'
    abbr -a gsw 'git switch'
    abbr -a gst 'git stash'
    abbr -a gsp 'git stash pop'
    abbr -a dps 'docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"'
    abbr -a dlog 'docker logs -f --tail 100'
    abbr -a dcu 'docker compose up -d'
    abbr -a dcd 'docker compose down'
    abbr -a dcr 'docker compose restart'
    abbr -a dcl 'docker compose logs -f --tail 100'
    abbr -a dce 'docker compose exec'
    abbr -a dcps 'docker compose ps'
    abbr -a sc  'sudo systemctl'
    abbr -a sce 'sudo systemctl enable --now'
    abbr -a scr 'sudo systemctl restart'
    abbr -a scs 'systemctl status'
    abbr -a scl 'journalctl -u'
    abbr -a sclf 'journalctl -fu'
    abbr -a pac 'sudo pacman -S'
    abbr -a pacs 'pacman -Ss'
    abbr -a pacr 'sudo pacman -Rns'
    abbr -a pacu 'sudo pacman -Syu'
    abbr -a yay 'yay -S'
    abbr -a yays 'yay -Ss'

    # ─── FUNCTIONS ──────────────────────────────────────────────────────

    # fd with sane defaults
    function fd --wraps fd
        command fd --hidden --strip-cwd-prefix $argv
    end

    # fzf file picker (returns path, used by other functions)
    function fzf_file
        command fd --hidden --strip-cwd-prefix --exclude .git --type f | \
            command fzf --preview 'bat --color=always --style=numbers --line-range=:500 {}' $argv
    end

    # Interactive fzf — opens files in nvim, cd's into directories
    function fzf --wraps fzf
        set result (command fzf --preview 'bat --color=always --style=numbers --line-range=:500 {}' $argv)
        if test -n "$result"
            if test -f "$result"
                nvim "$result"
            else if test -d "$result"
                cd "$result"
            else
                echo "$result"
            end
        end
    end

    # Yazi with directory change on exit (cd to wherever you navigated)
    function yazi_cd
        set tmp (mktemp -t "yazi-cwd.XXXXXX")
        command yazi $argv --cwd-file="$tmp"
        if set cwd (command cat -- "$tmp"); and [ -n "$cwd" ]; and [ "$cwd" != "$PWD" ]
            builtin cd -- "$cwd"
        end
        command rm -f -- "$tmp"
    end

    # ─── SEARCH & NAVIGATION SUPERPOWERS ────────────────────────────────

    # rg + fzf: interactive grep → open result in nvim at the exact line
    function rgf --description "Ripgrep → fzf → nvim at line"
        set -l result (rg --color=always --line-number --no-heading $argv | \
            command fzf --ansi \
                --delimiter ':' \
                --preview 'bat --color=always --highlight-line {2} {1}' \
                --preview-window 'right:55%:+{2}-10')
        if test -n "$result"
            set -l file (echo $result | cut -d: -f1)
            set -l line (echo $result | cut -d: -f2)
            nvim "+$line" "$file"
        end
    end

    # Process search & kill with fzf
    function psk --description "Fuzzy process kill"
        set -l pid (procs --color=always | command fzf --ansi --header-lines=1 | awk '{print $1}')
        if test -n "$pid"
            echo "Killing PID $pid"
            kill -9 $pid
        end
    end

    # Docker container shell — fzf pick a running container, exec into it
    function dsh --description "Fuzzy docker exec into container"
        set -l container (docker ps --format '{{.Names}}\t{{.Image}}\t{{.Status}}' | \
            column -t | command fzf --header="Select container" | awk '{print $1}')
        if test -n "$container"
            docker exec -it $container /bin/sh -c "if command -v bash > /dev/null; then bash; else sh; fi"
        end
    end

    # Docker logs viewer — fzf pick any container (including stopped)
    function dlf --description "Fuzzy docker logs follow"
        set -l container (docker ps -a --format '{{.Names}}\t{{.Image}}\t{{.Status}}' | \
            column -t | command fzf --header="Select container for logs" | awk '{print $1}')
        if test -n "$container"
            docker logs -f --tail 200 $container
        end
    end

    # SSH host picker from ~/.ssh/config
    function ss --description "Fuzzy SSH connect"
        set -l host (grep -E "^Host " ~/.ssh/config 2>/dev/null | awk '{print $2}' | \
            grep -v '*' | command fzf --header="SSH to...")
        if test -n "$host"
            ssh $host
        end
    end

    # Quick file/dir size inspector
    function big --description "Find biggest files/dirs in current path"
        set -l count (test -n "$argv[1]" && echo $argv[1] || echo 20)
        dust -n $count
    end

    # Quick port check — what's listening where
    function ports --description "Show listening ports"
        sudo ss -tlnp | tail -n +2 | sort -t: -k2 -n
    end

    # ─── CLIPBOARD INTEGRATION (Wayland/wl-clipboard) ──────────────────

    # Pipe anything to clipboard
    function clip --description "Copy stdin or file to clipboard"
        if test (count $argv) -gt 0
            cat $argv | wl-copy
        else
            wl-copy
        end
    end

    # Paste clipboard to stdout
    function clippaste --description "Paste clipboard to stdout"
        wl-paste
    end

    # Copy file contents to clipboard
    function clipfile --description "Copy file contents to clipboard"
        if test -f "$argv[1]"
            wl-copy < $argv[1]
            echo "Copied $argv[1] to clipboard"
        else
            echo "File not found: $argv[1]"
        end
    end

    # Copy current path to clipboard
    function clipwd --description "Copy current directory to clipboard"
        pwd | wl-copy
        echo "Copied: $(pwd)"
    end

    # ─── QUICK NOTES & SCRATCH ──────────────────────────────────────────

    # Scratch pad — fast note-taking without leaving shell
    function note --description "Quick notes — 'note' to view, 'note add <text>' to append"
        set -l notefile ~/notes/scratch.md
        mkdir -p ~/notes
        switch "$argv[1]"
            case add
                echo "- [$(date '+%Y-%m-%d %H:%M')] $argv[2..]" >> $notefile
                echo "📝 Note added"
            case edit
                nvim $notefile
            case clear
                echo -n > $notefile
                echo "🗑️  Notes cleared"
            case ''
                if test -f $notefile
                    bat $notefile
                else
                    echo "No notes yet. Use: note add <your note>"
                end
            case '*'
                # Bare text = quick add
                echo "- [$(date '+%Y-%m-%d %H:%M')] $argv" >> $notefile
                echo "📝 Note added"
        end
    end

    # ─── TOOLS REFERENCE ────────────────────────────────────────────────
    function tools
        if test (count $argv) -gt 0
            bat ~/.config/fish/tools.txt | rg -i $argv
        else
            bat ~/.config/fish/tools.txt
        end
    end

    # Cheatsheet for this config
    function shelp --description "Super shell quick reference"
        echo "
╔══════════════════════════════════════════════════════════════════╗
║  ⚡ SUPER SHELL QUICK REFERENCE                                 ║
╠══════════════════════════════════════════════════════════════════╣
║                                                                  ║
║  NAVIGATION         │  FILES & SEARCH                            ║
║  ──────────         │  ─────────────                             ║
║  y    → yazi (cd)   │  fzf  → fuzzy find → open                 ║
║  z    → zoxide jump │  rgf  → grep → fzf → nvim at line         ║
║  nf   → fzf → nvim  │  big  → show biggest files/dirs           ║
║  ss   → fzf ssh     │  note → quick scratch notes                ║
║                     │  clip/clipfile/clipwd → clipboard           ║
║                                                                  ║
║  GIT (abbreviations expand inline)                               ║
║  ─────────────────────────────────                               ║
║  gs gd gds gl gla gc gca gp gpl gb gco gsw gst gsp             ║
║  lg → lazygit TUI                                                ║
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
║  sc/sce/scr/scs/scl/sclf → systemctl shortcuts                  ║
║  pac/pacs/pacr/pacu → pacman shortcuts                           ║
║                                                                  ║
║  MULTIPLEXER (zellij)                                            ║
║  ────────────────────                                            ║
║  zj → zellij  │  zja → attach  │  zjl → list sessions           ║
║                                                                  ║
╚══════════════════════════════════════════════════════════════════╝
"
    end

    # ─── GIT ENHANCEMENTS ───────────────────────────────────────────────

    # Interactive branch switcher
    function gbf --description "Fuzzy git branch switch"
        set -l branch (git branch --all --sort=-committerdate | \
            grep -v HEAD | sed 's/^[\* ]*//' | sed 's|remotes/origin/||' | \
            sort -u | command fzf --header="Switch branch")
        if test -n "$branch"
            git switch $branch 2>/dev/null || git checkout $branch
        end
    end

    # Show recent branches you've been on
    function gbr --description "Recent git branches"
        git reflog | grep 'checkout: moving' | head -20 | \
            awk '{print $NF}' | awk '!seen[$0]++' | head -10
    end

    # Quick fixup commit — pick a recent commit to fixup with fzf
    function gfix --description "Fuzzy git fixup commit"
        set -l commit (git log --oneline -30 | \
            command fzf --header="Select commit to fixup" | awk '{print $1}')
        if test -n "$commit"
            git commit --fixup=$commit $argv
            echo "Created fixup for $commit — run 'git rebase -i --autosquash' to apply"
        end
    end

    # ─── DIRECTORY BOOKMARKS ────────────────────────────────────────────

    # Quick jump to frequent directories
    function j --description "Jump to bookmarked directory"
        set -l bookmarks \
            "homelab:$HOME/homelab" \
            "dots:$HOME/.config" \
            "fish:$HOME/.config/fish" \
            "nvim:$HOME/.config/nvim" \
            "hypr:$HOME/.config/hypr" \
            "notes:$HOME/notes" \
            "projects:$HOME/projects" \
            "scripts:$HOME/scripts"
            # ↑ Add your own bookmarks above

        if test -z "$argv[1]"
            set -l choice (printf '%s\n' $bookmarks | column -t -s: | \
                command fzf --header="Jump to..." | awk '{print $NF}')
            if test -n "$choice"
                cd $choice
            end
        else
            for bm in $bookmarks
                set -l parts (string split ':' $bm)
                if test "$parts[1]" = "$argv[1]"
                    cd $parts[2]
                    return
                end
            end
            echo "Unknown bookmark: $argv[1]"
        end
    end

    # ─── NETWORK & INFRA HELPERS ────────────────────────────────────────

    # Quick DNS lookup
    function dns --description "DNS lookup with doggo"
        if test (count $argv) -eq 1
            doggo $argv[1] A AAAA CNAME MX
        else
            doggo $argv
        end
    end

    # Tail a systemd service with syntax highlighting
    function logtail --description "Follow systemd journal for a service with bat"
        journalctl -fu $argv[1] -o cat | bat --paging=never -l log
    end

    # ─── COMPLETIONS BOOST ──────────────────────────────────────────────

    # Make sure fish knows about these tools for tab completion
    if command -q docker
        docker completion fish 2>/dev/null | source
    end

    # ─── INIT TOOLS ─────────────────────────────────────────────────────
    zoxide init fish | source
    starship init fish | source
    atuin init fish 2>/dev/null | source

    # ─── DRACULA PIKACHU ───────────────────────────────────────────────
    function _pikachu
        set -l purple  (set_color -o 'bd93f9')  # Dracula purple
        set -l pink    (set_color -o 'ff79c6')  # Dracula pink
        set -l green   (set_color -o '50fa7b')  # Dracula green
        set -l cyan    (set_color -o '8be9fd')  # Dracula cyan
        set -l fg      (set_color 'f8f8f2')     # Dracula foreground
        set -l comment (set_color '6272a4')     # Dracula comment
        set -l r       (set_color normal)

        echo ""
        echo $purple"⣿⣿⣿⣿⣿⣿⣿⠿⣛⣩⣴⣾⡿⠃"$green"⢀⣠⣾⣿⣿⣿⣿⣿⣿"$r
        echo $purple"⣿⣿⣿⣿⡿⣻⣴⣭⣭⣭⣭⣁⠶"$green"⣾⣿⣿⣿⣿⣿⣿⣿⣿⣿"$r
        echo $purple"⣿⣿⡿⢟⡕⢿⣿⣿⣿⣿⣿⣿⣿"$green"⣮⣹⣿⡿⠿⠿⢿⣿⣿⣿"$r
        echo $purple"⣿⡟⣴⣿⢶⢾⣿⣿"$cyan"⣿⣿⢟⠛⣿⣿"$green"⢿⣿⣿⣿⣷⣶⣮⣍⡛"$r
        echo $purple"⣦⣅⢵⣿⣇⣴⣽⣻"$cyan"⣿⣿⣦⣤⣿⣿"$green"⣷⡎⣭⣛⠛⠿⠛⠋⠁"$r
        echo $purple"⣿⣿⡌⣿⣏⣿⢏"$cyan"⣿⣿⡯⣾⣷⢽⣿"$green"⡟⣰⣶⣶⣭⣭⣛⠻⢿"$r
        echo $pink"⡹⣿⣿⣬⣿⣷"$cyan"⣿⣿⣿⣿⣾⠿⢿⣛"$green"⣘⣛⣻⡛⢿⣿⣿⣿⣶"$r
        echo $pink"⣷⣌⠏⣿⣿⣿"$cyan"⣿⣿⣿⣿⣿⣿⣿⣿"$fg"⣿⣿⣿⢿⢸⣿⣿⣿⡿"$r
        echo $pink"⣿⣿⢃⣿⣿⣿"$cyan"⣿⣿⣿⣿⣿⣿⣿⡿"$fg"⠟⣥⣿⡔⣤⣍⣋⣴"$r
        echo $pink"⣿⠏⣾⣿⣿⣿⣿⣿"$fg"⣿⣿⣿⣿⣿⣵⡄⣶⡿⠿⢓⣸⣿⣿⣿"$r
        echo $pink"⡏⣼⣿⣿⣿⣿⣿⣿"$fg"⣿⣿⣿⣿⣿⣿⣄⢺⠶⠹⣿⣿⣿⣿⣿"$r
        echo $comment"⡇⣿⣿⣿⣿⣿⣿⣿"$fg"⣿⣿⣿⣿⣿⣿⡏⣰⣶⣿⣿⣿⣿⣿⣿"$r
        echo $comment"⠷⣙⠿⣿⣿⠿⠿⠛"$fg"⠻⠿⣿⣿⣿⠟⣱⣿⣿⣿⣿⣿⣿⣿⣿"$r
        echo $comment"⣾⣬⣭⣷⣶⣿⣿⣿"$fg"⣿⣿⣶⣦⡲⠷⡙⣿⣿⣿⣿⣿⣿⣿⣿"$r
        echo ""
    end

    _pikachu

end
