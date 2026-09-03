#!/usr/bin/env pwsh

<#
.SYNOPSIS
    Copies the skills in this repo to the target skill folders defined in .env.

.DESCRIPTION
    A skill is any top-level directory containing a SKILL.md file. Everything
    else in the repo (docs, README, LICENSE, .git, ...) is ignored.

    Targets are read from .env in the repo root:
        CLAUDE_SKILLS="C:\Users\<user>\.claude\skills"
        CODEX_SKILLS="C:\Users\<user>\.codex\skills"

.PARAMETER EnvFile
    Path to the env file. Defaults to .env next to this script.

.PARAMETER Target
    Restrict the sync to specific env keys (e.g. -Target CLAUDE_SKILLS).

.PARAMETER WhatIf
    Show what would be copied without touching the filesystem.

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
    [string[]]$Target = @('CLAUDE_SKILLS', 'CODEX_SKILLS')
)

$ErrorActionPreference = 'Stop'

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

$envValues = Read-EnvFile -Path $EnvFile

$skills = Get-ChildItem -LiteralPath $PSScriptRoot -Directory |
    Where-Object { Test-Path -LiteralPath (Join-Path $_.FullName 'SKILL.md') } |
    Sort-Object Name

if (-not $skills) {
    Write-Warning "No skills found in $PSScriptRoot (a skill is a directory containing SKILL.md)."
    return
}

Write-Host "Skills found ($($skills.Count)): $($skills.Name -join ', ')"

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

        Write-Host "   $($skill.Name)"
    }
}

Write-Host ""
Write-Host "Done."
