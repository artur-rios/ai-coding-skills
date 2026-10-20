#!/usr/bin/env pwsh

<#
.SYNOPSIS
    Mirrors the skills in this repo into the agent skill folders defined in .env.

.DESCRIPTION
    A skill is any top-level directory containing a SKILL.md file. Everything
    else in the repo (docs, README, LICENSE, .git, ...) is ignored.

    For each target folder the script:
      1. copies every skill in the repo, replacing the previous copy;
      2. removes the skills this repo used to ship but no longer does (renamed
         or deleted ones), so they stop competing for the same requests;
      3. records what it installed in a manifest file in the target folder.

    Only skills this repo shipped are ever removed: the ones listed in the
    target's manifest, plus every skill that appears in this repo's git history
    (which covers copies synced before the manifest existed). Skills from other
    sources in the same folder are never touched.

    Targets are read from .env in the repo root:
        CLAUDE_SKILLS="C:\Users\<user>\.claude\skills"
        CODEX_SKILLS="C:\Users\<user>\.agents\skills"
        OPENCODE_SKILLS="C:\Users\<user>\.config\opencode\skills"

.PARAMETER EnvFile
    Path to the env file. Defaults to .env next to this script.

.PARAMETER Target
    Restrict the sync to specific env keys (e.g. -Target CLAUDE_SKILLS).

.PARAMETER WhatIf
    Show what would be copied and removed without touching the filesystem.

.EXAMPLE
    ./sync-skills.ps1
    ./sync-skills.ps1 -Target CODEX_SKILLS
    ./sync-skills.ps1 -WhatIf

    On Linux/macOS run it with PowerShell 7:
    pwsh ./sync-skills.ps1
#>
[CmdletBinding(SupportsShouldProcess)]
param(
    [string]$EnvFile = (Join-Path $PSScriptRoot '.env'),
    [string[]]$Target = @('CLAUDE_SKILLS', 'CODEX_SKILLS', 'OPENCODE_SKILLS')
)

$ErrorActionPreference = 'Stop'

# Lives in each target folder. Agents only load directories that contain a
# SKILL.md, so a plain file next to them is never mistaken for a skill.
$ManifestName = '.ai-coding-skills.manifest'

function Read-EnvFile {
    param([string]$Path)

    if (-not (Test-Path -LiteralPath $Path)) {
        throw "Env file not found: $Path. Copy .env.example to .env and adjust the paths."
    }

    $values = @{}
    foreach ($line in Get-Content -LiteralPath $Path) {
        $trimmed = $line.Trim()
        if (-not $trimmed -or $trimmed.StartsWith('#')) { continue }

        $separator = $trimmed.IndexOf('=')
        if ($separator -lt 1) { continue }

        $key = $trimmed.Substring(0, $separator).Trim()
        $value = $trimmed.Substring($separator + 1).Trim().Trim('"', "'")
        if ($key) { $values[$key] = $value }
    }

    return $values
}

# Every skill name that has ever had a SKILL.md at the top of this repo, on any
# branch. Empty (with a warning) when git or the history is unavailable.
function Get-HistoricSkillNames {
    if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
        Write-Warning 'git not found: retired skills are detected from the manifests only.'
        return @()
    }

    $paths = & git -C $PSScriptRoot log --all --name-only --format= -- '*/SKILL.md' 2>$null
    if ($LASTEXITCODE -ne 0) {
        Write-Warning 'Could not read the git history: retired skills are detected from the manifests only.'
        return @()
    }

    return @($paths |
        Where-Object { $_ -match '^[^/]+/SKILL\.md$' } |
        ForEach-Object { $_.Split('/')[0] } |
        Sort-Object -Unique)
}

function Read-Manifest {
    param([string]$Path)

    if (-not (Test-Path -LiteralPath $Path)) { return @() }
    return @(Get-Content -LiteralPath $Path |
        ForEach-Object { $_.Trim() } |
        Where-Object { $_ -and -not $_.StartsWith('#') })
}

$envValues = Read-EnvFile -Path $EnvFile

$skills = Get-ChildItem -LiteralPath $PSScriptRoot -Directory |
    Where-Object { Test-Path -LiteralPath (Join-Path $_.FullName 'SKILL.md') } |
    Sort-Object Name

if (-not $skills) {
    Write-Warning "No skills found in $PSScriptRoot (a skill is a directory containing SKILL.md)."
    return
}

$skillNames = @($skills.Name)
$historicNames = Get-HistoricSkillNames

Write-Host "Skills found ($($skills.Count)): $($skillNames -join ', ')"

foreach ($key in $Target) {
    $destinationRoot = $envValues[$key]

    if ([string]::IsNullOrWhiteSpace($destinationRoot)) {
        Write-Warning "$key is not set in $EnvFile - skipping."
        continue
    }

    Write-Host ""
    Write-Host "-> $key : $destinationRoot"

    if ($PSCmdlet.ShouldProcess($destinationRoot, 'Create destination root')) {
        if (-not (Test-Path -LiteralPath $destinationRoot)) {
            New-Item -ItemType Directory -Path $destinationRoot -Force | Out-Null
        }
    }

    foreach ($skill in $skills) {
        $destination = Join-Path $destinationRoot $skill.Name

        if ($PSCmdlet.ShouldProcess($destination, "Copy skill '$($skill.Name)'")) {
            if (Test-Path -LiteralPath $destination) {
                Remove-Item -LiteralPath $destination -Recurse -Force
            }
            Copy-Item -LiteralPath $skill.FullName -Destination $destination -Recurse -Force
        }

        Write-Host "   + $($skill.Name)"
    }

    # Retired = shipped by this repo once (manifest or git history), not shipped now.
    $manifestPath = Join-Path $destinationRoot $ManifestName
    $shippedNames = @(Read-Manifest -Path $manifestPath) + $historicNames | Sort-Object -Unique
    $retiredNames = @($shippedNames | Where-Object { $_ -notin $skillNames })

    foreach ($name in $retiredNames) {
        $stale = Join-Path $destinationRoot $name

        # Only a directory that still looks like a skill is removed.
        if (-not (Test-Path -LiteralPath (Join-Path $stale 'SKILL.md'))) { continue }

        if ($PSCmdlet.ShouldProcess($stale, "Remove retired skill '$name'")) {
            Remove-Item -LiteralPath $stale -Recurse -Force
        }

        Write-Host "   - $name (no longer in this repo)"
    }

    if ($PSCmdlet.ShouldProcess($manifestPath, 'Write manifest')) {
        $header = "# Skills installed by $(Join-Path $PSScriptRoot 'sync-skills.ps1'). Do not edit;"
        $note = '# the next sync uses this list to remove skills the repo no longer ships.'
        Set-Content -LiteralPath $manifestPath -Value (@($header, $note) + $skillNames) -Encoding utf8
    }
}

Write-Host ""
Write-Host "Done."
