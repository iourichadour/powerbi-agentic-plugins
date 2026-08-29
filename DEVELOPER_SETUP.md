# Developer Setup Guide: Get the Team Plugins Running

**Duration:** 5–10 minutes  
**For:** All team members who want to use Power BI and Fabric plugins locally

---

## Quick Start (3 Steps)

### Step 1: Clone the Repository
```powershell
# Clone the fork to your local machine
git clone https://github.com/YuriChadour/powerbi-agentic-plugins.git
cd powerbi-agentic-plugins
```

### Step 2: Run the Setup Script
```powershell
# Run the setup script (one command installs everything)
Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process -Force
.\setup-team-plugins.ps1

# Or install from a repo you already cloned elsewhere
Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process -Force
.\setup-team-plugins.ps1 -RepositoryPath "C:\Development\powerbi-agentic-plugins"

# Or install only one plugin
Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process -Force
.\setup-team-plugins.ps1 -PluginName powerbi
```

The script will:
- ✓ Set execution policy to Bypass for the current PowerShell session only
- ✓ Validate your system (PowerShell 5.1+, Git, GitHub Copilot CLI or VS Code)
- ✓ Copy all plugins to `$env:USERPROFILE\.copilot\installed-plugins\powerbi-agentic-plugins\` and mirror them to `extensions\` for discovery
- ✓ Register plugins in `config.json` and `settings.json` so Copilot CLI picks them up on next start
- ✓ Register plugins with GitHub Copilot CLI (if installed)
- ✓ Configure plugins for VS Code (if installed)
- ✓ Set up MCP servers
- ✓ Install the Power BI Desktop Bridge CLI (`@microsoft/powerbi-desktop-bridge-cli`) globally via npm, when the `powerbi` plugin is included
- ✓ Validate the installation

### Step 3: Verify Installation
```powershell
# GitHub Copilot CLI
copilot
/plugin list
# Should show: powerbi, fabric, devops, skill-creator ✓

# VS Code
# Restart VS Code and open Settings (Ctrl+,)
# Search for "chat.useAgentSkills" and enable it
```

Done! Your plugins are ready to use.

---

## Detailed Setup Guide

### Prerequisites

Before you start, ensure you have:

- **PowerShell 5.1 or later** (Windows PowerShell 5.1, ships with Windows, or PowerShell 7+)
  ```powershell
  $PSVersionTable.PSVersion  # Should show 5.1 or higher
  ```
  Not on 5.1+? Get PowerShell 7 from https://github.com/PowerShell/PowerShell

- **Git installed**
  ```powershell
  git --version
  ```
  Not installed? Get it from https://git-scm.com

- **Node.js 18+ (recommended for MCP servers)**
  ```powershell
  node --version
  ```
  Not installed? Get it from https://nodejs.org

- **One of these:**
  - GitHub Copilot CLI (`copilot` command available)
  - VS Code with GitHub Copilot Chat extension
  - Or both!

### Step-by-Step Installation

#### 1. Clone the Repository

You only need to do this once.

```powershell
# Choose a location for your repos (examples below)
cd "$env:USERPROFILE\repos"          # or
cd "$env:USERPROFILE\development"    # or
cd "C:\Development"                   # or any folder you prefer

# Clone the fork
git clone https://github.com/YuriChadour/powerbi-agentic-plugins.git
cd powerbi-agentic-plugins
```

**What you'll see:**
```
Cloning into 'powerbi-agentic-plugins'...
remote: Enumerating objects: ... 
Receiving objects: 100% (...)
Resolving deltas: 100% (...)
```

#### 2. Check the Setup Script

Before running, take a quick look at what the script does:

```powershell
Get-Content setup-team-plugins.ps1 -Head 30
```

You'll see the documentation explaining each step.

#### 3. Run the Setup Script

```powershell
# Basic setup (installs all plugins)
Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process -Force
.\setup-team-plugins.ps1

# If you already have plugins installed and want to update
Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process -Force
.\setup-team-plugins.ps1 -Force

# If you only want GitHub Copilot CLI (skip VS Code setup)
Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process -Force
.\setup-team-plugins.ps1 -SkipVSCode

# If you only want VS Code (skip Copilot CLI setup)
Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process -Force
.\setup-team-plugins.ps1 -SkipCopilotCLI

# Verbose output for troubleshooting
Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process -Force
.\setup-team-plugins.ps1 -Verbose
```

**What the script does:**

1. **Validates prerequisites** — checks PowerShell version, Git, Node.js, Copilot CLI/VS Code
2. **Finds the repository** — uses the current directory or searches common locations
3. **Copies plugins** — installs all plugins by default, or just one when `-PluginName` is provided, to `~\.copilot\installed-plugins\powerbi-agentic-plugins\`
4. **Registers plugins** — writes entries into `config.json` and `settings.json` so Copilot CLI discovers them on next start
5. **Mirrors to extensions** — copies plugins to `~\.copilot\extensions\` for VS Code discovery
6. **Configures MCP servers** — sets up Model Context Protocol servers from `.mcp.json` files
7. **Validates installation** — verifies all plugins loaded correctly

#### 4. Restart Your Tools

After running the setup script:

**For GitHub Copilot CLI:**
```powershell
# Restart Copilot
copilot
/exit

# Restart it
copilot

# Verify plugins loaded
/plugin list
```

**For VS Code:**
- Close and reopen VS Code
- Open Settings (`Ctrl+,`)
- Search for `chat.useAgentSkills`
- Enable the setting
- Restart VS Code

#### 5. Verify Installation

Check that your plugins are installed and loaded:

**GitHub Copilot CLI:**
```powershell
copilot
/plugin list
```

You should see:
```
Available plugins:
  • powerbi — Power BI and Fabric development  ✓
  • fabric — Fabric administration and operations  ✓
  • devops — Branch hygiene and Azure DevOps policies  ✓
```

**VS Code:**
- Open the Copilot Chat sidebar (`Ctrl+Shift+I` or `Cmd+Shift+I`)
- You should see that Copilot recognizes your plugins (they'll be available in context)

---

## Staying in Sync (Pulling Updates)

When the team updates the repository, pull the latest changes:

```powershell
# Navigate to your repo
cd $env:USERPROFILE\repos\powerbi-agentic-plugins  # or wherever you cloned it

# Pull updates
git pull

# Reinstall plugins (this updates them to the latest version)
Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process -Force
.\setup-team-plugins.ps1 -Force

# Restart your tools (Copilot CLI or VS Code)
```

**Recommended:** Pull updates weekly or when your team notifies you of changes.

---

## Troubleshooting

### Issue: "PowerShell 5.1 or later required"

**Solution:** Install PowerShell 7 from https://github.com/PowerShell/PowerShell, or use the Windows PowerShell 5.1 that ships with Windows.

To check your version:
```powershell
$PSVersionTable.PSVersion
```

### Issue: "Git not found. Please install Git"

**Solution:** Install Git from https://git-scm.com

After installing, restart PowerShell and verify:
```powershell
git --version
```

### Issue: "GitHub Copilot CLI not found in PATH"

**Solutions:**
- Install GitHub Copilot CLI from https://github.com/features/copilot/cli
- Or use the script with `Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process -Force` then `.\setup-team-plugins.ps1 -SkipCopilotCLI` to install for VS Code only

### Issue: "Repository not found in common locations"

**Solution:** When prompted, either:
1. Enter the path where you cloned the repo, or
2. Let the script clone it for you (default: `$env:USERPROFILE\repos\powerbi-agentic-plugins`)

### Issue: Plugin not appearing in Copilot CLI after setup

**Steps:**
1. Verify the plugin files are in the right location:
   ```powershell
   ls "$env:USERPROFILE\.copilot\installed-plugins\powerbi-agentic-plugins\powerbi"
   ls "$env:USERPROFILE\.copilot\installed-plugins\powerbi-agentic-plugins\fabric"
   ls "$env:USERPROFILE\.copilot\installed-plugins\powerbi-agentic-plugins\devops"
   ```
   Each should show `agents` and `skills` folders.

2. Verify Copilot config registration:
   ```powershell
   (Get-Content "$env:USERPROFILE\.copilot\config.json" | ConvertFrom-Json).installedPlugins | Select-Object name, marketplace, enabled
   ```
   All four plugins (`powerbi`, `fabric`, `devops`, `skill-creator`) should appear with `enabled = True`.

3. Restart Copilot CLI:
   ```powershell
   copilot
   /exit
   copilot
   /plugin list
   ```

4. Check for errors:
   ```powershell
   Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process -Force
   .\setup-team-plugins.ps1 -Verbose
   ```

### Issue: "Node.js not found" warning

**Impact:** This is a warning, not an error. MCP servers may not fully initialize. To fix:
- Install Node.js from https://nodejs.org (18+ recommended)
- Restart your tools after installing

### Issue: VS Code plugins not auto-discovered

**Steps:**
1. In VS Code, open Settings (`Ctrl+,`)
2. Search for `chat.useAgentSkills`
3. Enable the setting (check the box)
4. Restart VS Code

If still not working:
- Check that plugins are in the right location:
  ```powershell
  ls "$env:USERPROFILE\.copilot\extensions"
  ```
- Manually add the extensions folder in VS Code settings

---

## FAQ

**Q: Can I customize the plugins for my team?**  
A: Yes! Once installed, you can modify skills and agents. See `CONTRIBUTING_TEAM.md` for guidelines.

**Q: What if I want to install only certain plugins?**  
A: Pass `-PluginName powerbi`, `-PluginName fabric`, `-PluginName devops`, or `-PluginName skill-creator` to install just one plugin.

**Q: Do I need both GitHub Copilot CLI and VS Code?**  
A: No. Install one or both, depending on your preference. The setup script supports both.

**Q: How do I uninstall plugins?**  
A: Remove the plugin folders and re-run the setup with `-Force` to clean up:
  ```powershell
  rm -r "$env:USERPROFILE\.copilot\installed-plugins\powerbi-agentic-plugins\powerbi"
  rm -r "$env:USERPROFILE\.copilot\installed-plugins\powerbi-agentic-plugins\fabric"
  rm -r "$env:USERPROFILE\.copilot\installed-plugins\powerbi-agentic-plugins\devops"
  rm -r "$env:USERPROFILE\.copilot\extensions\powerbi"
  rm -r "$env:USERPROFILE\.copilot\extensions\fabric"
  rm -r "$env:USERPROFILE\.copilot\extensions\devops"
  ```

**Q: What if the setup script fails?**  
A: Run with `-Verbose` for detailed output:
  ```powershell
  Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process -Force
  .\setup-team-plugins.ps1 -Verbose
  ```
  Then check the "Troubleshooting" section above or ask your team lead.

**Q: How often should I update?**  
A: Pull updates weekly or when your team notifies you. You'll run `git pull`, then `Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process -Force`, then `.\setup-team-plugins.ps1 -Force`.

**Q: Can I have the repo in a different location?**  
A: Yes! Pass the path to the script:
  ```powershell
  Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process -Force
  .\setup-team-plugins.ps1 -RepositoryPath "C:\my\custom\path"
  ```

---

## Next Steps

1. **Verify installation:** Run `copilot /plugin list` or check VS Code
2. **Read the skills:** Check out the documentation in `plugins/powerbi/skills/` and `plugins/fabric/skills/`
3. **Try it out:** Open Copilot and ask it to help with Power BI or Fabric tasks
4. **Contribute:** See `CONTRIBUTING_TEAM.md` to learn how to improve skills and agents

---

## Getting Help

- **Script not working?** Run with `Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process -Force` then `.\setup-team-plugins.ps1 -Verbose`
- **Want to contribute?** Read `CONTRIBUTING_TEAM.md`
- **Have questions?** Contact your team lead or open an issue on GitHub

---

**Enjoy using the Power BI and Fabric plugins!** 🎉
