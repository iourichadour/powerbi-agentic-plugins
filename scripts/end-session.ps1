#Requires -Version 5.1
<#
.SYNOPSIS
    Validate and publish a session handoff for this repository.

.DESCRIPTION
    Stages only the explicitly declared handoff files, validates OpenSpec,
    commits the handoff, pushes the current Jira branch, and creates a PR.
    It prints a Jira-ready update after the commit and PR exist. Jira posting
    itself remains an explicit agent/MCP action so credentials and transitions
    are not guessed by this script.

.EXAMPLE
    .\scripts\end-session.ps1 -OpenSpecChange enable-local-vscode-dax-tests `
        -ResumePath SESSION_RESUME.md -CommitMessage "docs: update session handoff"

.EXAMPLE
    .\scripts\end-session.ps1 -OpenSpecChange enable-local-vscode-dax-tests `
        -StagePath @('MEMORY.md','SESSION_RESUME.md','openspec/changes/.../tasks.md')
#>
[CmdletBinding(SupportsShouldProcess)]
param(
    [string]$OpenSpecChange,
    [string]$ResumePath = 'SESSION_RESUME.md',
    [string]$MemoryPath = 'MEMORY.md',
    [string[]]$StagePath,
    [string]$CommitMessage = 'docs: update session handoff',
    [string]$BaseBranch = 'DEV',
    [string]$PullRequestTitle,
    [string]$PullRequestBody,
    [switch]$SkipValidation,
    [switch]$SkipPush,
    [switch]$SkipPullRequest,
    [switch]$AllowDirtyWorktree
)

$ErrorActionPreference = 'Stop'
$repo = Split-Path $PSScriptRoot -Parent
Push-Location $repo
try {
    function Invoke-Git {
        param([Parameter(Mandatory)][string[]]$Arguments)
        $result = & git @Arguments 2>&1
        if ($LASTEXITCODE -ne 0) { throw "git $($Arguments -join ' ') failed:`n$($result -join "`n")" }
        return @($result)
    }

    function Test-CommandAvailable {
        param([Parameter(Mandatory)][string]$Name)
        return $null -ne (Get-Command $Name -ErrorAction SilentlyContinue)
    }

    function Resolve-RepoPath {
        param([Parameter(Mandatory)][string]$Path)
        $candidate = Join-Path $repo $Path
        if (-not (Test-Path $candidate -PathType Leaf)) {
            throw "Required handoff file was not found: $Path. Update it before ending the session."
        }
        return (Resolve-Path $candidate).Path
    }

    $branch = (Invoke-Git @('branch', '--show-current')).Trim()
    if ([string]::IsNullOrWhiteSpace($branch)) { throw 'Detached HEAD is not supported by end-session workflow.' }
    $ticketMatch = [regex]::Match($branch, '(?<ticket>[A-Z]+-\d+)')
    $ticket = if ($ticketMatch.Success) { $ticketMatch.Groups['ticket'].Value } else { $null }
    $uncheckedCount = 0

    $status = @(Invoke-Git @('status', '--short'))
    if ($status.Count -gt 0 -and -not $AllowDirtyWorktree) {
        Write-Warning 'The worktree already contains changes. The script will stage only the declared handoff files.'
    }

    if (-not $StagePath) {
        $StagePath = @($MemoryPath, $ResumePath)
    }
    $resolvedStagePaths = @($StagePath | ForEach-Object { Resolve-RepoPath $_ })

    if (-not $SkipValidation) {
        if (-not (Test-Path (Join-Path $repo 'openspec'))) { throw 'openspec directory is missing.' }
        & openspec validate --specs
        if ($LASTEXITCODE -ne 0) { throw 'OpenSpec validation failed.' }
        if ($OpenSpecChange) {
            & openspec status --change $OpenSpecChange --json | Out-Host
            if ($LASTEXITCODE -ne 0) { throw "OpenSpec status failed for change: $OpenSpecChange" }
            $tasksPath = Join-Path $repo "openspec\changes\$OpenSpecChange\tasks.md"
            if (Test-Path $tasksPath) {
                $uncheckedCount = @(Select-String -Path $tasksPath -Pattern '^- \[ \]' -AllMatches).Count
                if ($uncheckedCount -gt 0) {
                    Write-Warning "$uncheckedCount OpenSpec task(s) remain unchecked for '$OpenSpecChange'. They will not be marked complete automatically."
                }
            }
        }
        & git diff --check
        if ($LASTEXITCODE -ne 0) { throw 'Whitespace validation failed.' }
    }

    $addArguments = @('add', '--') + $resolvedStagePaths
    Invoke-Git $addArguments | Out-Null
    $staged = @(Invoke-Git @('diff', '--cached', '--name-only'))
    if ($staged.Count -eq 0) { throw 'No staged handoff changes found. Update MEMORY.md or the resume file first.' }
    Write-Host "Staged files:" -ForegroundColor Cyan
    $staged | ForEach-Object { Write-Host "  $_" }

    if (-not $PSCmdlet.ShouldProcess($branch, "Commit session handoff")) { return }
    Invoke-Git @('commit', '-m', $CommitMessage) | ForEach-Object { Write-Host $_ }
    $commit = (Invoke-Git @('rev-parse', 'HEAD')).Trim()

    if (-not $SkipPush) {
        Invoke-Git @('push', '--set-upstream', 'origin', $branch) | ForEach-Object { Write-Host $_ }
    }

    $prUrl = $null
    if (-not $SkipPullRequest) {
        if (-not (Test-CommandAvailable 'gh')) { throw 'GitHub CLI (gh) is required to create the pull request, or use -SkipPullRequest.' }
        if ([string]::IsNullOrWhiteSpace($PullRequestTitle)) {
            $PullRequestTitle = if ($ticket) { "${ticket}: session handoff" } else { 'Session handoff' }
        }
        if ([string]::IsNullOrWhiteSpace($PullRequestBody)) {
            $PullRequestBody = @(
                '## Summary',
                '- Updated the session memory and resume handoff.',
                '- Preserved OpenSpec task status without inferring completion.',
                '',
                '## Validation',
                '- `openspec validate --specs`',
                '- `git diff --check`',
                '',
                '## Commit',
                "- $commit",
                '',
                '## OpenSpec',
                "- Change: $(if ($OpenSpecChange) { $OpenSpecChange } else { 'Not specified' })",
                "- Unchecked tasks: $uncheckedCount"
            ) -join "`n"
        }
        $prUrl = (& gh pr create --base $BaseBranch --head $branch --title $PullRequestTitle --body $PullRequestBody 2>&1)
        if ($LASTEXITCODE -ne 0) {
            $prError = $prUrl -join [Environment]::NewLine
            throw "gh pr create failed:`n$prError"
        }
        $prUrl = ($prUrl | Select-Object -Last 1).ToString().Trim()
    }

    $jiraLines = @(
        $(if ($ticket) { "$ticket session update" } else { 'Session update' }),
        '',
        'Commit:',
        "- $commit",
        '',
        'Pull request:',
        "- $(if ($prUrl) { $prUrl } else { 'Not created' })"
    )
    if ($OpenSpecChange) { $jiraLines += @('', 'OpenSpec change:', "- $OpenSpecChange") }
    $jiraLines += @("- Unchecked tasks: $uncheckedCount")
    Write-Host "`nJira update (post through the Jira workflow):`n$($jiraLines -join "`n")" -ForegroundColor Green
    Write-Host "`nSession handoff complete: branch=$branch commit=$commit PR=$prUrl" -ForegroundColor Green
}
finally {
    Pop-Location
}
