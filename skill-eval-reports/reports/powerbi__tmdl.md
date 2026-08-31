# Skill Evaluation Report

**Skill Name:** `tmdl`
**Evaluation Date:** 2026-08-29 01:14:50
**Evaluator Version:** 1.2.3

---

## Executive Summary

### Overall Score: 80.2/100

**Recommendation:** ❌ DO NOT INSTALL - Critical security risks

**Risk Level:** Critical

### Score Breakdown

| Dimension | Score | Weight |
|-----------|-------|--------|
| **Security** | 48.0/100 | 35% |
| **Quality** | 93.7224880382775/100 | 25% |
| **Utility** | 100.0/100 | 20% |
| **Compliance** | 100.0/100 | 20% |
| **Overall** | **80.2/100** | **100%** |

### Key Findings

- ✅ **Excellent code quality** and documentation
- ✅ **Fully compliant** with skill-creator guidelines
- **Overall Recommendation:** ❌ DO NOT INSTALL - Critical security risks

---

## Detailed Analysis

### 1. Security Analysis

**Score:** 48.0/100
**Risk Level:** Critical

#### Vulnerabilities Found

#### Medium-Risk Issues (9 found)

- Path Traversal and other issues found. Review security report for details.


#### Security Strengths

- Limited security issues detected

#### Security Recommendations


**General Recommendations:**
- Review all flagged security issues
- Implement input validation and sanitization
- Follow principle of least privilege

---

### 2. Quality Assessment

**Score:** 93.7224880382775/100

#### Breakdown
- **Code Quality:** 23.72248803827751/25
- **Documentation:** 20.0/25
- **Structure & Organization:** 25.0/25
- **Functionality:** 25.0/25

#### Strengths

- Clean, well-structured code
- Comprehensive documentation
- Proper directory organization
- Functional and practical implementation

#### Weaknesses

- No major quality weaknesses identified

#### Quality Recommendations

- Maintain current quality standards

---

### 3. Utility Evaluation

**Score:** 100.0/100

#### Breakdown
- **Problem-Solving Value:** 25.0/25
- **Usability:** 25.0/25
- **Scope Appropriateness:** 25.0/25
- **Effectiveness:** 25.0/25

#### Value Assessment

This skill provides excellent practical value and solves real problems effectively.

#### Use Cases

- Refer to SKILL.md for documented use cases
- Suitable for intended purpose as described

#### Limitations

- Static analysis only (no runtime testing)
- Pattern-based detection may have false positives/negatives

#### Utility Recommendations

- Consider additional features to expand utility
- Gather user feedback for improvements

---

### 4. Compliance Validation

**Score:** 100.0/100

#### Standards Met

✓ SKILL.md exists
✓ YAML frontmatter present
✓ Name field present
✓ Description field present
✓ Name matches directory
✓ Scripts directory exists
✓ References directory exists

#### Violations Found

No compliance violations detected.

#### Progressive Disclosure Assessment

Skill follows progressive disclosure principles with appropriate separation of metadata, instructions, and bundled resources.

#### Writing Style Review

Writing style follows imperative/infinitive form guidelines.

#### Compliance Recommendations

- Maintain compliance with skill-creator guidelines
- Keep structure and documentation up to date

---

## Overall Recommendations

### Priority Fixes

No critical fixes required.

### Suggested Improvements

- Review and address all flagged issues
- Enhance documentation with more examples
- Follow security and quality best practices
- Test thoroughly before distribution

### Best Practices to Adopt

- Use subprocess with list arguments (not shell=True)
- Validate and sanitize all inputs
- Implement proper error handling
- Write clear, imperative-form documentation
- Follow progressive disclosure design
- Use appropriate bundled resources (scripts, references, assets)

---

## Conclusion

This skill has critical issues that must be addressed before it can be safely used or distributed. Do not install until security and compliance issues are resolved.

---

## ⚠️ Important Disclaimers

**READ CAREFULLY BEFORE ACTING ON THIS EVALUATION**

### No Guarantee of Safety

This evaluation **CANNOT determine with certainty that a skill is safe.** Security analysis has inherent limitations:

- **Cannot prove absence of vulnerabilities** - Static analysis detects known patterns but cannot prove a skill is vulnerability-free
- **False negatives are possible** - Novel attacks, obfuscated code, or sophisticated malicious techniques may evade detection
- **Static analysis limitations** - Cannot assess runtime behavior, dynamic execution, or context-dependent security risks
- **Time-bound assessment** - New vulnerabilities may be discovered after this evaluation was performed

### Use as ONE Input Only

**This evaluation should be used as ONE input into your security decision, not the sole determining factor.**

### Your Responsibilities

Before installing ANY skill, regardless of evaluation score:

1. **Manual code review** - Read and understand the skill's code yourself
2. **Test in isolation** - Run in sandboxed or test environments before production use
3. **Follow organizational policies** - Security policies override any recommendation in this report
4. **Assess your risk** - Consider your specific threat model, data sensitivity, and risk tolerance
5. **Monitor ongoing** - Continue monitoring skill behavior after installation

### You Are Responsible

- **YOU are responsible for skills you install** - Not this evaluator, not the skill author
- **Security policies take precedence** - If your organization prohibits certain actions, this report doesn't override that
- **"HIGHLY RECOMMENDED" ≠ "SAFE"** - Even top-scoring skills require review and may contain undiscovered vulnerabilities
- **When uncertain, consult experts** - If unsure about a skill's safety, seek guidance from security professionals

### Limitations of This Analysis

This tool performs **pattern-based static code analysis** with known limitations:

**✅ Can Detect:**
- Common vulnerability patterns (injection, traversal, etc.)
- Structural and organizational issues
- Compliance violations with skill-creator guidelines
- Code quality and documentation problems

**❌ Cannot Detect:**
- Zero-day exploits or novel attack vectors
- Logic bombs or time-delayed malicious behavior
- Social engineering or supply chain attacks
- Backdoors triggered by specific conditions
- Malicious intent disguised as legitimate functionality

**❌ Cannot Assess:**
- Author trustworthiness or reputation
- Long-term maintenance and support
- Runtime performance or behavior
- Compatibility with your specific environment

### Legal Disclaimer

**NO WARRANTIES**: This evaluation is provided "as-is" without warranties of any kind, express or implied. The authors and contributors of this tool assume NO LIABILITY for any damages, losses, security breaches, or other consequences resulting from:

- Use of this evaluation tool
- Reliance on evaluation results
- Installation of evaluated skills
- Any actions taken based on this report

**USE AT YOUR OWN RISK**: By using this evaluation, you acknowledge and accept all risks associated with skill installation and use.


---

*Report generated by skill-evaluator v1.2.3*
