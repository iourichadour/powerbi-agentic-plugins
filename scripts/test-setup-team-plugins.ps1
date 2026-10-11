# Lightweight integration checks for the target dispatcher. Run with PowerShell 5.1+.
[CmdletBinding()]
param([switch]$RunIntegration)
$ErrorActionPreference = 'Stop'
$repo = Split-Path $PSScriptRoot -Parent
$setup = Join-Path $repo 'setup-team-plugins.ps1'
if (-not (Test-Path $setup)) { throw 'setup-team-plugins.ps1 is missing.' }
$source = Get-Content $setup -Raw
foreach ($required in @('-Target', 'Codex', 'Copilot', 'All', '-Force', 'powerbi-agentic-plugins.manifest.json', 'config.toml')) {
    if ($source -notmatch [regex]::Escape($required)) { throw "Installer contract is missing: $required" }
}
if ($source -notmatch '\$Target\s*=\s*"All"') { throw 'Target default is not All.' }
if ($source -notmatch 'Test-CopilotDestinations') { throw 'Copilot collision preflight is missing.' }
if ($source -notmatch 'Test-CodexCapabilities') { throw 'Codex capability checks are missing.' }
if ($source -notmatch 'Remove-OldInstallerBackups') { throw 'Installer backup retention cleanup is missing.' }
if ($source -notmatch 'older than \$RetentionDays days') { throw 'Backup cleanup output does not describe the retention boundary.' }
if ($source -notmatch 'Assert-CodexMcpOwnership') { throw 'Codex MCP ownership preflight is missing.' }
if ($source -notmatch "already exists and is not installer-owned; no Codex projection was modified") { throw 'Codex collision remediation is not explicit.' }
if ($source -notmatch 'if \(\$existing\) \{') { throw 'ADOMD.NET reuse check is missing.' }
if ($source -match 'if \(\$existing -and -not \$Force\)') { throw 'ADOMD.NET provisioning still reinstalls on -Force.' }
if ($source -match 'Convert-AgentMarkdownToCodexToml') { throw 'Installer must not generate Codex agent adapters.' }
if ($source -notmatch 'Test-AgentAdapterParity') { throw 'Checked-in Codex adapter parity validation is missing.' }
& (Join-Path $repo 'scripts\validate-codex-catalog.ps1') -RepositoryPath $repo | Out-Null
foreach ($agent in Get-ChildItem $repo -Recurse -File | Where-Object { $_.Directory.Name -eq 'agents' -and $_.Directory.FullName -match '\\plugins\\[^\\]+\\agents$' -and $_.Extension -eq '.md' }) {
    $adapterName = "$( ([IO.Path]::GetFileNameWithoutExtension($agent.Name) -replace '\.agent$','') ).toml"
    $adapter = Join-Path $agent.DirectoryName $adapterName
    if (-not (Test-Path $adapter)) { throw "Checked-in Codex adapter is missing: $adapter" }
}
foreach ($adapter in Get-ChildItem $repo -Recurse -File | Where-Object { $_.Directory.Name -eq 'agents' -and $_.Directory.FullName -match '\\plugins\\[^\\]+\\agents$' -and $_.Extension -eq '.toml' }) {
    $candidateNames = @("$([IO.Path]::GetFileNameWithoutExtension($adapter.Name)).agent.md", "$([IO.Path]::GetFileNameWithoutExtension($adapter.Name)).md")
    if (-not (@(Get-ChildItem $adapter.DirectoryName -File | Where-Object { $candidateNames -contains $_.Name }).Count)) {
        throw "Orphaned Codex adapter: $($adapter.FullName)"
    }
}
Write-Output 'Static setup contract OK.'
if (-not $RunIntegration) { return }
function Invoke-IsolatedSetup {
    param(
        [string]$Profile,
        [hashtable]$Arguments
    )
    $oldProfile = $env:USERPROFILE
    try {
        $env:USERPROFILE = $Profile
        & $setup @Arguments
        return $LASTEXITCODE
    } catch {
        # Parameter-binding failures (for example ValidateSet rejection) are
        # terminating errors in an in-process invocation; normalize them to
        # the same nonzero result a child process would return.
        return 1
    } finally {
        $env:USERPROFILE = $oldProfile
    }
}

function New-TestProfile {
    $profile = Join-Path ([IO.Path]::GetTempPath()) ('pbi-setup-test-' + [guid]::NewGuid().ToString('N'))
    New-Item -ItemType Directory -Path $profile -Force | Out-Null
    return $profile
}

function New-DevopsFixture {
    param([string]$Profile)
    $fixture = Join-Path $Profile 'fixture'
    New-Item -ItemType Directory -Path (Join-Path $fixture '.git'),(Join-Path $fixture '.claude-plugin'),(Join-Path $fixture 'plugins') -Force | Out-Null
    Copy-Item (Join-Path $repo '.claude-plugin\marketplace.json') (Join-Path $fixture '.claude-plugin\marketplace.json')
    Copy-Item (Join-Path $repo 'plugins\devops') (Join-Path $fixture 'plugins') -Recurse
    return $fixture
}

$fakeMcpLauncher = {
    param($Definition, $Request)
    [PSCustomObject]@{
        id = $Request.id
        result = [PSCustomObject]@{ protocolVersion = '2025-06-18' }
    }
}

$failedLaunchMcpLauncher = {
    param($Definition, $Request)
    throw 'fake launch failure'
}

$failedInitializeMcpLauncher = {
    param($Definition, $Request)
    [PSCustomObject]@{
        id = $Request.id
        error = [PSCustomObject]@{ message = 'fake initialize failure' }
    }
}

$fakeMcpProvisioner = {
    param($Package)
    return $true
}

$powerBiMcpSource = Get-Content (Join-Path $repo 'plugins\powerbi\.mcp.json') -Raw | ConvertFrom-Json
$powerBiMcpDefinition = $powerBiMcpSource.mcpServers.'powerbi-modeling-mcp'
if (@($powerBiMcpDefinition.args) -contains '--start') { throw 'Power BI Modeling MCP source still contains obsolete --start.' }
if (@($powerBiMcpDefinition.args) -notcontains '@microsoft/powerbi-modeling-mcp@1.0.0') { throw 'Power BI Modeling MCP source is not pinned to 1.0.0.' }
if ($powerBiMcpSource.mcpServers.PSObject.Properties.Name -notcontains 'powerbi-modeling-mcp') { throw 'Canonical Power BI Modeling MCP name is missing.' }
Write-Output 'Power BI Modeling MCP source contract OK.'

$profiles = @()
try {
    # Codex-only and selected-plugin projection.
    $codexProfile = New-TestProfile; $profiles += $codexProfile
    $code = Invoke-IsolatedSetup -Profile $codexProfile -Arguments @{ RepositoryPath=$repo; Target='Codex'; PluginName='fabric'; McpLauncher=$fakeMcpLauncher }
    if ($code -ne 0) { throw 'Codex isolated install failed.' }
    & (Join-Path $repo 'scripts\validate-codex-projection.ps1') -RepositoryPath $repo -ProjectionRoot (Join-Path $codexProfile '.codex')
    if (Test-Path (Join-Path $codexProfile '.copilot')) { throw 'Codex-only setup touched Copilot state.' }
    Write-Output 'Codex selected-plugin projection OK.'

    # Copilot-only projection remains independent of Codex.
    $copilotProfile = New-TestProfile; $profiles += $copilotProfile
    $code = Invoke-IsolatedSetup -Profile $copilotProfile -Arguments @{ RepositoryPath=$repo; Target='Copilot'; PluginName='fabric'; SkipCopilotCLI=$true; SkipVSCode=$true; McpLauncher=$fakeMcpLauncher }
    if ($code -ne 0) { throw 'Copilot isolated install failed.' }
    if (-not (Test-Path (Join-Path $copilotProfile '.copilot\extensions\fabric\skills\fabric-cli\SKILL.md'))) { throw 'Copilot fabric projection is missing.' }
    if (Test-Path (Join-Path $copilotProfile '.codex')) { throw 'Copilot-only setup touched Codex state.' }
    Write-Output 'Copilot selected-plugin projection OK.'

    # Missing Node.js is optional for the fabric Copilot projection. Remove its
    # PATH segment for this disposable run and verify setup remains successful.
    $optionalProfile = New-TestProfile; $profiles += $optionalProfile
    $oldPath = $env:PATH
    try {
        $nodeCommand = Get-Command node -ErrorAction SilentlyContinue
        if ($nodeCommand) {
            $nodeDirectory = Split-Path $nodeCommand.Source -Parent
            $env:PATH = (($env:PATH -split ';' | Where-Object { $_ -and $_ -ne $nodeDirectory }) -join ';')
        }
        $code = Invoke-IsolatedSetup -Profile $optionalProfile -Arguments @{ RepositoryPath=$repo; Target='Copilot'; PluginName='fabric'; SkipCopilotCLI=$true; SkipVSCode=$true; McpLauncher=$fakeMcpLauncher }
    } finally {
        $env:PATH = $oldPath
    }
    if ($code -ne 0) { throw 'Copilot setup failed when optional Node.js was unavailable.' }
    Write-Output 'Missing optional dependency behavior OK.'

    # Omitted Target defaults to All; explicit All with -Force exercises the update path.
    $allProfile = New-TestProfile; $profiles += $allProfile
    $code = Invoke-IsolatedSetup -Profile $allProfile -Arguments @{ RepositoryPath=$repo; PluginName='fabric'; SkipCopilotCLI=$true; SkipVSCode=$true; McpLauncher=$fakeMcpLauncher }
    if ($code -ne 0) { throw 'Default All install failed.' }
    & (Join-Path $repo 'scripts\validate-codex-projection.ps1') -RepositoryPath $repo -ProjectionRoot (Join-Path $allProfile '.codex')
    $code = Invoke-IsolatedSetup -Profile $allProfile -Arguments @{ RepositoryPath=$repo; Target='All'; PluginName='fabric'; Force=$true; SkipCopilotCLI=$true; SkipVSCode=$true; McpLauncher=$fakeMcpLauncher }
    if ($code -ne 0) { throw 'Explicit All force update failed.' }
    if (-not (Get-ChildItem (Join-Path $allProfile '.codex\backups') -Directory -ErrorAction SilentlyContinue)) { throw 'Force update did not create a Codex backup.' }
    Write-Output 'Default and explicit All projections OK.'

    # Backup retention is strict: old artifacts are removed, while an artifact
    # newer than seven days remains available after the update.
    $backupRoot = Join-Path $allProfile '.codex\backups'
    $oldBackup = Join-Path $backupRoot 'old-fixture'
    $currentBackup = Join-Path $backupRoot 'current-fixture'
    New-Item -ItemType Directory -Path $oldBackup,$currentBackup -Force | Out-Null
    $oldTime = (Get-Date).AddDays(-8)
    $currentTime = (Get-Date).AddDays(-1)
    (Get-Item $oldBackup).LastWriteTime = $oldTime
    (Get-Item $currentBackup).LastWriteTime = $currentTime
    $code = Invoke-IsolatedSetup -Profile $allProfile -Arguments @{ RepositoryPath=$repo; Target='Codex'; PluginName='fabric'; Force=$true; McpLauncher=$fakeMcpLauncher }
    if ($code -ne 0) { throw 'Retention fixture update failed.' }
    if (Test-Path $oldBackup) { throw 'Backup older than seven days was not removed.' }
    if (-not (Test-Path $currentBackup)) { throw 'Current backup was removed by retention cleanup.' }
    Write-Output 'Seven-day backup retention behavior OK.'

    # Non-force rerun must fail without deleting the existing projection.
    $code = Invoke-IsolatedSetup -Profile $codexProfile -Arguments @{ RepositoryPath=$repo; Target='Codex'; PluginName='fabric' }
    if ($code -eq 0) { throw 'Non-force Codex rerun unexpectedly succeeded.' }
    if (-not (Test-Path (Join-Path $codexProfile '.codex\powerbi-agentic-plugins.manifest.json'))) { throw 'Non-force rerun removed the Codex manifest.' }
    Write-Output 'Non-force collision behavior OK.'

    # Invalid selectors and an explicit missing repository must fail before either target writes.
    $invalidProfile = New-TestProfile; $profiles += $invalidProfile
    $code = Invoke-IsolatedSetup -Profile $invalidProfile -Arguments @{ RepositoryPath=$repo; Target='InvalidTarget'; SkipCopilotCLI=$true; SkipVSCode=$true }
    if ($code -eq 0 -or (Test-Path (Join-Path $invalidProfile '.codex')) -or (Test-Path (Join-Path $invalidProfile '.copilot'))) { throw 'Invalid target was not rejected before writes.' }
    $code = Invoke-IsolatedSetup -Profile $invalidProfile -Arguments @{ RepositoryPath=$repo; PluginName='invalid-plugin'; SkipCopilotCLI=$true; SkipVSCode=$true }
    if ($code -eq 0 -or (Test-Path (Join-Path $invalidProfile '.codex')) -or (Test-Path (Join-Path $invalidProfile '.copilot'))) { throw 'Invalid plugin was not rejected before writes.' }
    $code = Invoke-IsolatedSetup -Profile $invalidProfile -Arguments @{ RepositoryPath=(Join-Path $invalidProfile 'missing-repository'); Target='Codex' }
    if ($code -eq 0 -or (Test-Path (Join-Path $invalidProfile '.codex'))) { throw 'Missing repository was not rejected before writes.' }
    Write-Output 'Invalid selector and missing repository behavior OK.'

    # A disposable source checkout with a missing or invalid adapter must fail
    # source validation before Codex projection begins.
    $missingAdapterProfile = New-TestProfile; $profiles += $missingAdapterProfile
    $missingAdapterRepo = New-DevopsFixture -Profile $missingAdapterProfile
    Remove-Item (Join-Path $missingAdapterRepo 'plugins\devops\agents\devops.toml') -Force
    $code = Invoke-IsolatedSetup -Profile $missingAdapterProfile -Arguments @{ RepositoryPath=$missingAdapterRepo; Target='Codex'; PluginName='devops' }
    if ($code -eq 0 -or (Test-Path (Join-Path $missingAdapterProfile '.codex'))) { throw 'Missing adapter was not rejected before projection.' }

    $staleAdapterProfile = New-TestProfile; $profiles += $staleAdapterProfile
    $staleAdapterRepo = New-DevopsFixture -Profile $staleAdapterProfile
    $staleAdapterPath = Join-Path $staleAdapterRepo 'plugins\devops\agents\devops.toml'
    Add-Content -LiteralPath $staleAdapterPath -Value "`n# stale adapter fixture"
    $code = Invoke-IsolatedSetup -Profile $staleAdapterProfile -Arguments @{ RepositoryPath=$staleAdapterRepo; Target='Codex'; PluginName='devops' }
    if ($code -eq 0 -or (Test-Path (Join-Path $staleAdapterProfile '.codex'))) { throw 'Stale adapter was not rejected before projection.' }
    Write-Output 'Missing and stale adapter behavior OK.'

    # Inject a user-owned Codex MCP conflict. All must leave Copilot usable while
    # reporting Codex failure and preserving the conflicting configuration.
    $failureProfile = New-TestProfile; $profiles += $failureProfile
    $codexRoot = Join-Path $failureProfile '.codex'
    New-Item -ItemType Directory -Path $codexRoot -Force | Out-Null
    $conflictConfig = "[mcp_servers.fabric-mcp-server]`ncommand = 'user-owned'`nargs = []`n"
    Set-Content -LiteralPath (Join-Path $codexRoot 'config.toml') -Value $conflictConfig -Encoding UTF8
    $code = Invoke-IsolatedSetup -Profile $failureProfile -Arguments @{ RepositoryPath=$repo; Target='All'; PluginName='fabric'; SkipCopilotCLI=$true; SkipVSCode=$true; McpLauncher=$fakeMcpLauncher }
    if ($code -eq 0) { throw 'Injected Codex MCP conflict did not fail the All run.' }
    if (-not (Test-Path (Join-Path $failureProfile '.copilot\extensions\fabric\skills\fabric-cli\SKILL.md'))) { throw 'Copilot did not remain usable after Codex failure.' }
    if ((Get-Content (Join-Path $codexRoot 'config.toml') -Raw) -notmatch 'user-owned') { throw 'Codex conflict configuration was overwritten.' }
    Write-Output 'Injected one-target failure behavior OK.'

    # The canonical Power BI Modeling MCP collision is checked before Codex
    # projection, so a user-owned entry and the existing Codex assets remain
    # untouched when setup refuses the collision.
    $canonicalConflictProfile = New-TestProfile; $profiles += $canonicalConflictProfile
    $canonicalRoot = Join-Path $canonicalConflictProfile '.codex'
    New-Item -ItemType Directory -Path $canonicalRoot -Force | Out-Null
    $canonicalConfig = "[mcp_servers.powerbi-modeling-mcp]`ncommand = 'user-owned'`nargs = []`n"
    Set-Content -LiteralPath (Join-Path $canonicalRoot 'config.toml') -Value $canonicalConfig -Encoding UTF8
    $code = Invoke-IsolatedSetup -Profile $canonicalConflictProfile -Arguments @{ RepositoryPath=$repo; Target='Codex'; PluginName='powerbi'; McpLauncher=$fakeMcpLauncher; McpProvisioner=$fakeMcpProvisioner }
    if ($code -eq 0) { throw 'Canonical user-owned Codex MCP collision did not fail.' }
    if (-not (Test-Path (Join-Path $canonicalRoot 'config.toml'))) { throw 'Canonical collision removed the user config.' }
    if ((Get-Content (Join-Path $canonicalRoot 'config.toml') -Raw) -notmatch 'user-owned') { throw 'Canonical collision configuration was overwritten.' }
    if (Test-Path (Join-Path $canonicalRoot 'powerbi-agentic-plugins.manifest.json')) { throw 'Canonical collision created a Codex projection before failing.' }
    Write-Output 'Canonical Codex MCP ownership behavior OK.'

    # A pre-marker installer registration with the exact pinned legacy npx
    # signature is migrated by -Force instead of being treated as a collision.
    $legacyProfile = New-TestProfile; $profiles += $legacyProfile
    $legacyRoot = Join-Path $legacyProfile '.codex'
    New-Item -ItemType Directory -Path $legacyRoot -Force | Out-Null
    @(
        '[mcp_servers.powerbi-modeling-mcp]'
        'command = "npx"'
        'args = ["-y", "@microsoft/powerbi-modeling-mcp-win32-x64@1.0.0", "--start"]'
    ) | Set-Content (Join-Path $legacyRoot 'config.toml') -Encoding UTF8
    $code = Invoke-IsolatedSetup -Profile $legacyProfile -Arguments @{ RepositoryPath=$repo; Target='Codex'; PluginName='powerbi'; Force=$true; McpLauncher=$fakeMcpLauncher; McpProvisioner=$fakeMcpProvisioner }
    if ($code -ne 0) { throw 'Legacy installer-owned Codex MCP entry was not migrated.' }
    $legacyResult = Get-Content (Join-Path $legacyRoot 'config.toml') -Raw
    if ($legacyResult -notmatch '# BEGIN powerbi-agentic-plugins: powerbi-modeling-mcp' -or $legacyResult -notmatch '(?i)npx-cli\.js') { throw 'Legacy Codex MCP entry was not replaced with the owned direct-Node projection.' }
    Write-Output 'Legacy Codex MCP migration behavior OK.'

    # A user-owned FabricIQ entry is preserved as a warning while the rest of
    # the Codex projection and MCP registrations continue.
    $fabricIqProfile = New-TestProfile; $profiles += $fabricIqProfile
    $fabricIqRoot = Join-Path $fabricIqProfile '.codex'
    New-Item -ItemType Directory -Path $fabricIqRoot -Force | Out-Null
    $fabricIqConfig = "[mcp_servers.FabricIQ]`nurl = 'https://user-owned.invalid/fabriciq'`n"
    Set-Content -LiteralPath (Join-Path $fabricIqRoot 'config.toml') -Value $fabricIqConfig -Encoding UTF8
    $code = Invoke-IsolatedSetup -Profile $fabricIqProfile -Arguments @{ RepositoryPath=$repo; Target='Codex'; PluginName='fabric'; Force=$true; McpLauncher=$fakeMcpLauncher }
    if ($code -ne 0) { throw 'User-owned FabricIQ conflict incorrectly blocked the Codex install.' }
    $fabricIqResultConfig = Get-Content (Join-Path $fabricIqRoot 'config.toml') -Raw
    if ($fabricIqResultConfig -notmatch 'user-owned.invalid') { throw 'User-owned FabricIQ configuration was overwritten.' }
    if ($fabricIqResultConfig -notmatch '# BEGIN powerbi-agentic-plugins: fabric-mcp-server') { throw 'Non-conflicting Codex MCP server was not registered.' }
    Write-Output 'User-owned FabricIQ warning-and-continue behavior OK.'

    # A process launch failure and an initialize failure must both fail the
    # selected target instead of producing a false-ready result.
    foreach ($failureCase in @(
        @{ Name = 'launch'; Launcher = $failedLaunchMcpLauncher },
        @{ Name = 'initialize'; Launcher = $failedInitializeMcpLauncher }
    )) {
        $readinessProfile = New-TestProfile; $profiles += $readinessProfile
        $code = Invoke-IsolatedSetup -Profile $readinessProfile -Arguments @{ RepositoryPath=$repo; Target='Codex'; PluginName='fabric'; McpLauncher=$failureCase.Launcher }
        if ($code -eq 0) { throw "Fake $($failureCase.Name) failure was reported as ready." }
        Write-Output "MCP $($failureCase.Name) failure reporting OK."
    }

    # Copilot profile mirrors use different top-level schema keys. Equivalent
    # stale definitions must produce one logical conflict with both locations.
    $profileConflict = New-TestProfile; $profiles += $profileConflict
    $copilotProfileRoot = Join-Path $profileConflict '.copilot'
    New-Item -ItemType Directory -Path $copilotProfileRoot -Force | Out-Null
    $staleProfileJson = @{
        servers = @{ 'powerbi-modeling-mcp' = @{ command = 'stale-command'; args = @('stale') } }
    } | ConvertTo-Json -Depth 10
    $staleConfigJson = @{
        mcpServers = @{ 'powerbi-modeling' = @{ command = 'stale-command'; args = @('stale') } }
    } | ConvertTo-Json -Depth 10
    Set-Content -LiteralPath (Join-Path $copilotProfileRoot 'mcp.json') -Value $staleProfileJson -Encoding UTF8
    Set-Content -LiteralPath (Join-Path $copilotProfileRoot 'mcp-config.json') -Value $staleConfigJson -Encoding UTF8
    $code = Invoke-IsolatedSetup -Profile $profileConflict -Arguments @{ RepositoryPath=$repo; Target='Copilot'; PluginName='powerbi'; SkipCopilotCLI=$true; SkipVSCode=$true; McpLauncher=$fakeMcpLauncher; McpProvisioner=$fakeMcpProvisioner }
    if ($code -eq 0) { throw 'Mirrored Copilot profile conflict was reported as ready.' }
    if ((Get-Content (Join-Path $copilotProfileRoot 'mcp.json') -Raw) -notmatch 'stale-command') { throw 'mcp.json user-owned entry was overwritten.' }
    if ((Get-Content (Join-Path $copilotProfileRoot 'mcp-config.json') -Raw) -notmatch 'stale-command') { throw 'mcp-config.json user-owned entry was overwritten.' }
    Write-Output 'Mirrored Copilot profile conflict behavior OK.'

    # A hosted canonical registration is distinct from the local Windows stdio
    # registration, so it is preserved as a warning rather than overwritten.
    $hostedProfile = New-TestProfile; $profiles += $hostedProfile
    $hostedCopilotRoot = Join-Path $hostedProfile '.copilot'
    New-Item -ItemType Directory -Path $hostedCopilotRoot -Force | Out-Null
    $hostedJson = @{ servers = @{ 'powerbi-modeling-mcp' = @{ type = 'http'; url = 'https://example.invalid/mcp' } } } | ConvertTo-Json -Depth 10
    Set-Content -LiteralPath (Join-Path $hostedCopilotRoot 'mcp.json') -Value $hostedJson -Encoding UTF8
    $code = Invoke-IsolatedSetup -Profile $hostedProfile -Arguments @{ RepositoryPath=$repo; Target='Copilot'; PluginName='powerbi'; SkipCopilotCLI=$true; SkipVSCode=$true; McpLauncher=$fakeMcpLauncher; McpProvisioner=$fakeMcpProvisioner }
    if ($code -ne 0) { throw 'Hosted HTTP/local stdio mismatch incorrectly blocked Copilot setup.' }
    if ((Get-Content (Join-Path $hostedCopilotRoot 'mcp.json') -Raw) -notmatch 'example.invalid') { throw 'Hosted HTTP profile entry was overwritten.' }
    $projectedCopilotMcp = Get-Content (Join-Path $hostedProfile '.copilot\installed-plugins\powerbi-agentic-plugins\powerbi\.mcp.json') -Raw | ConvertFrom-Json
    if ([IO.Path]::GetFileName($projectedCopilotMcp.mcpServers.'powerbi-modeling-mcp'.command) -ne 'node.exe') { throw 'Copilot Windows projection does not use node.exe.' }
    if (-not (@($projectedCopilotMcp.mcpServers.'powerbi-modeling-mcp'.args) | Where-Object { [IO.Path]::GetFileName($_) -eq 'npx-cli.js' })) { throw 'Copilot Windows projection does not use npm npx-cli.js.' }
    if (@($projectedCopilotMcp.mcpServers.'powerbi-modeling-mcp'.args) -notcontains '@microsoft/powerbi-modeling-mcp-win32-x64@1.0.0') { throw 'Copilot Windows projection does not use the pinned x64 package.' }
    if (@($projectedCopilotMcp.mcpServers.'powerbi-modeling-mcp'.args) -notcontains '--start') { throw 'Copilot Windows projection is missing the platform package start mode.' }
    Write-Output 'Hosted/local transport mismatch and Copilot Windows projection OK.'

    $projectedCodex = New-TestProfile; $profiles += $projectedCodex
    $code = Invoke-IsolatedSetup -Profile $projectedCodex -Arguments @{ RepositoryPath=$repo; Target='Codex'; PluginName='powerbi'; McpLauncher=$fakeMcpLauncher; McpProvisioner=$fakeMcpProvisioner }
    if ($code -ne 0) { throw 'Power BI Codex projection failed.' }
    $codexMcp = Get-Content (Join-Path $projectedCodex '.codex\config.toml') -Raw
    if ($codexMcp -notmatch '(?i)command = ".*node\.exe"' -or $codexMcp -notmatch '(?i)npx-cli\.js' -or $codexMcp -notmatch '@microsoft/powerbi-modeling-mcp-win32-x64@1.0.0' -or $codexMcp -notmatch '--start') { throw 'Codex Windows projection does not contain the direct Node pinned x64 command.' }
    if ($codexMcp -match '(?i)command = ".*Program Files' -and $codexMcp -notmatch '(?i)command = ".*\\\\Program Files\\\\nodejs\\\\node\.exe"') { throw 'Codex Windows projection did not TOML-escape backslashes in the command path.' }
    Write-Output 'Codex Windows projection OK.'

    # A manually repaired direct Node entry remains equivalent to the generated
        # Windows projection.
    $manualCodex = New-TestProfile; $profiles += $manualCodex
    $manualCodexRoot = Join-Path $manualCodex '.codex'
    New-Item -ItemType Directory -Path $manualCodexRoot -Force | Out-Null
    $nodeCommand = (Get-Command node.exe -ErrorAction Stop).Source
    $npxCli = Join-Path (Split-Path -Parent $nodeCommand) 'node_modules\npm\bin\npx-cli.js'
    @(
        '[mcp_servers.powerbi-modeling-mcp]'
        "command = `"$nodeCommand`""
        "args = [`"$npxCli`", `"-y`", `"@microsoft/powerbi-modeling-mcp-win32-x64@1.0.0`", `"--start`"]"
    ) | Set-Content (Join-Path $manualCodexRoot 'config.toml') -Encoding UTF8
    $code = Invoke-IsolatedSetup -Profile $manualCodex -Arguments @{ RepositoryPath=$repo; Target='Codex'; PluginName='powerbi'; McpLauncher=$fakeMcpLauncher; McpProvisioner=$fakeMcpProvisioner }
    if ($code -ne 0) { throw 'Codex rejected an equivalent manually repaired direct Node MCP entry.' }
    Write-Output 'Codex direct Node equivalence behavior OK.'
} finally {
    foreach ($profile in $profiles) {
        if (Test-Path $profile) { Remove-Item -LiteralPath $profile -Recurse -Force -ErrorAction SilentlyContinue }
    }
}

# Make the successful integration result explicit for CI callers. Terminating
# assertion failures above still produce a nonzero process result.
exit 0
