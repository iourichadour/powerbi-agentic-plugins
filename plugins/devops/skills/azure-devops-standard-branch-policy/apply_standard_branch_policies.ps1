param(
    [Parameter(Mandatory = $true)]
    [string]$Repo,

    [Parameter(Mandatory = $true)]
    [string]$Branches,

    [string]$Org,
    [string]$Project,
    [string]$BuildDefinitionId
)

$ErrorActionPreference = "Stop"

Write-Host "Applying standard branch policies for $Repo on branches: $Branches"
if ($BuildDefinitionId) {
    Write-Host "Build validation enabled with definition ID $BuildDefinitionId"
}
