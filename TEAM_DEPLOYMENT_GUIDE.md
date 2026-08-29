# Team Deployment Guide: prep-powerbi-for-report-copilot

**For:** Internal team rollout and adoption of the prep-powerbi skill  
**Date:** May 2026  
**Duration:** 2–4 weeks (pilot → full rollout)

---

## Quick Links

- **Getting Started?** → Read [DEVELOPER_SETUP.md](DEVELOPER_SETUP.md) for installation instructions
- **Want to contribute?** → Read [CONTRIBUTING_TEAM.md](CONTRIBUTING_TEAM.md) for git workflow
- **First time using the skill?** → See "Using the Skill" section below

---

## Overview

This guide walks your team through adopting the `prep-powerbi-for-report-copilot` skill—a 5-step workflow to optimize Power BI reports for Report Copilot pane readiness.

**Key Benefits:**
- Ensure Copilot answers questions using *existing visuals* (not generating new ones)
- Protect sensitive fields (PII, restricted data) from Copilot reasoning
- Teach Copilot your business terminology
- Standardize Copilot behavior across the organization
- Reduce time spent training users on Copilot limitations

---

## Prerequisites

### For All Team Members
- **Plugins installed** via `setup-team-plugins.ps1` (see [DEVELOPER_SETUP.md](DEVELOPER_SETUP.md))
- GitHub Copilot CLI or VS Code with GitHub Copilot Chat extension
- Power BI Desktop 2024.5+ or Fabric Workspace access

### For Pilot Users (First 2)
- Same as above, PLUS:
- Experience with Power BI report development
- Access to a test/staging Power BI report (recommended: 20–50 visuals)
- ~4 hours available for the full workflow

### Optional
- Python 3.8+ (for diagnostic parsing; not required for main workflow)

---

## Installation & Setup

**New team members:** Follow [DEVELOPER_SETUP.md](DEVELOPER_SETUP.md) to install all plugins (powerbi + fabric + devops + skill-creator) in 3 steps.

---

## Phase A: Pilot Testing (Week 1)

### Step 1: Select 2 Pilot Users

Choose team members who:
- Are comfortable with Power BI report structures
- Have access to a suitable test report
- Can dedicate time for the workflow
- Are willing to provide feedback

**Suggested roles:** Senior Analyst, Power BI Developer, Report Architect

### Step 2: Run Workflow (3–4 hours)

Each pilot user runs the full 5-step workflow on their test report:

```powershell
copilot

# Start the skill with required inputs
/skill prep-powerbi-for-report-copilot

# Follow prompts:
# 1. Report name & format (PBIP or PBIX)?
# 2. Business domain (2–5 sentences)?
# 3. User personas (exec/analyst/risk)?
# 4. Top 10 questions Copilot should answer?
# 5. Sensitive fields policy?

# Skill generates 5 markdown documents in docs/copilot-prep/
```

**Expected Deliverables:**
- `01-report-usage-inventory.md` — visual → field mapping
- `02-ai-schema-recommendations.md` — include/exclude field list
- `03-ai-instructions.md` — terminology & defaults
- `04-answer-pack-design.md` — visual strategy
- `05-test-script-and-results.md` — test results

### Step 4: Pilot Feedback (1 hour)

Pilot users fill out **Pilot Feedback Form** (see below).

**Feedback Focus Areas:**
- Was the workflow clear? (Y/N, comments)
- Did the generated docs match your expectations? (Y/N, what's missing?)
- How long did it take vs. expected? (actual time)
- Would you recommend this to the team? (Y/N, why?)
- What should we improve? (free text)

### Step 5: Review & Iterate (1–2 days)

**Team lead:**
1. Collects feedback from both pilot users
2. Addresses any blockers or unclear steps
3. Documents findings in `PILOT_FEEDBACK_SUMMARY.md`
4. Decides: Ready for full rollout? (Y/N)

**If issues found:**
- Patch skill or documentation
- Re-test with pilots
- Loop back to Step 3

**If ready:**
- Proceed to Phase B (Full Rollout)

---

## Phase B: Full Team Rollout (Weeks 2–3)

### Step 2: Team Onboarding Session (30 min, optional)

**Host a meeting or record video:**
- Overview: Why we're adopting this skill (5 min)
- Demo: Run workflow on a sample report (10 min)
- Q&A: Address team questions (10 min)
- Next steps: Individual installation (5 min)

**Recording:** Share link to team Slack/wiki for async viewing

### Step 3: Installation for All Team Members

Each team member installs the plugins by following [DEVELOPER_SETUP.md](DEVELOPER_SETUP.md):

```powershell
# Clone the repository (one-time)
git clone https://github.com/YuriChadour/powerbi-agentic-plugins.git

# Run the setup script (installs all plugins)
cd powerbi-agentic-plugins
Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process -Force
.\setup-team-plugins.ps1

# Or install from an already-cloned local repo path
Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process -Force
.\setup-team-plugins.ps1 -RepositoryPath "C:\Development\powerbi-agentic-plugins"

# Verify
copilot /plugin list
```

**Support:** Designate a "Skill Champion" (see Phase C) for troubleshooting

### Step 4: First Report (Teams choose their own)

Each team member selects a Power BI report to optimize:
- Can be production or staging
- Should have 10+ visuals (minimum)
- Should serve a real business question

### Step 4: First Report (Teams choose their own)

Each team member selects a Power BI report to optimize:
- Can be production or staging
- Should have 10+ visuals (minimum)
- Should serve a real business question

### Step 5: Run Workflow & Document

Team runs the prep-powerbi-for-report-copilot skill on their report.

**Deliverable:** Commit generated docs to shared wiki or repo:
```
reports/
├── [Report-Name]/
│   └── copilot-prep/
│       ├── 01-report-usage-inventory.md
│       ├── 02-ai-schema-recommendations.md
│       ├── 03-ai-instructions.md
│       ├── 04-answer-pack-design.md
│       └── 05-test-script-and-results.md
```

**Timeline:** Week 2 (in parallel)

### Step 6: Peer Review

**Within Week 2–3:**
- Skill Champion + 1 peer review each report's docs
- Check for:
  - Sensitivity: No PII exposed in schema?
  - Completeness: All 5 docs present?
  - Quality: Terminology mapping correct?
- Provide constructive feedback (optional improvements)

### Step 7: Apply Changes to Reports

Each team member manually applies schema/instructions to their report via Power BI UI:

1. Open Power BI Desktop
2. Go to **Semantic Model** → **Prep data for AI**
3. **AI data schema tab:** Add/remove fields per recommendations
4. **AI instructions tab:** Copy instructions from `03-ai-instructions.md`
5. Save & publish to Fabric workspace

**Timeline:** End of Week 3

---

## Staying in Sync: Pulling Updates

When the team updates the repository, team members should pull the latest changes:

```powershell
# Navigate to your repo
cd $env:USERPROFILE\repos\powerbi-agentic-plugins  # or wherever you cloned it
Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process -Force

# Pull updates from GitHub
git pull origin main

# Reinstall plugins with the latest version
.\setup-team-plugins.ps1 -Force

# Restart Copilot CLI or VS Code
copilot /exit
copilot
```

**Recommended:** Pull updates weekly or when your team notifies you of changes.

**For contributors:** See [CONTRIBUTING_TEAM.md](CONTRIBUTING_TEAM.md) to learn how to create feature branches and submit pull requests.

---

## Phase C: Support & Enablement (Ongoing)

### Skill Champion Role

Designate **one team member** as Skill Champion:
- Answer day-to-day questions (Slack channel, weekly office hours)
- Troubleshoot installation issues
- Collect feedback for improvements
- Maintain internal wiki/knowledge base
- Track adoption metrics

**Time commitment:** ~2–3 hours/week

### Internal Slack Channel

Create: `#copilot-prep-powerbi` (or similar)

**Channels:**
- Share reports you've optimized
- Ask questions, share tips
- Post blockers
- Announce updates/improvements

### Office Hours (Optional)

**Weekly or bi-weekly 30-min sync:**
- Open Q&A
- Walkthrough examples
- Troubleshooting
- Feedback collection

---

## Success Metrics (Track Week 4+)

After full rollout, monitor:

| Metric | Target | Check |
|--------|--------|-------|
| **Adoption** | ≥80% of team has run skill | Week 4 |
| **Reports Prepped** | ≥3 reports optimized | Week 4 |
| **Copilot Accuracy** | ≥70% of top questions answered using existing visuals | Week 6 |
| **Team Satisfaction** | ≥4/5 rating in feedback survey | Week 6 |
| **Sensitive Data Protection** | 0 PII exposed in AI schemas | Week 4 |

---

## Troubleshooting Guide

### Installation Issues

| Problem | Solution |
|---------|----------|
| "Skill not found" | Re-run `.\setup-team-plugins.ps1 -RepositoryPath "C:\Development\powerbi-agentic-plugins"` from the local repo |
| PowerShell version error | Upgrade to PowerShell 5.1+ (ships with Windows) or PowerShell 7: https://github.com/PowerShell/PowerShell |
| "Cannot connect to GitHub" | Check firewall; try manual clone (Option B) |
| Plugin loads but skill missing | Run `copilot /skill list` to verify; restart Copilot |

### Workflow Issues

| Problem | Solution |
|---------|----------|
| "Report structure not recognized" | Ensure report is in PBIP format (File > Save As) |
| Missing field mappings | Verify all visuals have field wells populated; re-run inventory |
| Empty schema recommendations | Check that sensitive fields policy was specified |
| Instructions look generic | Customize terminology section in `03-ai-instructions.md` |

### Copilot Behavior Issues

| Problem | Solution |
|---------|----------|
| Copilot still generates new visuals | Verify schema changes applied in "Prep data for AI" |
| Copilot uses wrong field | Update terminology mapping in instructions |
| Copilot reveals sensitive data | Check that PII fields are removed from schema |

**Escalation:** If unresolved, Slack the Skill Champion or open GitHub issue

---

## Quick Reference Card (1-Pager)

Print and share with team:

```
╔═══════════════════════════════════════════════════════════════════╗
║        PREP POWER BI FOR REPORT COPILOT — QUICK START           ║
╚═══════════════════════════════════════════════════════════════════╝

INSTALLATION (see DEVELOPER_SETUP.md for full guide):
  1. git clone https://github.com/YuriChadour/powerbi-agentic-plugins.git
  2. cd powerbi-agentic-plugins
  3. Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process -Force
  4. .\setup-team-plugins.ps1

USING THE SKILL:
  copilot
  /skill prep-powerbi-for-report-copilot

WORKFLOW:
  • Step 1: Report Usage Inventory
  • Step 2: AI Data Schema (what to hide from Copilot)
  • Step 3: AI Instructions (terminology + defaults)
  • Step 4: Answer Pack (pages optimized for Copilot)
  • Step 5: Test & Iterate

OUTPUT:
  ✓ 01-report-usage-inventory.md
  ✓ 02-ai-schema-recommendations.md
  ✓ 03-ai-instructions.md
  ✓ 04-answer-pack-design.md
  ✓ 05-test-script-and-results.md

APPLY TO POWER BI:
  • Semantic Model > Prep data for AI
  • Add/remove fields per schema
  • Copy instructions
  • Save & publish

TEST IN COPILOT PANE:
  • Ask one of your top questions
  • Verify it uses existing visual
  • Iterate if needed

═══════════════════════════════════════════════════════════════════

HELP: 
  Setup: DEVELOPER_SETUP.md
  Contribute: CONTRIBUTING_TEAM.md
  Slack: #copilot-prep-powerbi
  Office Hours: [schedule]

═══════════════════════════════════════════════════════════════════
```

---

## Knowledge Base Articles (Wiki)

Create these articles for your team wiki/Confluence:

### Article 1: Understanding AI Data Schema
- What fields Copilot should see
- Why we hide FK columns
- Bucket vs. raw values
- Sensitive field protection

### Article 2: Terminology Best Practices
- Common mapping mistakes
- Date field clarifications
- Creating Copilot-friendly measure names
- Examples from our reports

### Article 3: Answer Pack Strategy
- Why existing visuals matter
- Naming conventions for Copilot discovery
- Creating anchor text
- Testing checklist

### Article 4: Troubleshooting
- "Copilot still generating new visuals" (FAQ)
- "How to hide a column after initial schema"
- "Updating instructions without breaking reports"

---

## Pilot Feedback Form Template

```markdown
# Prep Power BI for Report Copilot — Pilot Feedback

**Pilot User:** [Name]  
**Date:** [Date]  
**Report Tested:** [Report Name]  
**Time Spent:** [Actual hours] (vs. 4 hours expected)

## Workflow Clarity
**Q: Was the 5-step workflow clear and easy to follow?**
- [ ] Yes, very clear
- [ ] Mostly clear, small confusion
- [ ] Confusing in places
- [ ] Very confusing

Comments: [...]

## Generated Documents
**Q: Did the 5 generated documents meet expectations?**
- [ ] Excellent, everything I needed
- [ ] Good, minor gaps
- [ ] OK, missing some important info
- [ ] Poor, too vague/incomplete

Most useful doc: [...]  
Least useful doc: [...]  
What's missing? [...]

## Recommendations
**Q: Would you recommend this skill to the team?**
- [ ] Yes, definitely
- [ ] Yes, with improvements
- [ ] Maybe, need to see more
- [ ] No, not ready

Why/why not? [...]

## Improvements
**Q: What could we improve?**

1. [Priority 1]: [...]
2. [Priority 2]: [...]
3. [Priority 3]: [...]

## Additional Notes
[Free text feedback]
```

---

## Timeline Summary

| Week | Activity | Owner | Deliverable |
|------|----------|-------|-------------|
| Week 1 | Pilot: Install + Workflow + Feedback | 2 Pilots | Feedback form |
| Week 1 | Review & iterate | Lead | Pilot summary |
| Week 2–3 | Team: Install + Run + Apply | All | Optimized reports |
| Week 2–3 | Peer review | Champion | Review checklist |
| Week 3 | Apply schema/instructions | All | Updated models |
| Week 4+ | Support + Monitor metrics | Champion | Monthly report |

---

## Success Criteria: Team Readiness

✅ **Go-Live When:**
- [ ] All team members installed skill
- [ ] 3+ reports successfully optimized
- [ ] No critical blockers from pilot
- [ ] Slack channel active with Q&A
- [ ] Wiki articles published
- [ ] Skill Champion assigned

✅ **Measure Success After 4 Weeks:**
- [ ] ≥80% adoption rate
- [ ] ≥70% of Copilot queries use existing visuals
- [ ] Zero PII exposure incidents
- [ ] Team satisfaction ≥4/5

---

## Next Steps

1. **Week 0:** Send this guide to team; identify 2 pilots
2. **Week 1:** Pilots install + run workflow + provide feedback
3. **Week 2:** Review feedback; prepare onboarding
4. **Week 3:** Full team install + apply to own reports
5. **Week 4+:** Monitor adoption; gather metrics

---

**Questions?** Contact: [Skill Champion Name] / [Slack Channel]

**Latest Version:** [Date]  
**Fork:** https://github.com/YuriChadour/powerbi-agentic-plugins
