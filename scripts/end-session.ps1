#Requires -Version 5.1
<##
.SYNOPSIS
    Validate and publish a session handoff for this repository.

.DESCRIPTION
    Stages only explicitly declared publishable handoff files, validates
    OpenSpec, commits the handoff, writes a local session resume file, then
    optionally pushes the Jira branch and creates a PR. The resume file is
    local-only and is never staged.

.EXAMPLE
    .\scripts\end-session.ps1 -OpenSpecChange enable-local-vscode-dax-tests `
        -ResumePath SESSION_RESUME.md -StagePath @(
            'MEMORY.md',
            'openspec/changes/enable-local-vscode-dax-tests/tasks.md'
        ) -CommitMessage 'docs: update session handoff'

.EXAMPLE
    .\scripts\end-session.ps1 -PowerBiRecoveryPath specs/FIN-1909-sales-report `
        -StagePath @('MEMORY.md') -ResumePath SESSION_RESUME.md
##>
[CmdletBinding(SupportsShouldProcess)]
param(
    [string]$OpenSpecChange,
    [string]$ResumePath = 'SESSION_RESUME.md',
    [string]$MemoryPath = 'MEMORY.md',
    [string]$PowerBiRecoveryPath,
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
        if ($LASTEXITCODE -ne 0) {
            throw "git $($Arguments -join ' ') failed:`n$($result -join "`n")"
        }
        return @($result)
    }

    function Test-CommandAvailable {
        param([Parameter(Mandatory)][string]$Name)
        return $null -ne (Get-Command $Name -ErrorAction SilentlyContinue)
    }

    function Get-NormalizedRelativePath {
        param([Parameter(Mandatory)][string]$Path)
        return $Path.Replace('\', '/').TrimStart('./')
    }

    function Get-RepoRelativePath {
        param([Parameter(Mandatory)][string]$FullPath)
        $resolved = [IO.Path]::GetFullPath($FullPath)
        $repoRoot = [IO.Path]::GetFullPath($repo).TrimEnd('\') + '\'
        if (-not $resolved.StartsWith($repoRoot, [StringComparison]::OrdinalIgnoreCase)) {
            throw "Path must remain inside the repository: $FullPath"
        }
        return $resolved.Substring($repoRoot.Length).Replace('\', '/')
    }

    function Resolve-RepoFile {
        param([Parameter(Mandatory)][string]$Path)
        $candidate = if ([IO.Path]::IsPathRooted($Path)) { $Path } else { Join-Path $repo $Path }
        if (-not (Test-Path $candidate -PathType Leaf)) {
            throw "Required handoff file was not found: $Path. Update it before ending the session."
        }
        return (Resolve-Path $candidate).Path
    }

    function Resolve-RepoDirectory {
        param([Parameter(Mandatory)][string]$Path)
        $candidate = if ([IO.Path]::IsPathRooted($Path)) { $Path } else { Join-Path $repo $Path }
        if (-not (Test-Path $candidate -PathType Container)) {
            throw "Power BI recovery folder was not found: $Path"
        }
        return (Resolve-Path $candidate).Path
    }

    function Test-PathPrefix {
        param(
            [Parameter(Mandatory)][string]$Path,
            [Parameter(Mandatory)][string]$Prefix
        )
        $normalizedPath = Get-NormalizedRelativePath $Path
        $normalizedPrefix = (Get-NormalizedRelativePath $Prefix).TrimEnd('/') + '/'
        return $normalizedPath.StartsWith($normalizedPrefix, [StringComparison]::OrdinalIgnoreCase)
    }

    function Assert-PublishablePath {
        param(
            [Parameter(Mandatory)][string]$RelativePath,
            [Parameter(Mandatory)][string]$NormalizedMemoryPath,
            [string]$NormalizedOpenSpecPrefix,
            [string]$NormalizedPowerBiPrefix
        )
        $normalized = Get-NormalizedRelativePath $RelativePath
        $resumeRelative = Get-NormalizedRelativePath $ResumePath
        if ($normalized -eq $resumeRelative) {
            throw "ResumePath is local-only and must never be staged: $RelativePath"
        }
        if ($normalized -eq $NormalizedMemoryPath) { return }
        if ($NormalizedOpenSpecPrefix -and (Test-PathPrefix $normalized $NormalizedOpenSpecPrefix)) { return }
        if ($NormalizedPowerBiPrefix -and (Test-PathPrefix $normalized $NormalizedPowerBiPrefix)) { return }
        throw "Unapproved handoff path '$RelativePath'. Declare MEMORY.md, a file under the active OpenSpec change, or an explicitly selected Power BI recovery folder."
    }

    function Test-PublishableStagedPath {
        param(
            [Parameter(Mandatory)][string]$RelativePath,
            [Parameter(Mandatory)][string]$NormalizedMemoryPath,
            [string]$NormalizedOpenSpecPrefix,
            [string]$NormalizedPowerBiPrefix
        )
        $normalized = Get-NormalizedRelativePath $RelativePath
        if ($normalized -eq $NormalizedMemoryPath) { return $true }
        if ($NormalizedOpenSpecPrefix -and (Test-PathPrefix $normalized $NormalizedOpenSpecPrefix)) { return $true }
        if ($NormalizedPowerBiPrefix -and (Test-PathPrefix $normalized $NormalizedPowerBiPrefix)) { return $true }
        return $false
    }

    function Write-LocalResume {
        param(
            [Parameter(Mandatory)][string]$Commit,
            [Parameter(Mandatory)][string[]]$Validation,
            [Parameter(Mandatory)][int]$UncheckedTasks
        )
        $resumeTarget = if ([IO.Path]::IsPathRooted($ResumePath)) { $ResumePath } else { Join-Path $repo $ResumePath }
        $resumeParent = Split-Path $resumeTarget -Parent
        if ($resumeParent -and -not (Test-Path $resumeParent -PathType Container)) {
            New-Item -ItemType Directory -Path $resumeParent -Force | Out-Null
        }
        $state = if ($OpenSpecChange) {
            "OpenSpec change '$OpenSpecChange'; $UncheckedTasks unchecked task(s) remain."
        } else {
            'Handoff commit completed without an active OpenSpec change.'
        }
        $next = if ($OpenSpecChange -and $UncheckedTasks -gt 0) {
            "Resume the next unchecked task in openspec/changes/$OpenSpecChange/tasks.md."
        } elseif ($OpenSpecChange) {
            'Review the completed OpenSpec handoff and request implementation explicitly when ready.'
        } else {
            'Resume from the route recovery record or the next explicit user request.'
        }
        $content = @(
            '# Session Resume',
            '',
            "- Last commit: $Commit",
            "- Validation: $($Validation -join '; ')",
            "- Current state: $state",
            "- Next resume point: $next",
            '',
            'This file is local-only. Durable facts belong in MEMORY.md and route progress belongs in the route recovery record.'
        ) -join "`n"
        Set-Content -LiteralPath $resumeTarget -Value $content -Encoding UTF8
        $resumeRelative = Get-RepoRelativePath $resumeTarget
        & git check-ignore --quiet -- $resumeRelative
        if ($LASTEXITCODE -ne 0) {
            Write-Warning "ResumePath '$resumeRelative' is not ignored; it was written locally but will not be staged by this script."
        }
    }

    $branch = (Invoke-Git @('branch', '--show-current')).Trim()
    if ([string]::IsNullOrWhiteSpace($branch)) { throw 'Detached HEAD is not supported by end-session workflow.' }
    $ticketMatch = [regex]::Match($branch, '(?<ticket>[A-Z]+-\d+)')
    $ticket = if ($ticketMatch.Success) { $ticketMatch.Groups['ticket'].Value } else { $null }
    $uncheckedCount = 0
    $validation = New-Object System.Collections.Generic.List[string]

    $status = @(Invoke-Git @('status', '--short'))
    if ($status.Count -gt 0 -and -not $AllowDirtyWorktree) {
        Write-Warning 'The worktree already contains changes. The script will stage only the declared publishable files.'
    }

    $memoryFullPath = Resolve-RepoFile $MemoryPath
    $normalizedMemoryPath = Get-RepoRelativePath $memoryFullPath
    $normalizedOpenSpecPrefix = $null
    if ($OpenSpecChange) {
        $normalizedOpenSpecPrefix = "openspec/changes/$OpenSpecChange"
    }

    $normalizedPowerBiPrefix = $null
    $powerBiFullPath = $null
    if ($PowerBiRecoveryPath) {
        $powerBiFullPath = Resolve-RepoDirectory $PowerBiRecoveryPath
        $powerBiRelative = Get-RepoRelativePath $powerBiFullPath
        if ($powerBiRelative -notmatch '^specs/[A-Z]+-\d+-[a-z0-9]+(?:-[a-z0-9]+)*/?$') {
            throw "PowerBiRecoveryPath must be an explicitly selected specs/<JIRA>-<slug>/ folder: $PowerBiRecoveryPath"
        }
        $normalizedPowerBiPrefix = $powerBiRelative.TrimEnd('/')
    }

    if (-not $StagePath) {
        $StagePath = @($MemoryPath)
    }
    $resolvedStagePaths = New-Object System.Collections.Generic.List[string]
    foreach ($declaredPath in $StagePath) {
        $fullPath = Resolve-RepoFile $declaredPath
        $relative = Get-RepoRelativePath $fullPath
        Assert-PublishablePath $relative $normalizedMemoryPath $normalizedOpenSpecPrefix $normalizedPowerBiPrefix
        if (-not $resolvedStagePaths.Contains($relative)) { $resolvedStagePaths.Add($relative) }
    }
    if ($powerBiFullPath) {
        if (-not $resolvedStagePaths.Contains($normalizedPowerBiPrefix)) { $resolvedStagePaths.Add($normalizedPowerBiPrefix) }
    }

    if (-not $SkipValidation) {
        if (-not (Test-Path (Join-Path $repo 'openspec'))) { throw 'openspec directory is missing.' }
        & openspec validate --specs
        if ($LASTEXITCODE -ne 0) { throw 'OpenSpec validation failed.' }
        $validation.Add('openspec validate --specs')
        if ($OpenSpecChange) {
            & openspec status --change $OpenSpecChange --json | Out-Host
            if ($LASTEXITCODE -ne 0) { throw "OpenSpec status failed for change: $OpenSpecChange" }
            $validation.Add("openspec status --change $OpenSpecChange --json")
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
        $validation.Add('git diff --check')
    } else {
        $validation.Add('validation skipped by -SkipValidation')
    }

    $addArguments = @('add', '--') + @($resolvedStagePaths)
    Invoke-Git $addArguments | Out-Null
    $staged = @(Invoke-Git @('diff', '--cached', '--name-only')) | ForEach-Object { $_.ToString().Trim() } | Where-Object { $_ }
    $unexpected = @($staged | Where-Object {
        -not (Test-PublishableStagedPath $_ $normalizedMemoryPath $normalizedOpenSpecPrefix $normalizedPowerBiPrefix)
    })
    if ($unexpected.Count -gt 0) {
        throw "Unexpected staged files would be committed: $($unexpected -join ', '). Unstage them and retry."
    }
    if ($staged.Count -eq 0) {
        Write-Host 'No publishable handoff changes exist; nothing to commit.' -ForegroundColor Yellow
        return
    }
    Write-Host 'Staged files:' -ForegroundColor Cyan
    $staged | ForEach-Object { Write-Host "  $_" }

    if (-not $PSCmdlet.ShouldProcess($branch, 'Commit session handoff')) { return }
    Invoke-Git @('commit', '-m', $CommitMessage) | ForEach-Object { Write-Host $_ }
    $commit = (Invoke-Git @('rev-parse', 'HEAD')).Trim()
    Write-LocalResume -Commit $commit -Validation @($validation) -UncheckedTasks $uncheckedCount

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
                '- Updated the session memory and route-owned recovery handoff.',
                '- Kept the local session resume file out of the commit.',
                '',
                '## Validation',
                "- $($validation -join "`n- ")",
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
