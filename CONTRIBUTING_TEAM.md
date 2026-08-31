# Contributing Guide: Team Collaboration Workflow

**For:** Team members who want to improve or customize plugins, agents, and skills

---

## Overview

This repository uses a **fork-based collaboration model**:

1. You clone the team fork (`YuriChadour/powerbi-agentic-plugins`)
2. Create a feature branch for your changes
3. Make changes to skills, agents, or configurations
4. Test your changes locally
5. Push your branch and create a Pull Request (PR)
6. Team lead reviews and merges

---

## Quick Start: Contributing a Change

### 1. Clone (if you haven't already)

```powershell
git clone https://github.com/YuriChadour/powerbi-agentic-plugins.git
cd powerbi-agentic-plugins
```

### 2. Create a Feature Branch

```powershell
# Update to latest main
git pull origin main

# Create a new branch (use descriptive names)
git checkout -b feature/improve-copilot-instructions
# or
git checkout -b bugfix/fix-ai-schema-export
```

**Branch naming conventions:**
- `feature/description` — New feature or enhancement
- `bugfix/description` — Bug fix
- `docs/description` — Documentation updates
- `test/description` — Test improvements
- `chore/description` — Maintenance or non-functional changes

Examples:
- ✓ `feature/add-wac-bucket-validation`
- ✓ `bugfix/fix-tmdl-parser-error`
- ✓ `docs/update-setup-guide`
- ✗ `my-changes` (too vague)
- ✗ `fixing-stuff` (unclear what changed)

### 3. Make Your Changes

Edit files in your branch:
- `plugins/<plugin>/skills/[skill-name]/SKILL.md` — Update skill workflows
- `plugins/<plugin>/agents/[agent-name].md` — Update agent instructions
- `plugins/<plugin>/.mcp.json` — Update MCP server configuration
- Documentation and tests

**Key files not to modify without review:**
- `.git/` — Git internals
- `.gitignore` — Version control settings
- `LICENSE` — License terms
- Root `README.md` — Only update with team lead approval

### 4. Test Your Changes Locally

```powershell
# Reinstall plugins with your changes
Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process -Force
.\setup-team-plugins.ps1 -Force

# Restart Copilot CLI or VS Code
copilot /exit
copilot

# Test the updated skill or agent
/skill list  # Verify your changes are there
```

**Testing checklist:**
- [ ] Setup script runs without errors
- [ ] All plugins install to `$env:USERPROFILE\.copilot\extensions\`
- [ ] Copilot CLI or VS Code recognizes the changes
- [ ] Agents and skills load without errors
- [ ] Your specific change works as expected

### 5. Commit Your Changes

```powershell
# Stage your changes
git add plugins/powerbi/skills/prep-powerbi-for-report-copilot/SKILL.md

# View what you're about to commit
git status
git diff --cached

# Commit with a clear message
git commit -m "feat: add validation for report usage inventory

- Add checks for visual field bindings
- Improve error messages for missing axes
- Document expected field types
- Add examples of valid vs invalid configurations"
```

**Commit message format:**
```
[type]: [subject]

[optional body describing the change]

[optional footer]
```

Types: `feat`, `fix`, `docs`, `test`, `chore`, `refactor`

Examples:
- ✓ `feat: improve ai-schema recommendations for fact tables`
- ✓ `fix: correct tmdl relationship parsing`
- ✓ `docs: update troubleshooting section in DEVELOPER_SETUP.md`
- ✗ `updated stuff`
- ✗ `fix`

### 6. Push Your Branch

```powershell
# Push to your fork
git push origin feature/improve-copilot-instructions
```

You'll see output like:
```
Enumerating objects: 5, done.
Counting objects: 100% (5/5), done.
...
To https://github.com/YuriChadour/powerbi-agentic-plugins.git
 * [new branch]      feature/improve-copilot-instructions -> feature/improve-copilot-instructions
```

### 7. Create a Pull Request (PR)

Go to https://github.com/YuriChadour/powerbi-agentic-plugins and you'll see a prompt to create a PR:

![Create PR button](https://docs.github.com/assets/cb-3554/images/help/pull_requests/pull-request-start-review-button.png)

**PR title and description:**
```
Title: Improve AI schema recommendations for fact tables

Description:
This PR enhances the AI schema recommendations algorithm to:
- Better identify foreign key columns in fact tables
- Exclude raw numeric columns in favor of calculated measures
- Add clearer rationale for EXCLUDE decisions
- Include visual examples in the AI schema CSV

Fixes #42
Closes #38

Testing:
- Tested with IAM_FIELD_MAPPING model (206 measures)
- Verified FK columns correctly identified in relationships.tmdl
- Validated exclude recommendations reduce schema noise by 40%
```

### 8. Review and Merge

**Team lead** (or designated reviewer) will:
1. Review your code and changes
2. Request changes if needed (you'll revise and push again)
3. Approve and merge to main

After merge:
```powershell
# Pull the latest changes
git pull origin main

# Clean up your local branch (optional)
git branch -d feature/improve-copilot-instructions
```

---

## What to Change vs. What NOT to Change

### ✓ DO Change:
- **Skills** (`plugins/powerbi/skills/*/SKILL.md`)
  - Workflow steps
  - Templates and examples
  - Troubleshooting guidance
  - Best practices

- **Agents** (`plugins/<plugin>/agents/*.md`)
  - Instructions and prompts
  - Skills referenced
  - Role descriptions

- **MCP Configuration** (`.mcp.json`)
  - Server versions
  - Tool parameters
  - New tool additions

- **Documentation**
  - README files
  - Guides (DEVELOPER_SETUP.md, CONTRIBUTING_TEAM.md)
  - Comments in code

- **Tests** (if any)
  - Test cases
  - Validation logic

### ✗ DO NOT Change (without team lead review):
- License or legal terms
- Root `README.md` (coordinate with team lead)
- `.gitignore` or git configuration
- CI/CD workflows (if any)
- Plugin structure (adding/removing plugins)

---

## Working with Skills

### Editing a Skill

Skills are markdown files that define workflows. When editing:

1. **Locate the skill:**
   ```powershell
   # Example: editing the prep-powerbi-for-report-copilot skill
   code plugins/powerbi/skills/prep-powerbi-for-report-copilot/SKILL.md
   ```

2. **Make targeted improvements:**
   - Clarify confusing workflow steps
   - Add missing examples
   - Fix errors in templates
   - Improve troubleshooting sections

3. **Test in Copilot:**
   ```powershell
   # Reinstall with your changes
   Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process -Force
   .\setup-team-plugins.ps1 -Force
   
   # Restart Copilot and ask it to use the skill
   copilot
   
   # Example prompt:
   # "Help me optimize my Power BI report for Copilot readiness"
   ```

4. **Commit with clear message:**
   ```powershell
   git commit -m "docs: improve Step 2 AI schema recommendations

   - Add visual example of FK columns to exclude
   - Clarify bucket/range column classification
   - Add common mistakes section"
   ```

### Adding a New Skill

To add a new skill (requires team lead approval):

1. Create skill directory:
   ```powershell
   mkdir "plugins/powerbi/skills/my-new-skill"
   ```

2. Create `SKILL.md` with required sections:
   - Name and description
   - Primary objective
   - Required inputs
   - Workflow steps (numbered)
   - Templates
   - Guardrails

3. Update agent files to reference the new skill:
   ```powershell
   code plugins/devops/agents/devops.md
   # Add to "## Skills to use" section
   ```

4. Create a PR and request team lead review

---

## Working with Agents

### Editing an Agent

Agents are markdown files that define personas and tool usage. When editing:

1. **Locate the agent:**
   ```powershell
   code plugins/devops/agents/devops.md
   ```

2. **Update agent properties:**
   - Title, role, expertise
   - Skills referenced (in "## Skills to use")
   - Tools available (in MCP config)
   - Instructions and guidelines

3. **Test:**
   - Reinstall for Copilot: run `Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process -Force` then `.\setup-team-plugins.ps1 -Force`
   - Reinstall for Claude Code: `.\setup-claude-plugins.ps1 -Force`
   - Ask the assistant to take on the agent role

4. **Commit:**
   ```powershell
   git commit -m "feat: add fabric-admin skills to powerbi-architect agent"
   ```

---

## Code Review Checklist

When your PR is reviewed, the team lead will check:

- [ ] Changes align with project goals
- [ ] Skill workflows are clear and actionable
- [ ] Examples and templates are complete
- [ ] No breaking changes to existing workflows
- [ ] Documentation updated (if applicable)
- [ ] Commit messages are clear
- [ ] No merge conflicts

---

## Staying in Sync

### Before You Start a New Feature:
```powershell
# Fetch latest changes
git fetch origin

# Make sure main is up to date
git checkout main
git pull origin main
```

### If Your Branch Falls Behind:
```powershell
# While on your feature branch
git rebase origin/main

# Or use merge (alternative)
git merge origin/main
```

### If There's a Merge Conflict:
```powershell
# You'll see conflict markers in files
# Edit files to resolve, then:
git add .
git rebase --continue  # or git merge --continue
git push origin [branch-name]
```

---

## Troubleshooting

### Issue: "Your branch is ahead of 'origin/main' by 3 commits"

**Cause:** Your branch has commits that main doesn't.  
**Solution:** This is normal before you push. Just push:
```powershell
git push origin feature/my-feature
```

### Issue: "fatal: The current branch feature/xyz has no upstream branch"

**Cause:** New branch hasn't been pushed yet.  
**Solution:** Push with:
```powershell
git push -u origin feature/xyz
```

### Issue: Merge conflict

**Solution:**
1. Edit conflicted files
2. Look for `<<<<<<<`, `=======`, `>>>>>>>`
3. Keep the version you want
4. Remove conflict markers
5. Stage and commit:
   ```powershell
   git add .
   git commit -m "Resolve merge conflicts in SKILL.md"
   ```

### Issue: Accidentally committed to main

**Solution:**
```powershell
# Create a new branch from current main
git branch feature/my-fix

# Reset main to origin/main
git checkout main
git reset --hard origin/main

# Switch to your feature branch
git checkout feature/my-fix
```

---

## Best Practices

### Commit Often
Make small, logical commits instead of one giant commit:
```powershell
# Good: Three focused commits
git commit -m "docs: add FK column example"
git commit -m "docs: add bucket/range classification table"
git commit -m "docs: add common mistakes section"

# Avoid: One giant commit
git commit -m "updated docs"
```

### Write Clear Messages
```powershell
# Good
git commit -m "fix: handle case-insensitive column names in AI schema

The parser was failing on columns like LTV (uppercase) when the
model definition used ltv (lowercase). Now normalizes column names
before comparison."

# Avoid
git commit -m "fixed bug"
```

### Test Before Pushing
```powershell
# Always test your changes locally
Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process -Force
.\setup-team-plugins.ps1 -Force
# Then manually verify in Copilot
```

### Keep Branches Focused
One feature per branch:
```powershell
# Good
git checkout -b feature/add-bucket-validation

# Avoid
git checkout -b feature/massive-overhaul-of-everything
```

---

## Getting Help

- **Git help:** `git help [command]` or https://git-scm.com/doc
- **Team questions:** Ask your team lead
- **Stuck on a PR?** Comment with `@[team-lead-username]` to notify

---

## Summary

1. Clone → Create branch → Make changes → Test locally
2. Commit with clear message → Push → Create PR
3. Wait for review → Respond to feedback
4. Team lead merges → Pull latest → Delete old branch
5. Repeat!

Happy contributing! 🚀
