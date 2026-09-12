#
# Idempotent Azure CLI (`az`) + azure-devops extension setup for machines
# without admin rights. Safe to re-run: every step checks current state
# before making a change.
#
param(
    [string]$InstallDir = "$env:LOCALAPPDATA\GitHubCopilotCLI\az",
    [string]$Organization = "https://dev.azure.com/bayviewasset",
    [string]$Project,
    [switch]$SkipPath,
    [switch]$SkipExtension,
    [switch]$SkipDefaults
)

$ErrorActionPreference = "Stop"

$azCmd = Join-Path $InstallDir "bin\az.cmd"

if (-not (Test-Path $azCmd)) {
    Write-Host "Azure CLI not found at '$azCmd' - downloading zip distribution..." -ForegroundColor Cyan
    $zipUrl = "https://aka.ms/installazurecliwindowszipx64"
    $zipPath = Join-Path $env:TEMP "azure-cli-$(Get-Random).zip"
    Invoke-WebRequest -Uri $zipUrl -OutFile $zipPath
    New-Item -ItemType Directory -Path $InstallDir -Force | Out-Null
    Expand-Archive -Path $zipPath -DestinationPath $InstallDir -Force
    Remove-Item $zipPath -Force
    if (-not (Test-Path $azCmd)) {
        Write-Host "Extraction did not produce '$azCmd' - check the zip layout at $zipUrl." -ForegroundColor Red
        exit 1
    }
    Write-Host "Installed Azure CLI to '$InstallDir'." -ForegroundColor Green
} else {
    Write-Host "Azure CLI already installed at '$azCmd'." -ForegroundColor Green
}

$binDir = Join-Path $InstallDir "bin"

if (-not $SkipPath) {
    $userPath = [Environment]::GetEnvironmentVariable("Path", "User")
    if ($userPath -notlike "*$binDir*") {
        [Environment]::SetEnvironmentVariable("Path", "$userPath;$binDir", "User")
        Write-Host "Added '$binDir' to the User PATH (open a new terminal to pick it up)." -ForegroundColor Green
    } else {
        Write-Host "'$binDir' is already on the User PATH." -ForegroundColor Green
    }
    if ($env:Path -notlike "*$binDir*") {
        $env:Path = "$env:Path;$binDir"
    }
}

Write-Host "az --version:" -ForegroundColor Cyan
& $azCmd --version | Select-Object -First 1

if (-not $SkipExtension) {
    $hasExtension = & $azCmd extension list -o tsv --query "[?name=='azure-devops'].name" 2>$null
    if (-not $hasExtension) {
        & $azCmd extension add --name azure-devops --only-show-errors
        Write-Host "Installed the azure-devops CLI extension." -ForegroundColor Green
    } else {
        Write-Host "azure-devops CLI extension already installed." -ForegroundColor Green
    }
}

if (-not $SkipDefaults) {
    & $azCmd devops configure --defaults "organization=$Organization" | Out-Null
    Write-Host "Set default organization to '$Organization'." -ForegroundColor Green
    if ($Project) {
        & $azCmd devops configure --defaults "project=$Project" | Out-Null
        Write-Host "Set default project to '$Project'." -ForegroundColor Green
    }
}

$account = & $azCmd account show -o json 2>$null
if (-not $account) {
    Write-Host "Not logged in. Run 'az login' interactively (opens a browser), then re-run 'az devops project list -o table' to verify access." -ForegroundColor Yellow
} else {
    Write-Host "Already authenticated with Azure. Verifying DevOps access..." -ForegroundColor Green
    & $azCmd devops project list -o table
}
