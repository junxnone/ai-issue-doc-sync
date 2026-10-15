#!/usr/bin/env pwsh
<#
.SYNOPSIS
  Install the issue-doc-sync Claude Code skill.

.PARAMETER Target
  Path to a project repo to install into (.claude/skills/issue-doc-sync).
  If omitted, installs globally to ~/.claude/skills/issue-doc-sync.

.EXAMPLE
  .\install.ps1 -Target "C:\path\to\your-repo"

.EXAMPLE
  .\install.ps1
#>
param(
    [string]$Target
)

$ErrorActionPreference = "Stop"

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$SrcFile = Join-Path $ScriptDir "SKILL.md"

if (-not (Test-Path $SrcFile)) {
    Write-Error "error: $SrcFile not found (run this script from inside ai-issue-doc-sync)"
    exit 1
}

if ($Target) {
    if (-not (Test-Path $Target)) {
        Write-Error "error: target directory '$Target' does not exist"
        exit 1
    }
    $Dest = Join-Path (Join-Path (Join-Path $Target ".claude") "skills") "issue-doc-sync"
} else {
    $Dest = Join-Path (Join-Path (Join-Path $HOME ".claude") "skills") "issue-doc-sync"
}

New-Item -ItemType Directory -Force -Path $Dest | Out-Null
Copy-Item -Path $SrcFile -Destination (Join-Path $Dest "SKILL.md") -Force

Write-Host "Installed issue-doc-sync skill to: $Dest"
