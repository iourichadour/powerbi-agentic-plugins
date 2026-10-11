# Contributing to prep-powerbi-for-report-copilot

Thank you for your interest in contributing! This document outlines how to contribute to this project.

## Code of Conduct

- Be respectful and constructive
- Help others learn and grow
- Report issues privately if they're security-related

## Ways to Contribute

### 1. Report Bugs
- Check existing [Issues](https://github.com/YuriChadour/powerbi-agentic-plugins/issues) first
- Provide:
  - Clear description of the problem
  - Steps to reproduce
  - Expected vs. actual behavior
  - Your environment (PowerShell version, OS, Power BI version)
  - Example files (anonymized if needed)

### 2. Suggest Features
- Describe the use case clearly
- Include examples of how it would work
- Explain the benefit to other users

### 3. Improve Documentation
- Fix typos, unclear sections
- Add examples or clarifications
- Translate documentation (future)

### 4. Submit Code Changes

#### Setup Development Environment
```powershell
# Clone the repo
git clone https://github.com/bayviewasset/prep-powerbi-for-report-copilot.git
cd prep-powerbi-for-report-copilot

# Create feature branch
git checkout -b feature/your-feature-name

# Test your changes
.\scripts\Generate-AISchema.ps1 -SemanticModelPath "test_data" -OutputPath "test_output.csv"
```

#### Code Standards
- **PowerShell:**
  - Use `-Verbose`, `-ErrorAction` for reliability
  - Add comments for non-obvious logic
  - Follow [PoshCode style guide](https://poshcode.gitbooks.io/powershell-practice-and-style/)
  
- **Python:**
  - Follow PEP 8
  - Use type hints
  - Test with Python 3.8+

- **Markdown:**
  - Use ATX headers (# not ===)
  - Keep lines <100 characters for readability
  - Use tables for structured data

#### Testing
- Test on Windows (PowerShell 7+ and Windows PowerShell)
- Test with PBIP and PBIX formats if applicable
- Verify no hardcoded paths or credentials

#### Commit Messages
Follow conventional commits:
```
type(scope): description

body (optional)
footer (optional)
```

Examples:
```
feat(schema): add FK column detection from relationships.tmdl
fix(installer): handle UNC paths correctly
docs(quickstart): clarify Python 3.8+ requirement
```

#### Pull Request Process
1. Fork the repo
2. Create feature branch (`git checkout -b feature/xyz`)
3. Make changes with clear commits
4. Test thoroughly
5. Open PR with:
   - Clear description of changes
   - Link to related issue (if applicable)
   - Checklist of what you tested
6. Address review feedback
7. Merge after approval

#### PR Checklist
```markdown
- [ ] Tests pass (manual: run scripts with test data)
- [ ] No hardcoded paths or credentials
- [ ] Documentation updated if needed
- [ ] Commits are well-described
- [ ] Compatible with PowerShell 7+ and Windows PowerShell
```

### 5. Share Examples
- Document your workflow using this skill
- Share before/after results (anonymized)
- Post in [Discussions](https://github.com/YuriChadour/powerbi-agentic-plugins/discussions)

## Roadmap

Planned features:
- [ ] Real-time Intelligence (Eventhouse) support
- [ ] Automated Answer Pack visual generation
- [ ] Power BI Service REST API integration
- [ ] Multi-language AI instructions

If you're interested in any of these, please comment on [Discussions](https://github.com/YuriChadour/powerbi-agentic-plugins/discussions).

## Questions?

- 📖 See [SKILL.md](SKILL.md) for detailed workflow
- 💬 Open a [Discussion](https://github.com/YuriChadour/powerbi-agentic-plugins/discussions) for questions
- 🐛 Open an [Issue](https://github.com/YuriChadour/powerbi-agentic-plugins/issues) for bugs

---

**Thank you for making this skill better!**
