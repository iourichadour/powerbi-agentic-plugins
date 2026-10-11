#Requires -Version 5.1
<#
.SYNOPSIS
    Static source-catalog parity check for the Codex projection.
#>
[CmdletBinding()]
param([string]$RepositoryPath = (Split-Path $PSScriptRoot -Parent))

$ErrorActionPreference = 'Stop'
$expected = @('powerbi', 'fabric', 'devops', 'skill-creator', 'spec-lifecycle')
$marketplace = Get-Content (Join-Path $RepositoryPath '.claude-plugin\marketplace.json') -Raw | ConvertFrom-Json
$declared = @($marketplace.plugins | ForEach-Object { $_.name })
if (@(Compare-Object $expected $declared).Count) { throw 'Marketplace and supported plugin catalog differ.' }

$skillCount = 0; $agentCount = 0; $adapterCount = 0; $mcpCount = 0
foreach ($plugin in $expected) {
    $root = Join-Path $RepositoryPath "plugins\$plugin"
    if (-not (Test-Path $root -PathType Container)) { throw "Missing plugin root: $plugin" }
    foreach ($skill in Get-ChildItem (Join-Path $root 'skills') -Directory) {
        if (-not (Test-Path (Join-Path $skill.FullName 'SKILL.md'))) { throw "Missing SKILL.md: $($skill.FullName)" }
        $skillCount++
    }
    $agentFiles = @(Get-ChildItem (Join-Path $root 'agents') -Filter '*.md' -File -ErrorAction SilentlyContinue)
    $expectedAdapterNames = @($agentFiles | ForEach-Object { "$( ([IO.Path]::GetFileNameWithoutExtension($_.Name) -replace '\.agent$','') ).toml" })
    foreach ($adapter in Get-ChildItem (Join-Path $root 'agents') -Filter '*.toml' -File -ErrorAction SilentlyContinue) {
        if ($expectedAdapterNames -notcontains $adapter.Name) { throw "Orphaned Codex adapter: $($adapter.FullName)" }
    }
    foreach ($agent in $agentFiles) {
        $adapterName = "$( ([IO.Path]::GetFileNameWithoutExtension($agent.Name) -replace '\.agent$','') ).toml"
        $adapterPath = Join-Path $agent.DirectoryName $adapterName
        if (-not (Test-Path $adapterPath -PathType Leaf)) { throw "Missing Codex adapter: $plugin/agents/$adapterName" }
        $adapterText = Get-Content $adapterPath -Raw
        foreach ($field in @('name', 'description', 'developer_instructions')) {
            if ($adapterText -notmatch "(?m)^$field\s*=") { throw "Adapter missing required field '$field': $adapterPath" }
        }
        $expectedName = [IO.Path]::GetFileNameWithoutExtension($agent.Name) -replace '\.agent$',''
        $nameMatch = [regex]::Match($adapterText, '(?m)^name\s*=\s*"(?<value>[^"]+)"')
        if (-not $nameMatch.Success -or $nameMatch.Groups['value'].Value -ne $expectedName) { throw "Adapter name mismatch: $adapterPath" }
        $sourceText = Get-Content $agent.FullName -Raw
        $sourceMatch = [regex]::Match($sourceText, '(?s)\A---\r?\n.*?\r?\n---\r?\n(?<body>.*)\z')
        $sourceBody = if ($sourceMatch.Success) { $sourceMatch.Groups['body'].Value } else { $sourceText }
        $sourceBody = (($sourceBody -replace "`r`n", "`n" -replace "`r", "`n") -replace "(?m)[ \t]+$", "").Trim()
        $instructionMatch = [regex]::Match($adapterText, "(?s)developer_instructions\s*=\s*'''\r?\n(?<body>.*?)\r?\n'''\s*\z")
        $adapterBody = if ($instructionMatch.Success) { $instructionMatch.Groups['body'].Value } else { $null }
        $adapterBody = if ($null -ne $adapterBody) { (($adapterBody -replace "`r`n", "`n" -replace "`r", "`n") -replace "(?m)[ \t]+$", "").Trim() } else { $null }
        if (-not $instructionMatch.Success -or $adapterBody -ne $sourceBody) { throw "Adapter instruction drift: $adapterPath" }
        $agentCount++; $adapterCount++
    }
    foreach ($mcp in Get-ChildItem $root -Filter '.mcp.json' -File -ErrorAction SilentlyContinue) {
        Get-Content $mcp.FullName -Raw | ConvertFrom-Json | Out-Null
        $mcpCount++
    }
}
Write-Output "Catalog OK: plugins=$($expected.Count), skills=$skillCount, agents=$agentCount, adapters=$adapterCount, mcp=$mcpCount"
