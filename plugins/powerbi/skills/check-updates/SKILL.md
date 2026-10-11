---
name: check-updates
description: >
  Check for skills-for-fabric marketplace updates. Compares local version 
  against GitHub releases and shows changelog if updates are available. Use ONLY when the 
  user explicitly asks: (1) check for skill updates, (2) see what's new in skills-for-fabric, 
  (3) verify current version. Triggers: "check for updates", "am I up to date", 
  "what version", "update skills", "show changelog".
metadata:
  version: 0.1.0
---

# Check for Updates

This skill checks for updates to the skills-for-fabric marketplace.

## When to Run

> **Update Check — explicit only**
> Only run this check when the user explicitly asks (e.g., "check for updates", "is there a new version", "check-updates"). Do not invoke it automatically at session start or the first time any skill is used, regardless of any cadence language elsewhere in this file.

## Session State

The update check marker is stored in a **persistent, user-level directory** shared across all sessions and all plugins in the Fabric Skills marketplace:

```text
~/.config/fabric-collection/last-update-check.json
```
  
This file contains a JSON object mapping plugin names to the **UTC date** (YYYY-MM-DD) of their last update check:

```json
{
  "fabric-skills": "2026-02-17",
  "another-plugin": "2026-02-16"
}
```

Before checking, read `~/.config/fabric-collection/last-update-check.json`:
- If the file exists and the entry for the current plugin is within the last **7 days** (compared to the current **UTC date**), skip the check.
- If the file is missing, the plugin entry is absent, or the date is more than 7 days old (compared to the current **UTC date**), run the update check.

> **IMPORTANT — use UTC consistently**: Always use the current UTC date when saving and comparing the last-update-check timestamp. Do not use the local system timezone, as it varies across environments and can cause the check to run too often or be skipped. In shell, use `date -u +%Y-%m-%d` (Linux/macOS) or `(Get-Date).ToUniversalTime().ToString("yyyy-MM-dd")` (PowerShell).

> **Note**: Create the `~/.config/fabric-collection/` directory if it does not exist. On Windows, use `$env:USERPROFILE\.config\fabric-collection\`.

## Update Check Procedure

### Step 1: Get Local Version

Read the local plugin manifest at `.claude-plugin/marketplace.json` (repo root, or the equivalent path inside whatever install layout you're running from — e.g. `~/.copilot/installed-plugins/<collection>/<plugin>/.claude-plugin/marketplace.json` for a Copilot CLI plugin install, or `.claude-plugin/marketplace.json` at the repo root for a manual git clone).

This file contains a top-level `metadata.version` field (the repo/collection version) and, under `plugins[]`, a per-plugin `version` field for each plugin entry (e.g. `powerbi`, `fabric`). Use the repo-level `metadata.version` for an overall update check, or the specific plugin's `version` entry if the check concerns a single plugin.

### Step 2: Determine Repository Owner and Name

This repo does not currently publish a `repository` field in `.claude-plugin/marketplace.json`. Default to the known repository:

```text
owner: YuriChadour
repo: powerbi-agentic-plugins
```

If a future version of `.claude-plugin/marketplace.json` adds an explicit `repository` field (e.g. a `"https://github.com/<owner>/<repo>"` URL), prefer that value and parse `owner`/`repo` from it instead of the default above.

> **CRITICAL**: If a `repository` field is present, use the owner string **exactly as it appears** in the URL. Do NOT alter, normalize, or "correct" the owner name — including underscores, mixed case, or any other punctuation. (LLMs sometimes "auto-correct" underscores to hyphens — don't.)

### Step 3: Fetch Latest Release

Use the available tools in your environment to get the latest version. **Try methods in strict order — only fall back to the next method if the previous one fails or is unavailable.**

> **IMPORTANT**: Methods A and B work with both public and private repositories. Method C only works with public repos. Always attempt A or B first.

**Method A — Git CLI (preferred for git-clone installs)**

Only available if the plugin directory is a Git working tree (i.e. it has a `.git` entry — either a directory in a normal clone, or a file in a worktree/submodule). A Copilot CLI plugin install directory typically has no `.git` entry — for that install layout, skip to Method B. If you want a tool-agnostic check, run `git rev-parse --is-inside-work-tree` and only proceed if it prints `true`.

If you do have a Git clone, fetch the remote `.claude-plugin/marketplace.json` without pulling:

```bash
git fetch origin main --quiet
git show origin/main:.claude-plugin/marketplace.json
```

Extract the `metadata.version` field (or the relevant plugin's `version` entry under `plugins[]`) from the JSON output. This method is the most reliable because it uses the already-configured remote URL and authentication, and avoids any owner/repo name parsing.

**Method B — GitHub MCP tools (preferred for agentic environments)**

If you have access to GitHub MCP server tools (e.g., `get_file_contents`), use them to read the remote `.claude-plugin/marketplace.json`. Use the owner and repo from Step 2 **exactly as parsed** (do not modify the strings):

```text
get_file_contents(owner: "YuriChadour", repo: "powerbi-agentic-plugins", path: ".claude-plugin/marketplace.json")
```

Extract the `metadata.version` field (or the relevant plugin's `version` entry under `plugins[]`) from the response. This method works with private repositories because MCP tools use authenticated GitHub access.

**Method C — GitHub REST API (fallback only, public repos)**

> ⚠️ **Only use this method if Methods A and B both fail or are unavailable.** This method does not work with private repositories.

If the repository is public, make a GET request using the owner/repo from Step 2:

```text
GET https://api.github.com/repos/YuriChadour/powerbi-agentic-plugins/releases/latest
```

Extract the `tag_name` field (e.g., `v0.2.0`) and remove the `v` prefix.

> **Note**: This method returns 404 for private repositories, or if no GitHub Release has been published yet. If you receive a 404 error, do NOT assume the repository doesn't exist — retry with Method A or B and fall back to comparing `.claude-plugin/marketplace.json` directly.

### Step 4: Compare Versions

Compare the local version with the remote version using semantic versioning:
- If remote > local: Update available
- If remote <= local: Up to date

### Step 5: Display Results

#### If Up to Date

Show a brief confirmation and proceed:
```text
✅ skills-for-fabric v0.1.0 is up to date.
```

#### If Update Available

Show detailed information:

```text
╔══════════════════════════════════════════════════════════════════╗
║  🔄 skills-for-fabric Update Available                                ║
║                                                                  ║
║  Current: v0.1.0  →  Latest: v0.2.0                             ║
╚══════════════════════════════════════════════════════════════════╝

## What's New in v0.2.0

[Display relevant CHANGELOG.md entries here]

## Update Commands

Choose the update method based on how you installed skills-for-fabric.

### GitHub Copilot CLI (recommended)
/plugin update fabric-skills@fabric-collection

If you originally installed the plugin under the legacy id, this also works:
  /plugin update skills-for-fabric@fabric-collection

The plugin was renamed in 0.3.0 (skills-for-fabric → fabric-skills),
but the legacy id is kept as a deprecated alias of fabric-skills, so
either /plugin update command pulls the canonical payload.

(Optional cleanup) To migrate your installed entry from the legacy id
to the canonical fabric-skills id:
  /plugin uninstall skills-for-fabric@fabric-collection
  /plugin install fabric-skills@fabric-collection

### Manual (Git clone)
cd /path/to/skills-for-fabric
git pull

(There are no installation scripts to re-run on 0.3.0+.)

─────────────────────────────────────────────────────────────────
Would you like to update now? (The current skill will still work)
```

### Step 6: Set Update Marker

After completing the check (regardless of result), update `~/.config/fabric-collection/last-update-check.json` with today's **UTC date** (YYYY-MM-DD) for the current plugin. Create the directory and file if they don't exist. Preserve entries for other plugins already in the file.

## Must

- Only run this skill when the user explicitly asks for an update check — never automatically at session start or on first use of another skill
- Always proceed with the requested skill after the check (non-blocking)
- Handle network errors gracefully (show warning, continue with skill)
- Display the CHANGELOG.md content for versions between current and latest

## Prefer

- Use Git CLI (Method A) or GitHub MCP tools (Method B) for version checking — these work with private repos
- Fall back to the public GitHub REST API (Method C) **only** if Methods A and B both fail
- Show a concise summary rather than overwhelming detail
- Cache the check result in `~/.config/fabric-collection/last-update-check.json`
- Provide copy-pasteable update commands

## Avoid

- Blocking the user from using skills if update check fails
- Running this check automatically (at session start, on first skill use, or on any cadence) — it must only run when the user explicitly asks
- Attempting Method C (public API) before trying Methods A or B
- Relying solely on unauthenticated public API calls (will fail for private repos)
- Auto-updating without user consent

## Error Handling

If the update check fails (network error, API rate limit, etc.):

```text
⚠️ Could not check for skills-for-fabric updates (network error).
   Continuing with current version (v0.1.0).
   Run '/skill check-updates' manually to retry.
```

## Manual Invocation

Users can manually check for updates at any time:
- GitHub Copilot CLI: `/skill check-updates`
- Other tools: Invoke the check-updates skill directly

## Reference

- **GitHub Repository**: https://github.com/YuriChadour/powerbi-agentic-plugins
- **Releases**: https://github.com/YuriChadour/powerbi-agentic-plugins/releases
- **CHANGELOG**: See `CHANGELOG.md` in repository root
