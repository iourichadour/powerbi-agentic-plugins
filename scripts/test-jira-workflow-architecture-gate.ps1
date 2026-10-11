#Requires -Version 5.1
[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$repo = Split-Path $PSScriptRoot -Parent

function Assert-True {
    param([Parameter(Mandatory)][bool]$Condition, [Parameter(Mandatory)][string]$Message)
    if (-not $Condition) { throw "Assertion failed: $Message" }
}

function Assert-Contains {
    param(
        [Parameter(Mandatory)][string]$Text,
        [Parameter(Mandatory)][string]$Needle,
        [Parameter(Mandatory)][string]$Message
    )
    Assert-True ($Text.Contains($Needle)) $Message
}

function Invoke-TestGit {
    param(
        [Parameter(Mandatory)][string]$Root,
        [Parameter(Mandatory)][string[]]$Arguments
    )
    $oldErrorActionPreference = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'
    try {
        $result = @(& git -C $Root @Arguments 2>&1 | ForEach-Object { $_.ToString() })
    }
    finally {
        $ErrorActionPreference = $oldErrorActionPreference
    }
    if ($LASTEXITCODE -ne 0) { throw "git $($Arguments -join ' ') failed: $($result -join "`n")" }
    return @($result)
}

$jiraSkill = Get-Content -Raw (Join-Path $repo 'plugins/devops/skills/jira-workflow/SKILL.md')
$troubleshootingSkill = Get-Content -Raw (Join-Path $repo 'plugins/devops/skills/troubleshooting-workflow/SKILL.md')
$devopsAgent = Get-Content -Raw (Join-Path $repo 'plugins/devops/agents/devops.agent.md')
$prompt = Get-Content -Raw (Join-Path $repo '.github/prompts/jira-workflow.md')
$memory = Get-Content -Raw (Join-Path $repo 'MEMORY.md')
$endSession = Get-Content -Raw (Join-Path $repo 'scripts/end-session.ps1')
$memoryPointer = Get-Content -Raw (Join-Path $repo 'plugins/devops/skills/troubleshooting-workflow/assets/repo-memory-convention.template.md')

foreach ($category in @('**Bug**', '**Report Development Story**', '**Fabric Development**', '**Other**')) {
    Assert-Contains $jiraSkill $category "Jira skill documents category $category"
}
Assert-Contains $jiraSkill 'never infer or silently' 'Jira metadata cannot silently select a category'
Assert-Contains $jiraSkill 'Routing remains unresolved' 'Category cancellation stops routing'
foreach ($subtype in @('New report or dashboard', 'Existing report change', 'Model-only work', 'Report publishing or management')) {
    Assert-Contains $jiraSkill $subtype "Report subtype is documented: $subtype"
}
Assert-Contains $jiraSkill 'openspec new change' 'Fabric creates OpenSpec changes'
Assert-Contains $jiraSkill 'starts with the Jira' 'Fabric resume lookup uses the Jira prefix'
Assert-Contains $jiraSkill 'openspec-apply-change' 'Fabric implementation handoff is explicit'
Assert-Contains $jiraSkill 'simple operational Fabric' 'Simple Fabric operations can route directly'
Assert-Contains $troubleshootingSkill 'If evidence is unavailable' 'Troubleshooting records evidence blockers'
Assert-Contains $troubleshootingSkill 'extract reusable facts' 'Troubleshooting extracts reusable guidance'
Assert-Contains $troubleshootingSkill 'post-diagnosis fix gate' 'Troubleshooting has the post-diagnosis fix gate'
Assert-Contains $troubleshootingSkill 'Do not create a new brief' 'Surgical fixes avoid new planning records'
Assert-Contains $devopsAgent 'SESSION_RESUME.md' 'DevOps agent owns the local handoff update'
Assert-Contains $memory 'Cold-start orientation' 'Memory has cold-start orientation'
Assert-Contains $memory 'never contains ticket' 'Memory excludes transient ticket state'
Assert-Contains $memoryPointer '`MEMORY.md`' 'Memory pointer targets MEMORY.md'
Assert-True (-not $memoryPointer.Contains('TROUBLESHOOTING.md')) 'Memory pointer references only MEMORY.md'
Assert-Contains $endSession 'PowerBiRecoveryPath' 'End-session supports selected report recovery folders'
Assert-Contains $endSession 'No publishable handoff changes exist' 'End-session has a no-op path'
Assert-Contains $endSession 'ResumePath is local-only' 'End-session prevents staging the local resume path'

$tempRoot = Join-Path ([IO.Path]::GetTempPath()) ("jira-workflow-gate-" + [guid]::NewGuid().ToString('N'))
try {
    New-Item -ItemType Directory -Path (Join-Path $tempRoot 'scripts') -Force | Out-Null
    New-Item -ItemType Directory -Path (Join-Path $tempRoot 'specs/FIN-1909-report') -Force | Out-Null
    New-Item -ItemType Directory -Path (Join-Path $tempRoot 'specs/OTHER-1-unrelated') -Force | Out-Null
    Copy-Item (Join-Path $repo 'scripts/end-session.ps1') (Join-Path $tempRoot 'scripts/end-session.ps1')
    Set-Content -LiteralPath (Join-Path $tempRoot 'MEMORY.md') -Value '# Memory' -Encoding UTF8
    Set-Content -LiteralPath (Join-Path $tempRoot 'SESSION_RESUME.md') -Value '# Old local handoff' -Encoding UTF8
    Set-Content -LiteralPath (Join-Path $tempRoot '.gitignore') -Value '/SESSION_RESUME.md' -Encoding UTF8
    Set-Content -LiteralPath (Join-Path $tempRoot 'specs/FIN-1909-report/brief.md') -Value 'draft selected report record' -Encoding UTF8
    Set-Content -LiteralPath (Join-Path $tempRoot 'specs/OTHER-1-unrelated/brief.md') -Value 'draft unrelated report record' -Encoding UTF8

    Invoke-TestGit $tempRoot @('init', '--initial-branch=main') | Out-Null
    Invoke-TestGit $tempRoot @('config', 'core.autocrlf', 'false') | Out-Null
    Invoke-TestGit $tempRoot @('config', 'user.email', 'fixture@example.invalid') | Out-Null
    Invoke-TestGit $tempRoot @('config', 'user.name', 'Architecture Gate Fixture') | Out-Null
    Invoke-TestGit $tempRoot @('add', '.') | Out-Null
    Invoke-TestGit $tempRoot @('commit', '-m', 'fixture baseline') | Out-Null
    Invoke-TestGit $tempRoot @('checkout', '-b', 'feature/FIN-1909-fixture') | Out-Null

    Add-Content -LiteralPath (Join-Path $tempRoot 'MEMORY.md') -Value "`nupdated durable fact"
    Add-Content -LiteralPath (Join-Path $tempRoot 'specs/FIN-1909-report/brief.md') -Value "`nprogress: approved"
    Add-Content -LiteralPath (Join-Path $tempRoot 'specs/OTHER-1-unrelated/brief.md') -Value "`nshould remain unstaged"
    Set-Content -LiteralPath (Join-Path $tempRoot 'SESSION_RESUME.md') -Value '# Local only' -Encoding UTF8

    $runOutput = & powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $tempRoot 'scripts/end-session.ps1') `
        -PowerBiRecoveryPath 'specs/FIN-1909-report' `
        -StagePath @('MEMORY.md') `
        -ResumePath 'SESSION_RESUME.md' `
        -CommitMessage 'fixture selected report handoff' `
        -SkipValidation -SkipPush -SkipPullRequest -AllowDirtyWorktree 2>&1
    if ($LASTEXITCODE -ne 0) { throw "Selected recovery-folder fixture failed: $($runOutput -join "`n")" }

    $committed = @(Invoke-TestGit $tempRoot @('show', '--format=', '--name-only', 'HEAD')) | ForEach-Object { $_.ToString().Trim() } | Where-Object { $_ }
    Assert-True ($committed -contains 'MEMORY.md') 'Selected run stages MEMORY.md'
    Assert-True ($committed -contains 'specs/FIN-1909-report/brief.md') 'Selected run stages the declared report recovery folder'
    Assert-True ($committed -notcontains 'specs/OTHER-1-unrelated/brief.md') 'Selected run excludes unrelated report folders'
    Assert-True ($committed -notcontains 'SESSION_RESUME.md') 'Selected run excludes SESSION_RESUME.md'
    $resume = Get-Content -Raw (Join-Path $tempRoot 'SESSION_RESUME.md')
    Assert-Contains $resume 'Last commit:' 'Post-commit local resume records the commit'
    Assert-Contains $resume 'Validation:' 'Post-commit local resume records validation'
    Assert-Contains $resume 'Current state:' 'Post-commit local resume records current state'
    Assert-Contains $resume 'Next resume point:' 'Post-commit local resume records next point'
    Assert-True ((Invoke-TestGit $tempRoot @('check-ignore', '--quiet', '--', 'SESSION_RESUME.md')).Count -eq 0) 'SESSION_RESUME.md is ignored'
    Assert-True ((Invoke-TestGit $tempRoot @('status', '--short')).Count -eq 1) 'Only unrelated report work remains in status'

    $noOpOutput = & powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $tempRoot 'scripts/end-session.ps1') `
        -ResumePath 'SESSION_RESUME.md' -SkipValidation -SkipPush -SkipPullRequest -AllowDirtyWorktree 2>&1 | Out-String
    if ($LASTEXITCODE -ne 0) { throw "No-op fixture failed: $noOpOutput" }
    Assert-Contains $noOpOutput 'No publishable handoff changes exist' 'Only local handoff changes do not fail or commit'
}
finally {
    if (Test-Path $tempRoot) { Remove-Item -LiteralPath $tempRoot -Recurse -Force }
}

Write-Host 'Jira workflow architecture-gate fixtures passed.' -ForegroundColor Green
