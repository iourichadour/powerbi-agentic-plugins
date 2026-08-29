# 🧩 Power BI Agentic Plugins

Plugins that turn GitHub Copilot into a specialist for Power BI and Microsoft Fabric development. Built for [GitHub Copilot CLI](https://github.com/features/copilot/cli) and [Claude Code](https://claude.com/product/claude-code), also compatible with [VS Code](https://code.visualstudio.com/).

## 📦 Plugins

| Plugin                           | What it does                                                                                                                      | 
| -------------------------------- | --------------------------------------------------------------------------------------------------------------------------------- | 
| **[powerbi](./plugins/powerbi)** | Create semantic models, author reports in PBIR, write DAX queries, explore published datasets, apply modeling best practices, and **optimize reports for Report Copilot pane readiness**. | 
| **[fabric](./plugins/fabric)**   | Navigate workspaces, import/export item definitions, call Fabric & Power BI REST APIs, run jobs, and manage OneLake files.        |
| **[devops](./plugins/devops)**   | Enforce branch hygiene, standard Azure DevOps branch policies, and team-safe Git workflows.                                      |
| **[skill-creator](./plugins/skill-creator)** | Official Anthropic skill-authoring toolkit — create new skills, run with-skill/baseline benchmark evals, optimize trigger descriptions, and package `.skill` files. Vendored unmodified from [anthropics/claude-plugins-official](https://github.com/anthropics/claude-plugins-official). |

Every plugin follows the same structure:

```
plugin-name/
├── .claude-plugin/plugin.json   # Manifest
├── .mcp.json                    # Tool connections
├── agents/ or agent.md          # Agent personas with role-specific instructions
└── skills/                      # Domain knowledge Copilot draws on automatically
```

- **Skills** encode domain expertise, best practices, command references, and step-by-step workflows. Copilot draws on them automatically when relevant.
- **Agents** define personas with specific responsibilities (e.g., a Power BI architect vs. developer) and declare which skills and tools to use. Some single-purpose plugins package one top-level `agent.md` instead of an `agents/` folder.
- **Connectors** wire Copilot to external tools — the Fabric CLI and Power BI Modeling MCP — via [MCP servers](https://modelcontextprotocol.io/).

**These plugins are starting points.** They become much more useful when you customize them for how your team actually works:

- **Add company context** — Add your naming conventions, workspace structure, and modeling patterns into skill files so Copilot understands your world.
- **Adjust workflows** — Modify skill instructions to match how your team does things (e.g., your deployment pipeline, your BPA rules).
- **Swap connectors** — Edit `.mcp.json` to point at your specific MCP servers.
  
## 🚀 Getting Started

Select your AI assistant and install the plugin or skills directly within it.

### 🤝 For Teams: Team-Based Plugin Setup (Recommended)

If you're setting up plugins for a **team or group**, use the team-friendly setup approach:

1. **Clone the repository** (one person or each team member):
   ```powershell
   git clone https://github.com/YuriChadour/powerbi-agentic-plugins.git
   cd powerbi-agentic-plugins
   ```

2. **Run the setup script** (each team member):
   ```powershell
   Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process -Force
   .\setup-team-plugins.ps1
   ```

   The script sets execution policy to `Bypass` for the current session only, so it works without admin rights.

3. **Verify installation** (each team member):
   ```powershell
   copilot /plugin list
   ```

**Benefits:**
- ✓ All plugins (powerbi + fabric + devops + skill-creator) install in one command
- ✓ Both GitHub Copilot CLI and VS Code supported
- ✓ MCP servers auto-configured
- ✓ Team can pull updates via `git pull` and reinstall with `-Force`
- ✓ Easy to contribute improvements back to the team fork

**See [DEVELOPER_SETUP.md](DEVELOPER_SETUP.md) for full team setup guide including troubleshooting.**

### GitHub Copilot CLI Setup (Individual Users)

- Install [GitHub Copilot CLI](https://github.com/features/copilot/cli)
- Clone or download this repository locally, then run the setup script from that folder:

    ```powershell
    git clone https://github.com/YuriChadour/powerbi-agentic-plugins.git
    cd powerbi-agentic-plugins
    Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process -Force
    .\setup-team-plugins.ps1
    ```

- If the repo is already on disk somewhere else, point the script at that local path:

    ```powershell
    Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process -Force
    .\setup-team-plugins.ps1 -RepositoryPath "C:\Development\powerbi-agentic-plugins"
    ```

- To install only one plugin, add `-PluginName powerbi` (or `fabric`, `devops`, `skill-creator`). It installs to `~\.copilot\installed-plugins\<plugin>` and mirrors into `~\.copilot\extensions\<plugin>` so Copilot can discover it.

### Sample install prompts

Use these prompts when you want the assistant to install just one plugin:

```text
Use @setup-team-plugins.ps1 -PluginName powerbi to install only the Power BI plugin.
```
```text
Use @setup-team-plugins.ps1 -PluginName fabric to install only the Fabric plugin.
```
```text
Use @setup-team-plugins.ps1 -PluginName devops to install only the DevOps plugin.
```
```text
Use @setup-team-plugins.ps1 -PluginName skill-creator to install only the Skill Creator plugin.
```

Once installed, plugins activate automatically. Skills fire when relevant — for example, asking Copilot to create a semantic model automatically pulls in the `powerbi-semantic-model` skill.

### Visual Studio Code Setup

- Install [Visual Studio Code](https://code.visualstudio.com/download)
- Install [GitHub Copilot Chat extension](https://marketplace.visualstudio.com/items?itemName=GitHub.copilot-chat)
- Enable [Agent Skills](vscode://settings/chat.useAgentSkills) and [Use Skill Adherence Prompt](vscode://settings/chat.experimental.useSkillAdherencePrompt) in user settings (Ctrl+,)
- Follow [discover and install plugins](https://code.visualstudio.com/docs/copilot/customization/agent-plugins#_discover-and-install-plugins) to install this plugin in VS Code.
- Optionally, you can also clone/download this repo and manually setup in your workspac
    - Copy the skills you want from the downloaded plugin repo (e.g. `plugins\powerbi\skills`) to `.github/skills` 

        Your folder structure should look like this:

        ```text
        Folder/
        ├── .github/
        │   └── skills/
        │       └── powerbi-semantic-model/
        │           └── SKILL.md
        ├── ...
        ```

        See [GitHub Agent Skills documentation](https://code.visualstudio.com/docs/copilot/customization/agent-skills) for more information where you can configure skills with VS Code.


## ✨ What's New: Report Copilot Pane Optimization

This fork adds the **prep-powerbi-for-report-copilot** skill to the powerbi plugin. Optimize your Power BI reports and semantic models so the Report Copilot pane reliably answers questions using existing visuals.

### 5-Step Workflow
1. 📋 **Report Usage Inventory** — Document which fields each visual uses
2. 🎯 **AI Data Schema** — Design what Copilot should and shouldn't see
3. 💬 **AI Instructions** — Teach Copilot your business terminology
4. 📊 **Answer Pack** — Create visuals that Copilot will reference
5. ✅ **Test & Iterate** — Validate and refine Copilot behavior

### Example Prompt
```bash
# Prompt:
    Optimize my Power BI report for Copilot readiness
    
    Report path: C:\projects\portfolio-analysis\
    Business domain: Portfolio performance tracking for asset managers
    Top questions: ["What's the portfolio balance by state?", "Show me top 10 delinquencies", ...]
    Sensitive fields: SSN, taxpayer ID
```

See [prep-powerbi-for-report-copilot skill](plugins/powerbi/skills/prep-powerbi-for-report-copilot/README.md) for full details and workflow.


## 📊 Scenarios

### New Direct Lake semantic model on top of Lakehouse tables

```
# 1. Create a Lakehouse in Microsoft Fabric
# 2. Load it with some sample data, e.g. Retail sample data
# 3. Prompt:
    Create a new direct lake semantic model in workspace [workspace] that uses the tables from lakehouse [lakehouse]
```

### Semantic Model on top of CSV data

```
# Prompt:
    Create a new semantic model based on the CSV files located in `https://github.com/RuiRomano/powerbi-agentic-plugins/tree/main/assets/sample-data` use Power Query HTTP connector. Apply standard modeling best practices throughout (e.g., proper relationships, naming conventions, data types, and star schema design).
    After creating the semantic model, create a Power BI report on top of it.
```

### Align Report visuals

- Save a report as PBIP
- Close Desktop
- Open the PBIP using Copilot CLI
- Run the prompt
- Reopen PBIP in Power BI Desktop

```
# Prompt:
    Align the Power BI report visuals in the PBIR folder `Path to the PBIP *.Report\ folder`
    
```

### Spec driven development

- Create a Fabric workspace
- Using the [powerbi-architect](plugins/powerbi/agents/powerbi-architect.agent.md) agent
- Run the prompt below
- Using the [powerbi-developer](plugins/powerbi/agents/powerbi-developer.agent.md) agent ask to implement the spec created by the architect agent

Prompt:
```
## Goals

- Work in Fabric workspace: '[Workspace name]'
- I want to create a new Power BI semantic model with name 'SM_Sales_GitHub'
- CSV files are in the URL: https://github.com/RuiRomano/powerbi-agentic-plugins/tree/main/assets/sample-data
- **Business requirements:**
  - I want to see the total sales amount so that I can understand revenue performance.
  - I want to understand the taxes impact
  - I want to see year-over-year and month-over-month sales growth percentages  
- Ensure my **Team modeling guidelines are respected**. See [team-modeling-rules.md](assets/team-modeling-rules.md)
- **Before implementation create a spec for review**
  
## Expectations

- Model deployed to the Fabric workspace
- Model should be refreshed 
- Measures return expected results with acceptable performance

## Other
- When analysing CSV files from GitHub don't use the fetch_webpage. Download the files locally to a temp folder (`temp/`) and analyze the top ~50 rows without loading the entire file to LLM context window.
    
```

## Acknowledgments

The `fabric` plugin includes the `fabric-cli` skill by [Kurt Buhler](https://github.com/data-goblin), originally from [fabric-cli-plugin](https://github.com/data-goblin/fabric-cli-plugin).

## No Warranty / Limitation of Liability

This software is provided "as is" without warranties or conditions of any kind, either express or implied. Microsoft shall not be liable for any damages arising from use, misuse, or misconfiguration of this software.

## Code of Conduct

This project has adopted the [Microsoft Open Source Code of Conduct](https://opensource.microsoft.com/codeofconduct/). For more information, see the [Code of Conduct FAQ](https://opensource.microsoft.com/codeofconduct/faq/) or contact [open@microsoft.com](mailto:open@microsoft.com) with any additional questions or comments.
