#Requires -Version 5.1
<# Validates a materialized Codex projection against the repository catalog. #>
[CmdletBinding()]
param(
    [string]$RepositoryPath,
    [string]$ProjectionRoot = (Join-Path $env:USERPROFILE '.codex')
)
$ErrorActionPreference = 'Stop'
if ([string]::IsNullOrWhiteSpace($RepositoryPath)) {
    $scriptRoot = if ($PSScriptRoot) { $PSScriptRoot } else { (Get-Location).Path }
    $RepositoryPath = Split-Path $scriptRoot -Parent
}
$marketplace = Get-Content (Join-Path $RepositoryPath '.claude-plugin\marketplace.json') -Raw | ConvertFrom-Json
$catalogPlugins = @($marketplace.plugins | ForEach-Object name)
$manifestPath = Join-Path $ProjectionRoot 'powerbi-agentic-plugins.manifest.json'
if (-not (Test-Path $manifestPath)) { throw "Codex manifest not found: $manifestPath" }
$manifest = Get-Content $manifestPath -Raw | ConvertFrom-Json
if ($manifest.owner -ne 'powerbi-agentic-plugins') { throw 'Projection manifest has an unexpected owner.' }
$plugins = @($manifest.plugins)
if ($plugins.Count -eq 0) { throw 'Projection manifest contains no plugins.' }
if (@(Compare-Object $plugins ($plugins | Where-Object { $catalogPlugins -contains $_ })).Count) { throw 'Projection contains an undeclared plugin.' }
foreach ($plugin in $plugins) {
    $source = Join-Path $RepositoryPath "plugins\$plugin"
    if (-not (Test-Path $source -PathType Container)) { throw "Missing source plugin: $plugin" }
    foreach ($skill in Get-ChildItem (Join-Path $source 'skills') -Directory) {
        $projected = Join-Path $ProjectionRoot "skills\$($skill.Name)"
        if (-not (Test-Path (Join-Path $projected 'SKILL.md'))) { throw "Missing projected skill: $plugin/$($skill.Name)" }
        if ((Get-FileHash (Join-Path $skill.FullName 'SKILL.md')).Hash -ne (Get-FileHash (Join-Path $projected 'SKILL.md')).Hash) { throw "Skill content drift: $plugin/$($skill.Name)" }
    }
    foreach ($agent in Get-ChildItem (Join-Path $source 'agents') -Filter '*.md' -File -ErrorAction SilentlyContinue) {
        $adapterName = "$( ([IO.Path]::GetFileNameWithoutExtension($agent.Name) -replace '\.agent$','') ).toml"
        $sourceAdapter = Join-Path $agent.DirectoryName $adapterName
        $adapter = Join-Path $ProjectionRoot "agents\$adapterName"
        if (-not (Test-Path $sourceAdapter) -or -not (Test-Path $adapter)) { throw "Missing source or projected agent adapter: $plugin/$($agent.Name)" }
        if ((Get-FileHash $sourceAdapter).Hash -ne (Get-FileHash $adapter).Hash) { throw "Agent adapter drift: $plugin/$($agent.Name)" }
        $adapterText = Get-Content $adapter -Raw
        foreach ($field in @('name', 'description', 'developer_instructions')) {
            if ($adapterText -notmatch "(?m)^$field\s*=") { throw "Agent adapter is missing required field '$field': $adapter" }
        }
        $sourceText = Get-Content $agent.FullName -Raw
        $sourceMatch = [regex]::Match($sourceText, '(?s)\A---\r?\n.*?\r?\n---\r?\n(?<body>.*)\z')
        $sourceBody = if ($sourceMatch.Success) { $sourceMatch.Groups['body'].Value } else { $sourceText }
        $sourceBody = (($sourceBody -replace "`r`n", "`n" -replace "`r", "`n") -replace "(?m)[ \t]+$", "").Trim()
        $instructionMatch = [regex]::Match($adapterText, "(?s)developer_instructions\s*=\s*'''\r?\n(?<body>.*?)\r?\n'''\s*\z")
        $adapterBody = if ($instructionMatch.Success) { $instructionMatch.Groups['body'].Value } else { $null }
        $adapterBody = if ($null -ne $adapterBody) { (($adapterBody -replace "`r`n", "`n" -replace "`r", "`n") -replace "(?m)[ \t]+$", "").Trim() } else { $null }
        if (-not $instructionMatch.Success -or $adapterBody -ne $sourceBody) { throw "Agent adapter instruction drift: $plugin/$($agent.Name)" }
    }
}
Write-Output "Projection OK: plugins=$($plugins.Count), skills=$(@($manifest.skills).Count), agents=$(@($manifest.agents).Count)"
