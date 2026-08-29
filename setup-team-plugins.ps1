#Requires -Version 5.1
<#
.SYNOPSIS
    Setup script for installing Power BI Agentic Plugins for the team
    
.DESCRIPTION
    This script installs all plugins, or a single selected plugin, from a local copy of the
    powerbi-agentic-plugins repository to $USERPROFILE\.copilot\extensions for GitHub Copilot CLI
    and VS Code.
    
    It validates prerequisites, backs up and removes any existing copies of the
    targeted plugins already installed under $USERPROFILE\.copilot (both the
    installed-plugins cache and the extensions discovery folder), copies the
    current plugins, registers with GitHub Copilot CLI, integrates with VS Code,
    configures MCP servers, and installs the Power BI Desktop Bridge CLI
    (@microsoft/powerbi-desktop-bridge-cli) when the powerbi plugin is targeted.
    
    Backups are timestamped and stored under
    $USERPROFILE\.copilot\backups\<yyyyMMdd-HHmmss>, so previous plugin versions
    can be restored manually if needed.
    
.PARAMETER RepositoryPath
    Path to the local powerbi-agentic-plugins repository.
    If not provided, will search common locations or prompt to clone.

.PARAMETER PluginName
    Install only the specified plugin instead of all plugins.
    Valid values: powerbi, fabric, devops, skill-creator
     
.PARAMETER SkipCopilotCLI
    Skip GitHub Copilot CLI registration and verification.
    Use this for VS Code-only installs or when Copilot CLI is not installed.
    
.PARAMETER SkipVSCode
    Skip integration with VS Code (if not installed or not needed)
    
.PARAMETER Force
    Overwrite existing plugins if already installed
    
.PARAMETER Verbose
    Enable verbose logging for troubleshooting
    
.EXAMPLE
    .\setup-team-plugins.ps1
    
.EXAMPLE
    .\setup-team-plugins.ps1 -RepositoryPath "C:\repos\powerbi-agentic-plugins" -Force

.EXAMPLE
    .\setup-team-plugins.ps1 -SkipCopilotCLI

.EXAMPLE
    .\setup-team-plugins.ps1 -PluginName powerbi
    
.NOTES
    Requires PowerShell 5.1 or later (Windows PowerShell 5.1 or PowerShell 7+)
    Requires Git installed and in PATH
    Requires GitHub Copilot CLI or VS Code with GitHub Copilot Chat extension
#>

param(
    [string]$RepositoryPath,
    [ValidateSet("powerbi", "fabric", "devops", "skill-creator")]
    [string]$PluginName,
    [switch]$SkipCopilotCLI,
    [switch]$SkipVSCode,
    [switch]$Force,
    [switch]$Verbose
)

# Enable strict error handling
$ErrorActionPreference = "Stop"
$VerbosePreference = if ($Verbose) { "Continue" } else { "SilentlyContinue" }

# Run with a process-scoped bypass so the setup works without admin rights.
Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process -Force

# Colors for output
$Script:ColorSuccess = "Green"
$Script:ColorError = "Red"
$Script:ColorWarning = "Yellow"
$Script:ColorInfo = "Cyan"

#region Helper Functions

function Write-Header {
    param([string]$Message)
    Write-Host "`n" + ("=" * 80) -ForegroundColor $ColorInfo
    Write-Host $Message -ForegroundColor $ColorInfo
    Write-Host ("=" * 80) -ForegroundColor $ColorInfo
}

function Write-Success {
    param([string]$Message)
    Write-Host "✓ $Message" -ForegroundColor $ColorSuccess
}

function Write-Error-Custom {
    param([string]$Message)
    Write-Host "✗ $Message" -ForegroundColor $ColorError
}

function Write-Warning-Custom {
    param([string]$Message)
    Write-Host "⚠ $Message" -ForegroundColor $ColorWarning
}

function Write-Info {
    param([string]$Message)
    Write-Host "ℹ $Message" -ForegroundColor $ColorInfo
}

function Get-TargetPlugins {
    param([string]$PluginName)

    if ($PluginName) {
        return @($PluginName)
    }

    return @("powerbi", "fabric", "devops", "skill-creator")
}

function Get-MarketplaceName {
    param([string]$RepositoryPath)
    $marketplacePath = Join-Path $RepositoryPath ".claude-plugin\marketplace.json"
    if (Test-Path $marketplacePath) {
        $marketplace = Get-Content $marketplacePath -Raw | ConvertFrom-Json
        return $marketplace.name
    }
    return "powerbi-agentic-plugins"
}

function Get-PluginVersion {
    param([string]$RepositoryPath, [string]$PluginName)
    $marketplacePath = Join-Path $RepositoryPath ".claude-plugin\marketplace.json"
    if (Test-Path $marketplacePath) {
        $marketplace = Get-Content $marketplacePath -Raw | ConvertFrom-Json
        $plugin = $marketplace.plugins | Where-Object { $_.name -eq $PluginName }
        if ($plugin) { return $plugin.version }
    }
    return "0.1.0"
}

function Get-InstallRoot {
    param([string]$MarketplaceName)
    return (Join-Path $env:USERPROFILE ".copilot\installed-plugins\$MarketplaceName")
}

function Get-DiscoveryRoot {
    return (Join-Path $env:USERPROFILE ".copilot\extensions")
}

function ConvertFrom-JsonWithComments {
    # Some .copilot config files ship with leading // comment lines, which
    # ConvertFrom-Json cannot parse ("Invalid JSON primitive").
    param([string]$RawContent)

    $stripped = ($RawContent -split "`r?`n" | Where-Object { $_.TrimStart() -notmatch '^//' }) -join "`n"
    return $stripped | ConvertFrom-Json
}

function Backup-ExistingPlugins {
    param(
        [string]$InstallRoot,
        [string]$DiscoveryRoot,
        [string[]]$Plugins
    )

    Write-Header "Backing Up Existing Plugins"

    $backupRoot = Join-Path $env:USERPROFILE ".copilot\backups\$(Get-Date -Format 'yyyyMMdd-HHmmss')"
    $anyBackedUp = $false

    # (label, root) pairs so both the install cache and the discovery/extensions
    # copy of each plugin get backed up and removed before the fresh install.
    $locations = @(
        @{ Label = "installed-plugins"; Root = $InstallRoot },
        @{ Label = "extensions"; Root = $DiscoveryRoot }
    )

    foreach ($location in $locations) {
        foreach ($pluginName in $Plugins) {
            $existingPath = Join-Path $location.Root $pluginName
            if (-not (Test-Path $existingPath)) {
                continue
            }

            $backupDest = Join-Path (Join-Path $backupRoot $location.Label) $pluginName
            $backupParent = Split-Path $backupDest -Parent
            if (-not (Test-Path $backupParent)) {
                New-Item -ItemType Directory -Path $backupParent -Force | Out-Null
            }

            Write-Info "Backing up existing $pluginName plugin ($($location.Label)) to: $backupDest"
            Copy-Item -Path $existingPath -Destination $backupDest -Recurse -Force
            $anyBackedUp = $true

            Write-Info "Removing existing $pluginName plugin ($($location.Label))..."
            Remove-Item -Path $existingPath -Recurse -Force
        }
    }

    if ($anyBackedUp) {
        Write-Success "Existing plugins backed up to: $backupRoot"
    } else {
        Write-Info "No existing plugins found to back up."
    }

    return $backupRoot
}

function Test-Prerequisites {
    Write-Header "Validating Prerequisites"
    
    $prereqsMet = $true
    
    # Check PowerShell version
    Write-Info "PowerShell version: $($PSVersionTable.PSVersion)"
    if ($PSVersionTable.PSVersion -lt [Version]"5.1") {
        Write-Error-Custom "PowerShell 5.1 or later required. Current: $($PSVersionTable.PSVersion)"
        $prereqsMet = $false
    } else {
        Write-Success "PowerShell 5.1+ ✓"
    }
    
    # Check Git
    try {
        $gitVersion = git --version 2>&1
        Write-Info "Git: $gitVersion"
        Write-Success "Git installed ✓"
    } catch {
        Write-Error-Custom "Git not found. Please install Git from https://git-scm.com"
        $prereqsMet = $false
    }
    
    # Check Node.js (needed for MCP servers)
    try {
        $nodeVersion = node --version 2>&1
        Write-Info "Node.js: $nodeVersion"
        Write-Success "Node.js installed ✓"
    } catch {
        Write-Warning-Custom "Node.js not found. MCP servers may not work. Install from https://nodejs.org"
    }
    
    # Check for GitHub Copilot CLI or VS Code
    $copilotCLIExists = $null -ne (Get-Command copilot -ErrorAction SilentlyContinue)
    $vsCodeExists = $null -ne (Get-Command code -ErrorAction SilentlyContinue)
    
    if ($copilotCLIExists) {
        Write-Success "GitHub Copilot CLI found ✓"
    } elseif (-not $SkipCopilotCLI) {
        Write-Warning-Custom "GitHub Copilot CLI not found in PATH"
    }
    
    if ($vsCodeExists) {
        Write-Success "VS Code found ✓"
    } elseif (-not $SkipVSCode) {
        Write-Warning-Custom "VS Code not found in PATH"
    }
    
    if (-not $copilotCLIExists -and -not $vsCodeExists) {
        Write-Error-Custom "Neither GitHub Copilot CLI nor VS Code found. Please install one of them."
        $prereqsMet = $false
    }
    
    return $prereqsMet
}

function Find-Repository {
    param([string]$ProvidedPath)
    
    Write-Header "Locating Repository"
    
    # If path provided, use it
    if ($ProvidedPath) {
        Write-Verbose "DEBUG Find-Repo: ProvidedPath=$ProvidedPath"
        if (Test-Path -Path $ProvidedPath -PathType Container) {
            if (Test-Path -Path "$ProvidedPath\.git" -PathType Container) {
                Write-Success "Repository found at: $ProvidedPath"
                Write-Verbose "DEBUG Find-Repo: Returning $ProvidedPath"
                return $ProvidedPath
            }
        }
        Write-Error-Custom "Invalid repository path: $ProvidedPath"
        return $null
    }
    
    # Search common locations
    $commonLocations = @(
        $PSScriptRoot,
        "$(Split-Path $PSScriptRoot -Parent)",
        "$env:USERPROFILE\repos\powerbi-agentic-plugins",
        "$env:USERPROFILE\git\powerbi-agentic-plugins",
        "$env:USERPROFILE\development\powerbi-agentic-plugins",
        "C:\Development\powerbi-agentic-plugins"
    )
    
    Write-Verbose "DEBUG Find-Repo: Searching locations..."
    foreach ($location in $commonLocations) {
        Write-Verbose "DEBUG Find-Repo: Checking $location"
        if (Test-Path -Path "$location\.git" -PathType Container) {
            Write-Success "Repository found at: $location"
            Write-Verbose "DEBUG Find-Repo: Returning $location"
            return $location
        }
    }
    
    # Prompt to clone
    Write-Info "Repository not found in common locations."
    $clonePath = Read-Host "Enter path to clone repository (default: $env:USERPROFILE\repos\powerbi-agentic-plugins)"
    
    if ([string]::IsNullOrWhiteSpace($clonePath)) {
        $clonePath = "$env:USERPROFILE\repos\powerbi-agentic-plugins"
    }
    
    if (Test-Path $clonePath) {
        Write-Error-Custom "Path already exists: $clonePath"
        return $null
    }
    
    Write-Info "Cloning repository to: $clonePath"
    try {
        $parentPath = Split-Path $clonePath -Parent
        if (-not (Test-Path $parentPath)) {
            New-Item -ItemType Directory -Path $parentPath -Force | Out-Null
        }
        git clone https://github.com/YuriChadour/powerbi-agentic-plugins.git $clonePath
        Write-Success "Repository cloned successfully"
        return $clonePath
    } catch {
        Write-Error-Custom "Failed to clone repository: $_"
        return $null
    }
}

function Install-Plugins {
    param(
        [string]$SourcePath,
        [string]$DestinationPath,
        [bool]$Force,
        [string[]]$Plugins
    )
    
    Write-Header "Installing Plugins"
    
    $successCount = 0
    Write-Info "Target plugins: $($Plugins -join ', ')"
    
    for ($i = 0; $i -lt $Plugins.Count; $i++) {
        $pluginName = $Plugins[$i]
        
        $sourcePath_Local = Join-Path (Join-Path $SourcePath "plugins") $pluginName
        $destPath_Local = Join-Path $DestinationPath $pluginName
        
        Write-Verbose "DEBUG: Processing plugin $($i+1) of $($Plugins.Count): $pluginName"
        Write-Verbose "DEBUG: Source: $sourcePath_Local"
        
        if (-not (Test-Path $sourcePath_Local)) {
            Write-Error-Custom "Plugin source not found: $sourcePath_Local"
            continue
        }
        
        # Remove existing if Force
        if ($Force -and (Test-Path $destPath_Local)) {
            Write-Info "Removing existing $pluginName plugin..."
            Remove-Item -Path $destPath_Local -Recurse -Force
        }
        
        # Create destination if needed
        if (-not (Test-Path $destPath_Local)) {
            New-Item -ItemType Directory -Path $destPath_Local -Force | Out-Null
        }
        
        # Copy plugin files
        Write-Info "Copying $pluginName plugin..."
        Copy-Item -Path "$sourcePath_Local\*" -Destination $destPath_Local -Recurse -Force
        
        # Verify key files exist
        if (Test-Path "$destPath_Local\skills") {
            Write-Success "$pluginName plugin installed ✓"
            $successCount++
        } else {
            Write-Error-Custom "$pluginName plugin missing skills directory"
        }
    }
    
    return $successCount -eq $Plugins.Count
}

function Sync-PluginsToDiscoveryRoot {
    param(
        [string]$InstallRoot,
        [string]$DiscoveryRoot,
        [string[]]$Plugins,
        [bool]$Force
    )

    if ($InstallRoot -eq $DiscoveryRoot) {
        return $true
    }

    foreach ($pluginName in $Plugins) {
        $sourcePath = Join-Path $InstallRoot $pluginName
        $destPath = Join-Path $DiscoveryRoot $pluginName

        if (-not (Test-Path $sourcePath)) {
            Write-Error-Custom "Installed plugin not found at: $sourcePath"
            return $false
        }

        if ($Force -and (Test-Path $destPath)) {
            Write-Info "Removing existing discovered $pluginName plugin..."
            Remove-Item -Path $destPath -Recurse -Force
        }

        if (-not (Test-Path $destPath)) {
            New-Item -ItemType Directory -Path $destPath -Force | Out-Null
        }

        Copy-Item -Path "$sourcePath\*" -Destination $destPath -Recurse -Force
        Write-Info "Mirrored $pluginName plugin to discovery path: $destPath"
    }

    return $true
}

function Register-PluginsInCopilotConfig {
    param(
        [string]$InstallRoot,
        [string]$MarketplaceName,
        [string[]]$Plugins,
        [string]$RepositoryPath
    )

    $configPath = "$env:USERPROFILE\.copilot\config.json"
    if (-not (Test-Path $configPath)) {
        Write-Warning-Custom "config.json not found — skipping plugin registration in config"
        return $false
    }

    Write-Header "Registering Plugins in Copilot Config"

    try {
        $config = ConvertFrom-JsonWithComments -RawContent (Get-Content $configPath -Raw)
    } catch {
        Write-Warning-Custom "Could not parse config.json ($_) — skipping plugin registration in config"
        return $false
    }

    if (-not $config.PSObject.Properties['installedPlugins']) {
        $config | Add-Member -NotePropertyName 'installedPlugins' -NotePropertyValue @() -Force
    }

    foreach ($pluginName in $Plugins) {
        $cachePath = Join-Path $InstallRoot $pluginName
        $version   = Get-PluginVersion -RepositoryPath $RepositoryPath -PluginName $pluginName

        $existing = $config.installedPlugins | Where-Object { $_.name -eq $pluginName -and $_.marketplace -eq $MarketplaceName }

        if ($existing) {
            $existing.version    = $version
            $existing.cache_path = $cachePath
            $existing.enabled    = $true
            Write-Info "Updated $pluginName in config.json (version $version)"
        } else {
            $entry = [PSCustomObject]@{
                name         = $pluginName
                marketplace  = $MarketplaceName
                installed_at = (Get-Date -Format "yyyy-MM-ddTHH:mm:ss.fffZ")
                enabled      = $true
                version      = $version
                cache_path   = $cachePath
            }
            $config.installedPlugins += $entry
            Write-Info "Registered $pluginName in config.json (version $version)"
        }
    }

    $config | ConvertTo-Json -Depth 20 | Set-Content $configPath -Encoding UTF8
    Write-Success "Plugin registrations saved to config.json ✓"
    return $true
}

function Register-PluginsInSettings {
    param(
        [string]$MarketplaceName,
        [string[]]$Plugins
    )

    $settingsPath = "$env:USERPROFILE\.copilot\settings.json"
    if (-not (Test-Path $settingsPath)) {
        Write-Warning-Custom "settings.json not found — skipping enabledPlugins update"
        return $false
    }

    try {
        $settings = ConvertFrom-JsonWithComments -RawContent (Get-Content $settingsPath -Raw)
    } catch {
        Write-Warning-Custom "Could not parse settings.json ($_) — skipping enabledPlugins update"
        return $false
    }

    if (-not $settings.PSObject.Properties['enabledPlugins']) {
        $settings | Add-Member -NotePropertyName 'enabledPlugins' -NotePropertyValue ([PSCustomObject]@{}) -Force
    }

    foreach ($pluginName in $Plugins) {
        $key = "$pluginName@$MarketplaceName"
        if (-not $settings.enabledPlugins.PSObject.Properties[$key]) {
            $settings.enabledPlugins | Add-Member -NotePropertyName $key -NotePropertyValue $true -Force
            Write-Info "Enabled $key in settings.json"
        } else {
            Write-Info "$key already enabled in settings.json"
        }
    }

    $settings | ConvertTo-Json -Depth 10 | Set-Content $settingsPath -Encoding UTF8

    Write-Success "Plugin settings saved to settings.json ✓"
    return $true
}

function Register-CopilotCLI {
    param([string]$ExtensionsPath)
    
    if ($SkipCopilotCLI) {
        Write-Info "Skipping GitHub Copilot CLI registration (--SkipCopilotCLI)"
        return $true
    }
    
    Write-Header "Registering with GitHub Copilot CLI"
    
    $copilotExists = $null -ne (Get-Command copilot -ErrorAction SilentlyContinue)
    if (-not $copilotExists) {
        Write-Warning-Custom "GitHub Copilot CLI not found. Skipping registration."
        return $false
    }
    
    try {
        # The plugins are already in the extensions directory
        # Copilot CLI will auto-discover them
        Write-Info "Plugins installed to: $ExtensionsPath"
        Write-Info "GitHub Copilot CLI will auto-discover plugins on next startup"
        
        # Try to list plugins to verify
        Write-Info "Verifying plugins are discoverable..."
        $listOutput = copilot /plugin list 2>&1
        Write-Success "GitHub Copilot CLI registration verified ✓"
        return $true
    } catch {
        Write-Warning-Custom "Could not verify GitHub Copilot CLI registration: $_"
        Write-Info "Plugins are installed; they will be auto-discovered on next CLI startup."
        return $false
    }
}

function Register-VSCode {
    param([string]$ExtensionsPath)
    
    if ($SkipVSCode) {
        Write-Info "Skipping VS Code integration (--SkipVSCode)"
        return $true
    }
    
    Write-Header "Integrating with VS Code"
    
    $codeExists = $null -ne (Get-Command code -ErrorAction SilentlyContinue)
    if (-not $codeExists) {
        Write-Warning-Custom "VS Code not found. Skipping integration."
        return $false
    }
    
    try {
        Write-Info "VS Code plugins directory: $ExtensionsPath"
        Write-Info "VS Code will auto-discover plugins on next startup"
        Write-Info "To enable Agent Skills in VS Code:"
        Write-Info "  1. Open VS Code Settings (Ctrl+,)"
        Write-Info "  2. Search for 'chat.useAgentSkills'"
        Write-Info "  3. Enable the setting"
        
        Write-Success "VS Code integration ready ✓"
        return $true
    } catch {
        Write-Error-Custom "Failed to integrate with VS Code: $_"
        return $false
    }
}

function Install-DesktopBridgeCli {
    param([bool]$Force)

    Write-Header "Installing Power BI Desktop Bridge CLI"

    $npmCmd = Get-Command npm -ErrorAction SilentlyContinue
    if (-not $npmCmd) {
        Write-Warning-Custom "npm not found — skipping powerbi-desktop-bridge-cli install. Install Node.js from https://nodejs.org, then run: npm install -g @microsoft/powerbi-desktop-bridge-cli"
        return $false
    }

    $existing = Get-Command powerbi-desktop -ErrorAction SilentlyContinue
    if ($existing -and -not $Force) {
        Write-Success "powerbi-desktop CLI already installed ✓ ($($existing.Source))"
        return $true
    }

    Write-Info "Running: npm install -g @microsoft/powerbi-desktop-bridge-cli"
    try {
        npm install -g "@microsoft/powerbi-desktop-bridge-cli" 2>&1 | ForEach-Object { Write-Verbose "$_" }

        $installed = Get-Command powerbi-desktop -ErrorAction SilentlyContinue
        if ($installed) {
            $version = & powerbi-desktop --version 2>&1
            Write-Success "powerbi-desktop CLI installed ✓ ($version)"
            return $true
        }

        Write-Warning-Custom "npm install completed but 'powerbi-desktop' was not found on PATH. You may need to restart your shell."
        return $false
    } catch {
        Write-Warning-Custom "Failed to install powerbi-desktop-bridge-cli: $_. Install manually with: npm install -g @microsoft/powerbi-desktop-bridge-cli"
        return $false
    }
}

function Validate-Installation {
    param(
        [string]$ExtensionsPath,
        [string[]]$Plugins
    )
    
    Write-Header "Validating Installation"
    
    $allValid = $true
    
    foreach ($plugin in $Plugins) {
        $pluginPath = Join-Path $ExtensionsPath $plugin
        
        if (-not (Test-Path $pluginPath)) {
            Write-Error-Custom "Plugin not found: $plugin"
            $allValid = $false
            continue
        }
        
        # Check required directories
        $hasAgents = Test-Path "$pluginPath\agents"
        $hasSkills = Test-Path "$pluginPath\skills"
        $hasMCP = Test-Path "$pluginPath\.mcp.json"

        if ($hasSkills) {
            $agentStatus = if ($hasAgents) { "agents ✓" } else { "agents (optional)" }
            Write-Success "$plugin plugin: $agentStatus skills ✓ $(if ($hasMCP) { 'mcp ✓' } else { 'mcp (optional)' })"
        } else {
            Write-Error-Custom "$plugin plugin missing required skills directory"
            $allValid = $false
        }
    }
    
    # List installed skills
    Write-Info "Installed plugins and skills:"
    foreach ($plugin in $Plugins) {
        $pluginPath = Join-Path $ExtensionsPath $plugin
        $skillsPath = "$pluginPath\skills"
        
        if (Test-Path $skillsPath) {
            $skills = Get-ChildItem -Path $skillsPath -Directory -Name
            foreach ($skill in $skills) {
                Write-Info "  • $plugin/$skill"
            }
        }
        if (Test-Path "$pluginPath\agents") {
            $agents = Get-ChildItem -Path "$pluginPath\agents" -File -Name
            foreach ($agent in $agents) {
                Write-Info "  • $plugin/agents/$agent"
            }
        }
    }
    
    return $allValid
}

function Show-NextSteps {
    param(
        [string]$ExtensionsPath,
        [string[]]$Plugins,
        [string]$BackupPath
    )
    
    Write-Header "Installation Complete!"
    
    Write-Info "Plugins installed to:"
    Write-Host "  $ExtensionsPath" -ForegroundColor $ColorInfo
    Write-Info "Installed plugin(s): $($Plugins -join ', ')"
    if ($BackupPath -and (Test-Path $BackupPath)) {
        Write-Info "Previous plugins (if any) were backed up to:"
        Write-Host "  $BackupPath" -ForegroundColor $ColorInfo
    }
    
    Write-Info "Next steps:"
    Write-Host "  1. Restart GitHub Copilot CLI or VS Code to load plugins" -ForegroundColor $ColorInfo
    Write-Host "  2. For Copilot CLI: run 'copilot /plugin list' to verify" -ForegroundColor $ColorInfo
    Write-Host "  3. For VS Code: enable 'chat.useAgentSkills' in settings (Ctrl+,)" -ForegroundColor $ColorInfo
    Write-Host "  4. Read DEVELOPER_SETUP.md for team workflows" -ForegroundColor $ColorInfo
    Write-Host "  5. Read CONTRIBUTING_TEAM.md for contribution guidelines" -ForegroundColor $ColorInfo
    
    Write-Info "Staying in sync:"
    Write-Host "  cd $(if ($RepositoryPath) { $RepositoryPath } else { '$RepositoryPath' })" -ForegroundColor $ColorInfo
    Write-Host "  git pull" -ForegroundColor $ColorInfo
    Write-Host "  .\setup-team-plugins.ps1 -Force" -ForegroundColor $ColorInfo
    
    Write-Host "`n"
}

#endregion

#region Main

try {
    Write-Host "
╔════════════════════════════════════════════════════════════════════════════╗
║         Power BI Agentic Plugins — Team Setup Script                      ║
║                                                                            ║
║  This script installs all plugins, or a single selected plugin, to your    ║
║  user profile for use with GitHub Copilot CLI and/or VS Code.             ║
╚════════════════════════════════════════════════════════════════════════════╝
" -ForegroundColor $ColorInfo
    
    # Test prerequisites
    if (-not (Test-Prerequisites)) {
        Write-Error-Custom "Prerequisites not met. Please fix the issues above and try again."
        exit 1
    }
    
    # Find or clone repository
    $repoPath = Find-Repository -ProvidedPath $RepositoryPath
    if (-not $repoPath) {
        Write-Error-Custom "Could not locate repository. Exiting."
        exit 1
    }

    # Resolve marketplace name and target plugins
    $marketplaceName = Get-MarketplaceName -RepositoryPath $repoPath
    $targetPlugins   = Get-TargetPlugins -PluginName $PluginName
    
    # Set up destination paths
    $installRoot   = Get-InstallRoot -MarketplaceName $marketplaceName
    $discoveryRoot = Get-DiscoveryRoot

    if (-not (Test-Path $installRoot)) {
        New-Item -ItemType Directory -Path $installRoot -Force | Out-Null
    }

    if (-not (Test-Path $discoveryRoot)) {
        New-Item -ItemType Directory -Path $discoveryRoot -Force | Out-Null
    }
    
    Write-Info "Install root: $installRoot"
    Write-Info "Discovery root: $discoveryRoot"

    # Always back up and remove any existing plugins before installing the current ones
    $backupPath = Backup-ExistingPlugins -InstallRoot $installRoot -DiscoveryRoot $discoveryRoot -Plugins $targetPlugins

    # Install plugins
    if (-not (Install-Plugins -SourcePath $repoPath -DestinationPath $installRoot -Force $Force -Plugins $targetPlugins)) {
        Write-Error-Custom "Failed to install plugins."
        exit 1
    }

    if (-not (Sync-PluginsToDiscoveryRoot -InstallRoot $installRoot -DiscoveryRoot $discoveryRoot -Plugins $targetPlugins -Force $Force)) {
        Write-Error-Custom "Failed to sync plugins to discovery path."
        exit 1
    }

    # Install Power BI Desktop Bridge CLI (needed for the powerbi-report-authoring skill's
    # Desktop reload/screenshot verification loop)
    if ($targetPlugins -contains "powerbi") {
        Install-DesktopBridgeCli -Force $Force | Out-Null
    }

    # Register plugins in Copilot config and settings
    Register-PluginsInCopilotConfig -InstallRoot $installRoot -MarketplaceName $marketplaceName -Plugins $targetPlugins -RepositoryPath $repoPath | Out-Null
    Register-PluginsInSettings -MarketplaceName $marketplaceName -Plugins $targetPlugins | Out-Null
    
    # Register with tools
    $cliRegistered = Register-CopilotCLI -ExtensionsPath $discoveryRoot
    $vscodeRegistered = Register-VSCode -ExtensionsPath $discoveryRoot
    
    # Validate
    if (-not (Validate-Installation -ExtensionsPath $discoveryRoot -Plugins $targetPlugins)) {
        Write-Error-Custom "Installation validation failed."
        exit 1
    }
    
    # Show next steps
    Show-NextSteps -ExtensionsPath $discoveryRoot -Plugins $targetPlugins -BackupPath $backupPath
    
    Write-Success "Setup complete!"
    exit 0
}
catch {
    Write-Error-Custom "Unexpected error: $_"
    Write-Host $_.ScriptStackTrace -ForegroundColor $ColorError
    exit 1
}

#endregion
