# Prep Power BI for Report Copilot Pane

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
![PowerShell](https://img.shields.io/badge/PowerShell-7.0%2B-blue)
![Power BI](https://img.shields.io/badge/Power%20BI-Desktop%20%26%20Service-blue)

**Optimize your Power BI reports and semantic models so the Report Copilot pane reliably answers questions using existing visuals and generates accurate new visuals.**

## Problem

Power BI's Report Copilot pane is powerful—but only when your report is designed for it. Without proper setup:
- ❌ Copilot generates visuals instead of finding answers in existing ones
- ❌ Confused terminology leads to wrong answers
- ❌ Sensitive fields are exposed to Copilot reasoning
- ❌ Users get inconsistent results

## Solution

This skill guides you through a **5-step workflow** to optimize your reports for Copilot:

1. **Report Usage Inventory** — Document which fields/measures each visual uses
2. **AI Data Schema** — Decide what Copilot should (and shouldn't) see
3. **AI Instructions** — Teach Copilot your business terminology and defaults
4. **Answer Pack** — Build visuals that answer your top questions
5. **Test & Iterate** — Validate Copilot behavior and refine

## What You'll Get

After running this skill, you'll have:

```
docs/copilot-prep/
├── 01-report-usage-inventory.md      ← Which fields each visual uses
├── 02-ai-schema-recommendations.md   ← Include/exclude list for Copilot
├── 03-ai-instructions.md              ← Terminology, defaults, date logic
├── 04-answer-pack-design.md           ← Visual strategy & testing plan
└── 05-test-script-and-results.md      ← Test results & fixes
```

Plus (optional):
- **AI Data Schema** configured in Power BI
- **AI Instructions** applied to your semantic model
- **Answer Pack pages** with verified answers inside the report

## Quick Start

### Prerequisites
- **Power BI Desktop** or **Fabric Workspace** access
- **PowerShell 7.0+** (run `$PSVersionTable.PSVersion` to check)
- **Report format:** PBIP (preferred) or PBIX

### Installation

**Option A: Automatic (PowerShell)**
```powershell
# Download and run installer
iwr "https://raw.githubusercontent.com/[your-org]/prep-powerbi-for-report-copilot/main/install-skill.ps1" | iex
```

**Option B: Manual**
1. Clone this repo: `git clone https://github.com/[your-org]/prep-powerbi-for-report-copilot.git`
2. Copy the skill folder to `.github/extensions/` in your Copilot CLI project
3. Run: `copilot` (verify the skill loads)

### First Run (5 Minutes)

```powershell
# 1. Start Copilot CLI in your repo
cd C:\your\powerbi\repo
copilot

# 2. Invoke the skill
/skill prep-powerbi-for-report-copilot

# 3. Answer the required inputs:
#    - Report name and format (PBIP/PBIX)
#    - Business domain (2–5 sentences)
#    - User personas (exec/analyst/risk/ops)
#    - Top 10–25 questions you want Copilot to answer

# 4. Follow the workflow (Step 0 → Step 6)
# 5. Review the generated docs in docs/copilot-prep/
```

## Example: Investment Fund Report

**Before:**
```
User: "Show me the top 10 underperforming holdings"
Copilot: [Generates new visual with raw numeric columns]
❌ Result: Confusing, unformatted, not trusted
```

**After:**
```
User: "Show me the top 10 underperforming holdings"
Copilot: [References existing "Portfolio Performance" Answer Pack visual]
✓ Result: Consistent, formatted, instantly trusted
```

## Key Features

✅ **Report-driven schema** — Only includes fields actually used in your visuals  
✅ **Sensitive field protection** — Exclude PII and restricted data from Copilot  
✅ **Terminology mapping** — Teach Copilot your business terms (e.g., "balance" → `[Total Current Balance $M]`)  
✅ **Answer Pack strategy** — Design visuals that Copilot will find and reference  
✅ **Test & iterate** — Validate behavior with automated test scripts  
✅ **Dual AI mode** — Works with reasoning models (o1, Claude) and instruction-following models (GPT-4o)  

## Workflow Overview

```
┌─────────────────────────────────────────────────────────┐
│ Step 0: Discover Report Structure                       │
│ → Identify pages, visuals, filters, semantic model     │
└────────────────┬────────────────────────────────────────┘
                 │
┌─────────────────▼────────────────────────────────────────┐
│ Step 1: Build Report Usage Inventory                     │
│ → Document which fields each visual uses               │
└────────────────┬────────────────────────────────────────┘
                 │
┌─────────────────▼────────────────────────────────────────┐
│ Step 2: Design AI Data Schema                            │
│ → INCLUDE: business fields Copilot should use          │
│ → EXCLUDE: technical/sensitive fields to hide          │
└────────────────┬────────────────────────────────────────┘
                 │
┌─────────────────▼────────────────────────────────────────┐
│ Step 3: Write AI Instructions                            │
│ → Terminology defaults, date rules, response format    │
└────────────────┬────────────────────────────────────────┘
                 │
┌─────────────────▼────────────────────────────────────────┐
│ Step 4: Design Answer Pack Visuals                       │
│ → Create pages & visuals for top questions             │
└────────────────┬────────────────────────────────────────┘
                 │
┌─────────────────▼────────────────────────────────────────┐
│ Step 5: Test & Refine                                    │
│ → Run test prompts, iterate on schema/instructions    │
└─────────────────────────────────────────────────────────┘
```

## Common Questions

**Q: Does this modify my report in place?**  
A: No. This skill generates **documentation** (markdown files) for your review. You then apply changes manually via Power BI UI or scripts.

**Q: Can I use this with PBIX files?**  
A: Yes, but export to PBIP first (`File > Save As` in Power BI Desktop) for detailed visual inspection.

**Q: How long does this take?**  
A: 2–4 hours for a typical report (30–50 visuals). Most time is spent designing the Answer Pack.

**Q: Do I need to know DAX?**  
A: No. This skill works with your existing measures. You'll review them—no coding required.

**Q: Can I publish this to my team?**  
A: Yes! All output files (markdown + scripts) are version-controlled. Commit to git and share.

## Documentation

- **[SKILL.md](SKILL.md)** — Full workflow, templates, troubleshooting, agent playbook
- **[Quick-Start Guide](docs/QUICKSTART.md)** — 1-page reference
- **Examples** — See `examples/` for sample outputs on real-world reports

## Support

- 📖 **Documentation:** See [SKILL.md](SKILL.md) for detailed workflow, templates, and troubleshooting
- 🐛 **Report Issues:** [GitHub Issues](https://github.com/YuriChadour/powerbi-agentic-plugins/issues)
- 💬 **Discussions:** [GitHub Discussions](https://github.com/YuriChadour/powerbi-agentic-plugins/discussions)
- 🤝 **Contributing:** See [CONTRIBUTING.md](CONTRIBUTING.md)

## Roadmap

- [ ] v1.1: Support for Real-time Intelligence (Eventhouses, KQL queries)
- [ ] v1.2: Automated Answer Pack visual generation (PBIR JSON templates)
- [ ] v1.3: Power BI Service integration (apply schema + instructions via REST API)
- [ ] v1.4: Multi-language support for AI instructions

## License

MIT License — See [LICENSE](LICENSE) for details.

## Credits

Built for Power BI developers who want Copilot to work reliably in production.

---

**Ready to optimize your reports?** Start with the [Quick-Start Guide](docs/QUICKSTART.md) or run `/skill prep-powerbi-for-report-copilot` in Copilot CLI.
