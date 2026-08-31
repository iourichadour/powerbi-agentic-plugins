#Requires -Version 5.1
<#
.SYNOPSIS
    Setup script for installing Power BI Agentic Plugins into Claude Code.

.DESCRIPTION
    Installs all plugins, or a single selected plugin, from a local copy of the
    powerbi-agentic-plugins repository into Claude Code via the supported
    `claude plugin` marketplace commands.

    The script validates prerequisites, registers (or refreshes) the repo's
    `.claude-plugin/marketplace.json` as a local marketplace, installs the
    requested plugins from it, and — when the `powerbi` plugin is in scope —
    installs the Power BI Desktop Bridge CLI
    (@microsoft/powerbi-desktop-bridge-cli).

    This is the Claude Code counterpart to `setup-team-plugins.ps1` (which wires
    the same plugins into GitHub Copilot CLI / VS Code). The two are independent;
    running one does not affect the other.

.PARAMETER RepositoryPath
    Path to the local powerbi-agentic-plugins repository.
    If not provided, common locations are searched, then a clone is offered.

.PARAMETER PluginName
    Install only the specified plugin instead of all plugins.
    Valid values: powerbi, fabric, devops, skill-creator

.PARAMETER Force
    Reinstall plugins even if already present (uninstall + reinstall). Use this
    to pick up local changes to a plugin without bumping its version.

.PARAMETER Uninstall
    Remove the plugins from Claude Code and offer to remove the marketplace.

.PARAMETER SkipDesktopBridge
    Skip the global npm install of @microsoft/powerbi-desktop-bridge-cli.

.PARAMETER Verbose
    Enable verbose logging for troubleshooting.

.EXAMPLE
    .\setup-claude-plugins.ps1

.EXAMPLE
    .\setup-claude-plugins.ps1 -RepositoryPath "C:\Development\powerbi-agentic-plugins" -Force

.EXAMPLE
    .\setup-claude-plugins.ps1 -PluginName devops

.EXAMPLE
    .\setup-claude-plugins.ps1 -Uninstall

.NOTES
    Requires PowerShell 5.1 or later (Windows PowerShell 5.1 or PowerShell 7+)
    Requires the Claude Code CLI (`claude`) installed and on PATH
    Git recommended; Node.js/npm required only for the Desktop Bridge CLI
#>

param(
    [string]$RepositoryPath,
    [ValidateSet("powerbi", "fabric", "devops", "skill-creator")]
    [string]$PluginName,
    [switch]$Force,
    [switch]$Uninstall,
    [switch]$SkipDesktopBridge,
    [switch]$Verbose
)

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
    Write-Host ("`n" + ("=" * 80)) -ForegroundColor $ColorInfo
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

function Find-Repository {
    param([string]$ProvidedPath)

    Write-Header "Locating Repository"

    if ($ProvidedPath) {
        Write-Verbose "DEBUG Find-Repo: ProvidedPath=$ProvidedPath"
        if (Test-Path -Path $ProvidedPath -PathType Container) {
            if (Test-Path -Path "$ProvidedPath\.claude-plugin\marketplace.json") {
                Write-Success "Repository found at: $ProvidedPath"
                return $ProvidedPath
            }
        }
        Write-Error-Custom "Invalid repository path (no .claude-plugin\marketplace.json): $ProvidedPath"
        return $null
    }

    $commonLocations = @(
        $PSScriptRoot,
        "$(Split-Path $PSScriptRoot -Parent)",
        "$env:USERPROFILE\repos\powerbi-agentic-plugins",
        "$env:USERPROFILE\git\powerbi-agentic-plugins",
        "$env:USERPROFILE\development\powerbi-agentic-plugins",
        "C:\Development\powerbi-agentic-plugins"
    )

    foreach ($location in $commonLocations) {
        Write-Verbose "DEBUG Find-Repo: Checking $location"
        if ($location -and (Test-Path -Path "$location\.claude-plugin\marketplace.json")) {
            Write-Success "Repository found at: $location"
            return $location
        }
    }

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
        git clone https://github.com/iourichadour/powerbi-agentic-plugins.git $clonePath
        Write-Success "Repository cloned successfully"
        return $clonePath
    } catch {
        Write-Error-Custom "Failed to clone repository: $_"
        return $null
    }
}

function Test-Prerequisites {
    Write-Header "Validating Prerequisites"

    $prereqsMet = $true

    Write-Info "PowerShell version: $($PSVersionTable.PSVersion)"
    if ($PSVersionTable.PSVersion -lt [Version]"5.1") {
        Write-Error-Custom "PowerShell 5.1 or later is required"
        $prereqsMet = $false
    } else {
        Write-Success "PowerShell 5.1+ ✓"
    }

    $claudeCmd = Get-Command claude -ErrorAction SilentlyContinue
    if ($claudeCmd) {
        Write-Success "Claude Code CLI found ✓ ($($claudeCmd.Source))"
    } else {
        Write-Error-Custom "Claude Code CLI ('claude') not found in PATH."
        Write-Info    "Install it with: npm install -g @anthropic-ai/claude-code"
        Write-Info    "or see https://docs.claude.com/en/docs/claude-code"
        $prereqsMet = $false
    }

    $gitCmd = Get-Command git -ErrorAction SilentlyContinue
    if ($gitCmd) {
        Write-Success "Git installed ✓"
    } else {
        Write-Warning-Custom "Git not found. Needed only if the script has to clone the repo."
    }

    $npmCmd = Get-Command npm -ErrorAction SilentlyContinue
    if ($npmCmd) {
        Write-Success "Node.js / npm installed ✓"
    } else {
        Write-Warning-Custom "npm not found. The Power BI Desktop Bridge CLI install will be skipped."
    }

    return $prereqsMet
}

function Invoke-Claude {
    # Runs the claude CLI, streams output to the host, and returns a result
    # object { ExitCode, Output } without throwing on a non-zero exit.
    param([string[]]$Arguments)

    Write-Verbose "DEBUG Invoke-Claude: claude $($Arguments -join ' ')"
    $output = & claude @Arguments 2>&1 | ForEach-Object {
        $line = $_.ToString()
        Write-Verbose $line
        $line
    }
    return [pscustomobject]@{
        ExitCode = $LASTEXITCODE
        Output   = ($output -join "`n")
    }
}

function Register-Marketplace {
    param([string]$RepositoryPath, [string]$MarketplaceName)

    Write-Header "Registering Marketplace"
    Write-Info "Marketplace: $MarketplaceName"
    Write-Info "Source:      $RepositoryPath"

    # `marketplace add` is idempotent — it exits 0 whether the marketplace is
    # newly added or "already on disk".
    $add = Invoke-Claude -Arguments @("plugin", "marketplace", "add", $RepositoryPath)
    if ($add.ExitCode -ne 0 -and $add.Output -notmatch "already") {
        Write-Error-Custom "Failed to register marketplace:`n$($add.Output)"
        Write-Info "Run manually: claude plugin marketplace add `"$RepositoryPath`""
        return $false
    }
    Write-Success "Marketplace registered ✓"

    # Always refresh from source so a re-run picks up local marketplace.json edits.
    $update = Invoke-Claude -Arguments @("plugin", "marketplace", "update", $MarketplaceName)
    if ($update.ExitCode -eq 0) {
        Write-Success "Marketplace refreshed from source ✓"
    } else {
        Write-Warning-Custom "Could not refresh marketplace (using cached copy):`n$($update.Output)"
    }
    return $true
}

function Install-Plugins {
    param([string[]]$Plugins, [string]$MarketplaceName, [bool]$Force)

    Write-Header "Installing Plugins"
    Write-Info "Target plugins: $($Plugins -join ', ')"

    $successCount = 0
    foreach ($plugin in $Plugins) {
        $ref = "$plugin@$MarketplaceName"

        # `claude plugin install` has no --force; to reinstall we remove first.
        if ($Force) {
            Write-Info "Removing existing $plugin (for -Force reinstall)..."
            Invoke-Claude -Arguments @("plugin", "uninstall", $ref) | Out-Null
        }

        # -y accepts the marketplace-declared install without a TTY prompt.
        Write-Info "Installing $ref ..."
        $result = Invoke-Claude -Arguments @("plugin", "install", $ref, "-y")

        if ($result.ExitCode -eq 0 -or $result.Output -match "already installed") {
            Write-Success "$plugin installed ✓"
            $successCount++
        }
        elseif ($result.Output -match "trust|confirm|interactive|prompt") {
            Write-Warning-Custom "$plugin needs an interactive trust prompt. Run manually:"
            Write-Info "  claude plugin install $ref -y"
        }
        else {
            Write-Error-Custom "Failed to install ${plugin}:`n$($result.Output)"
        }
    }

    Write-Info "$successCount of $($Plugins.Count) plugin(s) installed."
    return $successCount
}

function Uninstall-Plugins {
    param([string[]]$Plugins, [string]$MarketplaceName)

    Write-Header "Uninstalling Plugins"

    foreach ($plugin in $Plugins) {
        $ref = "$plugin@$MarketplaceName"
        Write-Info "Uninstalling $ref ..."
        $result = Invoke-Claude -Arguments @("plugin", "uninstall", $ref)
        if ($result.ExitCode -eq 0 -or $result.Output -match "not installed") {
            Write-Success "$plugin removed ✓"
        } else {
            Write-Warning-Custom "Could not uninstall ${plugin}:`n$($result.Output)"
        }
    }

    $answer = Read-Host "Also remove the '$MarketplaceName' marketplace? (y/N)"
    if ($answer -match '^(y|yes)$') {
        $result = Invoke-Claude -Arguments @("plugin", "marketplace", "remove", $MarketplaceName)
        if ($result.ExitCode -eq 0) {
            Write-Success "Marketplace removed ✓"
        } else {
            Write-Warning-Custom "Could not remove marketplace:`n$($result.Output)"
        }
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

function Show-Verification {
    param([string[]]$Plugins, [string]$MarketplaceName)

    Write-Header "Verifying Installation"

    $list = Invoke-Claude -Arguments @("plugin", "list")
    if ($list.ExitCode -eq 0) {
        Write-Host $list.Output
    } else {
        Write-Warning-Custom "Could not run 'claude plugin list':`n$($list.Output)"
    }

    $pluginsRoot = Join-Path $env:USERPROFILE ".claude\plugins"
    if (Test-Path $pluginsRoot) {
        Write-Info "Claude plugins root: $pluginsRoot"
    }

    foreach ($plugin in $Plugins) {
        if ($list.Output -match [regex]::Escape($plugin)) {
            Write-Success "$plugin present in 'claude plugin list' ✓"
        } else {
            Write-Warning-Custom "$plugin not visible in 'claude plugin list' — restart Claude Code or check /plugin."
        }
    }
}

#endregion

#region Main

Write-Header "Power BI Agentic Plugins — Claude Code Setup"

$repoPath = Find-Repository -ProvidedPath $RepositoryPath
if (-not $repoPath) {
    Write-Error-Custom "Could not locate the repository. Pass -RepositoryPath with the repo path."
    exit 1
}

if (-not (Test-Prerequisites)) {
    Write-Error-Custom "Prerequisites not met. Resolve the errors above and re-run."
    exit 1
}

$marketplaceName = Get-MarketplaceName -RepositoryPath $repoPath
$targetPlugins = Get-TargetPlugins -PluginName $PluginName

if ($Uninstall) {
    Uninstall-Plugins -Plugins $targetPlugins -MarketplaceName $marketplaceName
    Write-Header "Done"
    Write-Info "Restart Claude Code (or run /plugin) for the change to take effect."
    exit 0
}

if (-not (Register-Marketplace -RepositoryPath $repoPath -MarketplaceName $marketplaceName)) {
    exit 1
}

$installed = Install-Plugins -Plugins $targetPlugins -MarketplaceName $marketplaceName -Force $Force.IsPresent

if (($targetPlugins -contains "powerbi") -and (-not $SkipDesktopBridge)) {
    Install-DesktopBridgeCli -Force $Force.IsPresent | Out-Null
}

Show-Verification -Plugins $targetPlugins -MarketplaceName $marketplaceName

Write-Header "Next Steps"
Write-Info "1. Restart Claude Code (or run /plugin) so it picks up the new plugins."
Write-Info "2. Verify with: claude plugin list"
Write-Info "3. To update later:"
Write-Info "     git -C `"$repoPath`" pull"
Write-Info "     claude plugin marketplace update $marketplaceName"
Write-Info "     .\setup-claude-plugins.ps1 -Force"
Write-Info "4. To remove:  .\setup-claude-plugins.ps1 -Uninstall"

if ($installed -lt $targetPlugins.Count) {
    Write-Warning-Custom "Some plugins did not install cleanly — see messages above."
    exit 1
}

Write-Success "Claude Code setup complete."
exit 0

#endregion
