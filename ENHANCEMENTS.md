# SuperShell — Enhancement Backlog

Improvements identified during the launch-update code review (June 2026), to be
worked through incrementally. Bugs found in that review have already been fixed;
these are the "would be better" items, roughly ordered by value.

## 1. In-session launcher regeneration (kills the restart requirement)

`update-apps` already refreshes `$script:AppMap` so `run` sees new apps
immediately, but bare-word launchers are only generated at profile load.
Extract the function-generation `foreach` into a helper (e.g.
`Update-AppLaunchers`) and call it from both profile load and `update-apps`.
Then remove the "Restart shell to regenerate" message and the README caveat.

## 2. Batch the collision guard (startup latency)

The generation loop calls `Get-Command` once per cached app — with hundreds of
apps that's hundreds of command resolutions at every startup. `Get-Command`
accepts an array: resolve all names in one call, put the hits in a HashSet,
then test membership in the loop.

```powershell
$existing = [System.Collections.Generic.HashSet[string]]::new(
    [string[]](Get-Command -Name @($script:AppMap.Keys) -ErrorAction Ignore).Name,
    [System.StringComparer]::OrdinalIgnoreCase)
```

## 3. UWP / Microsoft Store app discovery

App Paths + Start Menu .lnk scanning misses Store apps entirely (Spotify,
WhatsApp, Terminal, etc.). Add a third source in `Get-InstalledGuiApps`:
`Get-StartApps` returns Name + AppID (AppUserModelID); launch via
`explorer.exe shell:AppsFolder\<AppID>`. Needs a marker in the cache to
distinguish "path" entries (Start-Process) from "AUMID" entries (explorer).

## 4. CI on a Windows runner

The dev machine is Linux, so the PowerShell scripts are never executed before
merge — the `$pid`/`$host` read-only-variable bugs shipped because of this.
Add a GitHub Actions workflow (`windows-latest`):
- PSScriptAnalyzer over `*.ps1`
- Parse check ([System.Management.Automation.Language.Parser]::ParseFile)
- Smoke test: dot-source the launcher section against a seeded cache
  (the container test approach from the review can be ported directly)
Optionally lint `config.fish` / `install-supershell.sh` on `ubuntu-latest`.

## 5. `run` passes arguments through to the launched app

`run brave --incognito` currently treats `--incognito` as part of the fzf
query. After selection, pass any args beyond the query through to
`Start-Process -ArgumentList`. Needs a convention to split query from args
(e.g. `run <query> -- <args...>`).

## 6. Cache staleness auto-refresh

`apps.json` only updates when the user remembers to run `update-apps`. Options:
check the cache file age at startup and, if older than ~7 days, kick off a
background rescan (`Start-ThreadJob`) that rewrites the cache for next launch —
keeps the prompt-latency guarantee while staying fresh.

## 7. Shared launch helper

The generated per-app functions and `run` both call `Start-Process` with their
own logic. A single `Invoke-AppLaunch -Name <n>` helper reading
`$script:AppMap` centralizes behavior (and is where the UWP/AUMID branch from
item 3 would live).

## 8. fzf preview in the `run` picker

Show the resolved target path in an fzf preview pane so near-identical entries
("brave" vs "brave-browser") are distinguishable before launching.

## 9. Installer module-install helper

The CompletionPredictor block in `install-supershell.ps1` hand-rolls the
check/install/verify/DryRun pattern. If more PSGallery modules get added,
extract an `Install-PSModuleGroup` helper mirroring `Install-WingetGroup`.

## 10. Document gsudo extras

`gsudoModule` (when present) also provides `gsudo !!` (re-run last command
elevated). Worth a line in the README's elevation section and `shelp`.
