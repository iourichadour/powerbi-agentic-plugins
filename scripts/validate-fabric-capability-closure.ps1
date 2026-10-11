#Requires -Version 5.1
[CmdletBinding()]
param([string]$RepositoryPath = (Split-Path $PSScriptRoot -Parent))

$ErrorActionPreference = 'Stop'
$pluginRoot = Join-Path $RepositoryPath 'plugins\fabric'
$closurePath = Join-Path $pluginRoot 'capability-closure.json'
$closure = Get-Content $closurePath -Raw | ConvertFrom-Json

foreach ($agent in $closure.agents) {
    $path = Join-Path $pluginRoot "agents\$agent"
    if (-not (Test-Path $path -PathType Leaf)) { throw "Missing closure agent: $agent" }
}
foreach ($skill in $closure.skills) {
    $path = Join-Path $pluginRoot "skills\$skill\SKILL.md"
    if (-not (Test-Path $path -PathType Leaf)) { throw "Missing closure skill: $skill" }
}
foreach ($common in $closure.common) {
    $path = Join-Path $pluginRoot "common\$common"
    if (-not (Test-Path $path -PathType Leaf)) { throw "Missing closure common reference: $common" }
}

$allSkillDirs = @(Get-ChildItem (Join-Path $pluginRoot 'skills') -Directory | ForEach-Object Name)
$unexpected = @($allSkillDirs | Where-Object {
    $_ -notin @('fabric-cli', 'fabriciq') -and $_ -notin $closure.skills
})
if ($unexpected.Count -gt 0) { throw "Unexpected Fabric skills in the selected closure: $($unexpected -join ', ')" }

Write-Output "Fabric capability closure OK: agents=$($closure.agents.Count), skills=$($closure.skills.Count), common=$($closure.common.Count)"
