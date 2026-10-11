#
# Creates a pull request for the current repository. The host is detected from
# `git remote get-url origin`:
#   github.com            -> `gh pr create`
#   dev.azure.com         -> `az repos pr create`
#   anything else         -> reported as unsupported, nothing is created
#
# This script does NOT prompt for confirmation itself — the calling agent
# is responsible for showing the resolved plan (repo, source, target,
# title) to the user and getting an explicit "yes" before invoking this
# script. This mirrors apply_standard_branch_policies.ps1's reliance on the
# agent for the confirmation gate.
#
# -Repo is required for Azure DevOps remotes and optional for GitHub (defaults
# to the origin remote). -Org and -Project apply to Azure DevOps remotes only.
#
param(
    [string]$Repo,
    [string]$SourceBranch,
    [string]$TargetBranch = "DEV",
    [string]$Title,
    [string]$Body = "",
    [string]$Org,
    [string]$Project
)

$ErrorActionPreference = "Stop"

# --- Detect the host from the origin remote ---
$remoteUrl = (& git remote get-url origin 2>$null)
if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrWhiteSpace($remoteUrl)) {
    Write-Host "Could not read the 'origin' remote URL (git remote get-url origin). Add an origin remote first." -ForegroundColor Red
    exit 1
}
$remoteUrl = $remoteUrl.Trim()

# Reduce the URL to its host: strip scheme, user@, then everything after the host.
$remoteHost = $remoteUrl
if ($remoteHost -match '://') { $remoteHost = $remoteHost.Substring($remoteHost.IndexOf('://') + 3) }
if ($remoteHost -match '@') { $remoteHost = $remoteHost.Substring($remoteHost.IndexOf('@') + 1) }
$remoteHost = ($remoteHost -split '[/:]')[0].ToLowerInvariant()

switch ($remoteHost) {
    "github.com" { $hostKind = "github" }
    { $_ -in @("dev.azure.com", "ssh.dev.azure.com") } { $hostKind = "azure" }
    default {
        Write-Host "Unsupported remote host '$remoteHost' (origin: $remoteUrl). Only github.com and dev.azure.com are supported. No pull request was created." -ForegroundColor Red
        exit 1
    }
}
Write-Host "Detected host: $remoteHost ($hostKind)" -ForegroundColor Cyan

# --- Prerequisite check for the detected host ---
if ($hostKind -eq "github") {
    if (-not (Get-Command gh -ErrorAction SilentlyContinue)) {
        Write-Host "Prerequisite missing: the GitHub CLI ('gh') is not installed. Install it from https://cli.github.com and run 'gh auth login'." -ForegroundColor Red
        exit 1
    }
    & gh auth status *> $null
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Prerequisite missing: 'gh' is not authenticated. Run 'gh auth login' first." -ForegroundColor Red
        exit 1
    }
} else {
    $hasExtension = & az extension list -o tsv --query "[?name=='azure-devops'].name" 2>$null
    if (-not $hasExtension) {
        Write-Host "Prerequisite missing: the 'azure-devops' CLI extension is not installed. Run 'az extension add --name azure-devops' (or plugins/devops/skills/git-branch-guard/assets/setup_azure_cli.ps1) first." -ForegroundColor Red
        exit 1
    }

    $account = & az account show -o json 2>$null
    if (-not $account) {
        Write-Host "Prerequisite missing: no authenticated Azure CLI session. Run 'az login' first." -ForegroundColor Red
        exit 1
    }

    if (-not $Org -and -not $Project) {
        $defaults = & az devops configure --list -o tsv 2>$null
        if (-not ($defaults -match "organization")) {
            Write-Host "Prerequisite missing: no default organization is configured and -Org was not provided. Run 'az devops configure --defaults organization=<url>' or pass -Org explicitly." -ForegroundColor Red
            exit 1
        }
    }
}

# --- Resolve source branch / title from the current branch if not passed ---
if (-not $SourceBranch) {
    $SourceBranch = (git branch --show-current).Trim()
    if ([string]::IsNullOrWhiteSpace($SourceBranch)) {
        Write-Host "Could not determine the current Git branch to use as -SourceBranch. Pass -SourceBranch explicitly." -ForegroundColor Red
        exit 1
    }
    Write-Host "Resolved -SourceBranch from the current branch: '$SourceBranch'" -ForegroundColor Cyan
}

if (-not $Title) {
    if ($SourceBranch -match '([A-Z]+-\d+)') {
        $Title = "$($Matches[1]): $SourceBranch"
    } else {
        $Title = $SourceBranch
    }
    Write-Host "Resolved -Title from the source branch: '$Title'" -ForegroundColor Cyan
}

if ($hostKind -eq "azure" -and -not $Repo) {
    Write-Host "Prerequisite missing: -Repo is required for Azure DevOps remotes (no repository was passed)." -ForegroundColor Red
    exit 1
}

# --- Always print the exact plan before creating anything ---
$repoDisplay = if ($Repo) { $Repo } else { "(from origin: $remoteUrl)" }
Write-Host "PR plan:" -ForegroundColor Cyan
Write-Host "  Host:            $remoteHost"
Write-Host "  Repository:      $repoDisplay"
Write-Host "  Source branch:   $SourceBranch"
Write-Host "  Target branch:   $TargetBranch"
Write-Host "  Title:           $Title"
if ($Body) { Write-Host "  Body:            $Body" }
if ($Org) { Write-Host "  Organization:    $Org" }
if ($Project) { Write-Host "  Project:         $Project" }

if ($hostKind -eq "github") {
    $tool = "gh"
    $argsList = @(
        "pr", "create",
        "--base", $TargetBranch,
        "--head", $SourceBranch,
        "--title", $Title,
        "--body", $Body
    )
    if ($Repo) { $argsList += @("--repo", $Repo) }
} else {
    $tool = "az"
    $argsList = @(
        "repos", "pr", "create",
        "--repository", $Repo,
        "--source-branch", $SourceBranch,
        "--target-branch", $TargetBranch,
        "--title", $Title
    )
    if ($Body) { $argsList += @("--description", $Body) }
    if ($Org) { $argsList += @("--org", $Org) }
    if ($Project) { $argsList += @("--project", $Project) }
}

& $tool @argsList
$exitCode = $LASTEXITCODE

if ($exitCode -ne 0) {
    Write-Host "PR creation failed ($tool exit code $exitCode). See the CLI output above for details." -ForegroundColor Red
    exit $exitCode
}

Write-Host "Pull request created." -ForegroundColor Green
