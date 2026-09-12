#
# Creates an Azure DevOps pull request via `az repos pr create`.
#
# This script does NOT prompt for confirmation itself — the calling agent
# is responsible for showing the resolved plan (repo, source, target,
# title) to the user and getting an explicit "yes" before invoking this
# script. This mirrors apply_standard_branch_policies.ps1's reliance on the
# agent for the confirmation gate.
#
param(
    [string]$Repo,
    [string]$SourceBranch,
    [string]$TargetBranch = "DEV",
    [string]$Title,
    [string]$Org,
    [string]$Project
)

$ErrorActionPreference = "Stop"

# --- Prerequisite check: azure-devops extension + authenticated session ---
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

if (-not $Repo) {
    Write-Host "Prerequisite missing: -Repo is required (no repository was passed)." -ForegroundColor Red
    exit 1
}

# --- Always print the exact plan before creating anything ---
Write-Host "PR plan:" -ForegroundColor Cyan
Write-Host "  Repository:      $Repo"
Write-Host "  Source branch:   $SourceBranch"
Write-Host "  Target branch:   $TargetBranch"
Write-Host "  Title:           $Title"
if ($Org) { Write-Host "  Organization:    $Org" }
if ($Project) { Write-Host "  Project:         $Project" }

$argsList = @(
    "repos", "pr", "create",
    "--repository", $Repo,
    "--source-branch", $SourceBranch,
    "--target-branch", $TargetBranch,
    "--title", $Title
)
if ($Org) { $argsList += @("--org", $Org) }
if ($Project) { $argsList += @("--project", $Project) }

& az @argsList
$exitCode = $LASTEXITCODE

if ($exitCode -ne 0) {
    Write-Host "PR creation failed (az exit code $exitCode). See the CLI output above for details." -ForegroundColor Red
    exit $exitCode
}

Write-Host "Pull request created." -ForegroundColor Green
