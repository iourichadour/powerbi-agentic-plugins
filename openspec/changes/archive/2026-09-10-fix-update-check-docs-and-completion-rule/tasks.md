## 1. Fix AGENTS.md update-check reference

- [x] 1.1 Update the "Update Check" note in `AGENTS.md` to read version from `.claude-plugin/marketplace.json` (`metadata.version`) in `YuriChadour/powerbi-agentic-plugins` instead of a root `package.json`, and verify the note no longer mentions `package.json`

## 2. Fix check-updates skill manifest guidance

- [x] 2.1 Rewrite `plugins/powerbi/skills/check-updates/SKILL.md` Step 1 (Get Local Version) to read from `.claude-plugin/marketplace.json` (repo-level `metadata.version` and/or the relevant plugin's `version` entry) instead of `.github/plugin/plugin.json` or root `package.json`, and verify the described path exists in this repo
- [x] 2.2 Rewrite Step 2 (Determine Repository Owner and Name) to read the repository from this repo's actual metadata source, defaulting to `YuriChadour/powerbi-agentic-plugins` when no separate `repository` field is present, removing the two-layout (`plugin.json` vs `package.json`) parsing guidance that no longer applies
- [x] 2.3 Update Step 3 (Fetch Latest Release) Methods A/B/C examples (`git show origin/main:package.json`, `get_file_contents(... path: "package.json")`, releases API) to fetch `.claude-plugin/marketplace.json` from `YuriChadour/powerbi-agentic-plugins` and verify each method's example command/path is consistent with Step 1
- [x] 2.4 Update the Reference section's GitHub Repository/Releases/CHANGELOG links from `microsoft/skills-for-fabric` to `YuriChadour/powerbi-agentic-plugins`, and confirm no remaining mentions of `skills-for-fabric` manifest paths survive a search of the file

## 3. Add task-completion validation rule to powerbi-developer agent

- [x] 3.1 Add an explicit step to the "Implementing a spec" section of `plugins/powerbi/agents/powerbi-developer.agent.md` requiring the agent to validate each task's output against that task's acceptance criteria (or the corresponding spec requirement/scenario) before marking it done, and to leave it unchecked with a reported gap otherwise
- [x] 3.2 Re-read the updated section and verify the new rule sits between task execution and marking done, matching `specs/powerbi/powerbi-developer-agent-completion/spec.md`'s three scenarios (pass / fail / cannot evaluate)

## 4. Verification

- [x] 4.1 Grep the three edited files for stale references (`package.json`, `.github/plugin/plugin.json`, `skills-for-fabric`, `microsoft/skills-for-fabric`) outside of explanatory "not X" phrasing, and confirm the update-check documents are internally consistent with `.claude-plugin/marketplace.json`
