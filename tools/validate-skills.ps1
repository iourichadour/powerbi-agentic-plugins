<#
.SYNOPSIS
    Validates SKILL.md and *.agent.md files across all plugins for required
    frontmatter fields and basic structural correctness.

.DESCRIPTION
    Scans plugins/**/skills/*/SKILL.md and plugins/**/agents/*.agent.md,
    checks each for required YAML frontmatter fields, and writes:
      - One Markdown report per file under tools/validation-reports/
      - A summary index at tools/validation-reports/_summary.md
      - A machine-readable tools/validation-reports/_summary.json

.PARAMETER PluginsRoot
    Root folder containing the plugins. Defaults to ../plugins relative to
    this script's location (i.e. repo-root/plugins).

.PARAMETER ReportsDir
    Folder to write reports into. Defaults to ./validation-reports relative
    to this script's location.

.EXAMPLE
    ./validate-skills.ps1
    Re-run anytime to re-validate and refresh all reports.
#>

[CmdletBinding()]
param(
    [string]$PluginsRoot = (Join-Path (Split-Path $PSScriptRoot -Parent) "plugins"),
    [string]$ReportsDir  = (Join-Path $PSScriptRoot "validation-reports")
)

if (-not (Test-Path $ReportsDir)) {
    New-Item -ItemType Directory -Path $ReportsDir -Force | Out-Null
}

function Get-Frontmatter {
    param([string]$Content)
    $lines = $Content -split "`r?`n"
    if ($lines.Count -lt 2 -or $lines[0].Trim() -ne '---') {
        return $null
    }
    $fmLines = @()
    $closeIndex = -1
    for ($i = 1; $i -lt $lines.Count; $i++) {
        if ($lines[$i].Trim() -eq '---') {
            $closeIndex = $i
            break
        }
        $fmLines += $lines[$i]
    }
    if ($closeIndex -eq -1) {
        return $null
    }
    return [PSCustomObject]@{
        Text       = ($fmLines -join "`n")
        Lines      = $fmLines
        BodyStart  = $closeIndex + 1
        AllLines   = $lines
    }
}

function Test-YamlFieldPresent {
    param([string[]]$FmLines, [string]$FieldName)
    foreach ($line in $FmLines) {
        if ($line -match "^\s{0,3}$FieldName\s*:") {
            return $true
        }
    }
    return $false
}

function Get-YamlFieldValue {
    param([string[]]$FmLines, [string]$FieldName)
    foreach ($line in $FmLines) {
        if ($line -match "^\s{0,3}$FieldName\s*:\s*(.*)$") {
            return $matches[1].Trim().Trim("'").Trim('"')
        }
    }
    return $null
}

function Get-BodyContent {
    param($Frontmatter)
    if (-not $Frontmatter) { return "" }
    $bodyLines = $Frontmatter.AllLines[$Frontmatter.BodyStart..($Frontmatter.AllLines.Count - 1)]
    return ($bodyLines -join "`n").Trim()
}

function Test-SkillFile {
    param([string]$Path)

    $content = Get-Content -Path $Path -Raw
    $fm = Get-Frontmatter $content
    $issues = @()

    if (-not $fm) {
        $issues += "No YAML frontmatter found (file must start with '---' and close with '---')"
        return [PSCustomObject]@{ Issues = $issues; Fields = @{} }
    }

    $name        = Get-YamlFieldValue $fm.Lines "name"
    $description = Get-YamlFieldValue $fm.Lines "description"
    $hasMetadata = Test-YamlFieldPresent $fm.Lines "metadata"
    $body        = Get-BodyContent $fm

    if (-not (Test-YamlFieldPresent $fm.Lines "name")) {
        $issues += "Missing required 'name' field in frontmatter"
    }
    if (-not (Test-YamlFieldPresent $fm.Lines "description")) {
        $issues += "Missing required 'description' field in frontmatter"
    }
    if ([string]::IsNullOrWhiteSpace($body)) {
        $issues += "No body content after frontmatter"
    }
    # name should match parent folder name (convention check)
    $folderName = Split-Path (Split-Path $Path -Parent) -Leaf
    if ($name -and $name -ne $folderName) {
        $issues += "Frontmatter 'name: $name' does not match parent folder name '$folderName'"
    }

    return [PSCustomObject]@{
        Issues = $issues
        Fields = @{
            name        = $name
            description = $description
            hasMetadata = $hasMetadata
        }
    }
}

function Test-AgentFile {
    param([string]$Path)

    $content = Get-Content -Path $Path -Raw
    $fm = Get-Frontmatter $content
    $issues = @()

    # Get-Content strips a UTF-8 byte order mark, so check the raw bytes. Claude Code
    # cannot parse frontmatter that does not start at byte 0, so the agent is not listed.
    $head = New-Object byte[] 3
    $stream = [System.IO.File]::OpenRead($Path)
    try { $read = $stream.Read($head, 0, 3) } finally { $stream.Dispose() }
    if ($read -ge 3 -and $head[0] -eq 0xEF -and $head[1] -eq 0xBB -and $head[2] -eq 0xBF) {
        $issues += "File starts with a UTF-8 byte order mark (EF BB BF); frontmatter must start at byte 0 so Claude Code can parse it"
    }

    if (-not $fm) {
        $issues += "No YAML frontmatter found (file must start with '---' and close with '---')"
        return [PSCustomObject]@{ Issues = $issues; Fields = @{} }
    }

    $name        = Get-YamlFieldValue $fm.Lines "name"
    $description = Get-YamlFieldValue $fm.Lines "description"
    $hasTools    = Test-YamlFieldPresent $fm.Lines "tools"
    $hasModel    = Test-YamlFieldPresent $fm.Lines "model"
    $body        = Get-BodyContent $fm

    if (-not (Test-YamlFieldPresent $fm.Lines "description")) {
        $issues += "Missing required 'description' field in frontmatter"
    }
    if (-not $hasTools) {
        $issues += "Missing 'tools' array in frontmatter"
    }
    if (-not $hasModel) {
        $issues += "Missing 'model' field in frontmatter"
    }
    if ([string]::IsNullOrWhiteSpace($body)) {
        $issues += "No body content (system prompt) after frontmatter"
    }

    return [PSCustomObject]@{
        Issues = $issues
        Fields = @{
            name        = $name
            description = $description
            hasTools    = $hasTools
            hasModel    = $hasModel
        }
    }
}

function Write-PerFileReport {
    param(
        [string]$ReportsDir,
        [string]$Type,
        [string]$LogicalName,
        [string]$SourcePath,
        [string[]]$Issues,
        [hashtable]$Fields
    )

    $status = if ($Issues.Count -eq 0) { "VALID" } else { "WARNING" }
    $safeName = ($LogicalName -replace '[^a-zA-Z0-9_.-]', '_')
    $reportPath = Join-Path $ReportsDir "$Type-$safeName.md"

    $lines = @()
    $lines += "# Validation Report: $LogicalName"
    $lines += ""
    $lines += "- **Type**: $Type"
    $lines += "- **Status**: $status"
    $lines += "- **Source**: ``$SourcePath``"
    $lines += "- **Checked**: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
    $lines += ""
    $lines += "## Fields detected"
    $lines += ""
    foreach ($key in $Fields.Keys) {
        $lines += "- **$key**: $($Fields[$key])"
    }
    $lines += ""
    $lines += "## Issues"
    $lines += ""
    if ($Issues.Count -eq 0) {
        $lines += "None. This file passed all checks."
    } else {
        foreach ($issue in $Issues) {
            $lines += "- $issue"
        }
    }
    $lines += ""

    Set-Content -Path $reportPath -Value ($lines -join "`n") -Encoding utf8
    return [PSCustomObject]@{
        Path   = $reportPath
        Status = $status
    }
}

function Get-TriggerPhrasesFromSkill {
    param([string]$Path)
    $text = (Get-Content -Path $Path -Raw) -replace "`r", ""
    $m = [regex]::Match($text, '## Step 2.*?\*\*Trigger phrases\*\*[^\n]*\n(?:[^\n]*\n)*?(?<list>(?:- "[^"\n]+"\n)+)', 'Singleline')
    if (-not $m.Success) { return $null }
    return @([regex]::Matches($m.Groups['list'].Value, '- "([^"\n]+)"') | ForEach-Object { $_.Groups[1].Value })
}

function Get-TriggerPhrasesFromAgent {
    param([string]$Path)
    # Agent files wrap the list across lines, so collapse whitespace before matching.
    $text = (Get-Content -Path $Path -Raw) -replace '\s+', ' '
    $m = [regex]::Match($text, 'trigger list documented in `jira-workflow` Step 2 \((?<list>[^)]*)\)')
    if (-not $m.Success) { return $null }
    return @([regex]::Matches($m.Groups['list'].Value, '"([^"]+)"') | ForEach-Object { $_.Groups[1].Value })
}

# Checks that the devops persona agent's three dialects and the jira-workflow skill list the same
# start-ticket trigger phrases, and that "work on <KEY>" is among them. Returns a list of problems.
function Test-DevopsTriggerParity {
    param([string]$PluginsRoot)

    $devopsRoot = Join-Path $PluginsRoot "devops"
    $sources = [ordered]@{
        "jira-workflow SKILL.md" = @{ Path = Join-Path $devopsRoot "skills/jira-workflow/SKILL.md"; Reader = "skill" }
        "devops.md"              = @{ Path = Join-Path $devopsRoot "agents/devops.md";               Reader = "agent" }
        "devops.agent.md"        = @{ Path = Join-Path $devopsRoot "agents/devops.agent.md";         Reader = "agent" }
        "devops.toml"            = @{ Path = Join-Path $devopsRoot "agents/devops.toml";             Reader = "agent" }
    }

    $problems = @()
    $lists = @{}
    foreach ($label in $sources.Keys) {
        $src = $sources[$label]
        if (-not (Test-Path $src.Path)) {
            $problems += "${label}: file not found at $($src.Path)"
            continue
        }
        $phrases = if ($src.Reader -eq "skill") { Get-TriggerPhrasesFromSkill $src.Path } else { Get-TriggerPhrasesFromAgent $src.Path }
        if ($null -eq $phrases -or $phrases.Count -eq 0) {
            $problems += "${label}: could not find the start-ticket trigger phrase list"
            continue
        }
        $lists[$label] = $phrases
        if ($phrases -notcontains 'work on <KEY>') {
            $problems += "${label}: missing start-ticket phrase 'work on <KEY>'"
        }
    }

    $union = @($lists.Values | ForEach-Object { $_ } | Sort-Object -Unique)
    foreach ($label in $lists.Keys) {
        foreach ($phrase in $union) {
            if ($lists[$label] -notcontains $phrase -and $phrase -ne 'work on <KEY>') {
                $problems += "${label}: missing start-ticket phrase '$phrase' that another file lists"
            }
        }
    }
    return $problems
}

# --- Main ---

$skillFiles = Get-ChildItem -Path $PluginsRoot -Filter "SKILL.md" -Recurse -ErrorAction SilentlyContinue
# Agent files: any *.md inside a top-level `plugins/<plugin>/agents/` folder
# (Claude Code style), plus legacy *.agent.md anywhere (Copilot style). Nested
# skills/*/agents/ prompt fragments are not plugin agents and are skipped.
$agentFiles = Get-ChildItem -Path $PluginsRoot -Filter "*.md" -Recurse -ErrorAction SilentlyContinue |
    Where-Object {
        ($_.Directory.Name -eq "agents" -and $_.Directory.Parent.Parent.Name -eq (Split-Path $PluginsRoot -Leaf)) `
            -or $_.Name -like "*.agent.md"
    } |
    Sort-Object FullName -Unique

$summary = @()

Write-Host "=== Validating SKILL.md files ===" -ForegroundColor Cyan
foreach ($file in $skillFiles) {
    $skillName = Split-Path (Split-Path $file.FullName -Parent) -Leaf
    $result = Test-SkillFile -Path $file.FullName
    $report = Write-PerFileReport -ReportsDir $ReportsDir -Type "skill" -LogicalName $skillName `
        -SourcePath $file.FullName -Issues $result.Issues -Fields $result.Fields

    $icon = if ($report.Status -eq "VALID") { "[OK]" } else { "[!!]" }
    Write-Host "$icon $skillName"
    if ($result.Issues.Count -gt 0) {
        $result.Issues | ForEach-Object { Write-Host "     - $_" -ForegroundColor Yellow }
    }

    $summary += [PSCustomObject]@{
        Type       = "skill"
        Name       = $skillName
        Status     = $report.Status
        IssueCount = $result.Issues.Count
        Issues     = $result.Issues
        SourcePath = $file.FullName
        ReportPath = $report.Path
    }
}

Write-Host "`n=== Validating *.agent.md files ===" -ForegroundColor Cyan
foreach ($file in $agentFiles) {
    $agentName = ([IO.Path]::GetFileNameWithoutExtension($file.Name)) -replace '\.agent$', ''
    $result = Test-AgentFile -Path $file.FullName
    $report = Write-PerFileReport -ReportsDir $ReportsDir -Type "agent" -LogicalName $agentName `
        -SourcePath $file.FullName -Issues $result.Issues -Fields $result.Fields

    $icon = if ($report.Status -eq "VALID") { "[OK]" } else { "[!!]" }
    Write-Host "$icon $agentName"
    if ($result.Issues.Count -gt 0) {
        $result.Issues | ForEach-Object { Write-Host "     - $_" -ForegroundColor Yellow }
    }

    $summary += [PSCustomObject]@{
        Type       = "agent"
        Name       = $agentName
        Status     = $report.Status
        IssueCount = $result.Issues.Count
        Issues     = $result.Issues
        SourcePath = $file.FullName
        ReportPath = $report.Path
    }
}

# Hard failures make the script exit non-zero: a byte order mark stops Claude Code from loading
# the agent, and trigger-phrase drift stops "work on <KEY>" from reaching jira-workflow.
$hardFailures = @()
foreach ($item in $summary | Where-Object { $_.Type -eq "agent" }) {
    foreach ($issue in $item.Issues) {
        if ($issue -like "*byte order mark*") { $hardFailures += "$($item.SourcePath): $issue" }
    }
}

Write-Host "`n=== Checking devops start-ticket trigger-phrase parity ===" -ForegroundColor Cyan
if (Test-Path (Join-Path $PluginsRoot "devops")) {
    $parityProblems = Test-DevopsTriggerParity -PluginsRoot $PluginsRoot
    if ($parityProblems.Count -eq 0) {
        Write-Host "[OK] devops.md, devops.agent.md, devops.toml and jira-workflow SKILL.md list the same trigger phrases, including 'work on <KEY>'"
    } else {
        foreach ($problem in $parityProblems) {
            Write-Host "[!!] $problem" -ForegroundColor Red
            $hardFailures += "Trigger-phrase parity: $problem"
        }
    }
} else {
    Write-Host "[--] No devops plugin under $PluginsRoot; skipped"
}

# Summary index (Markdown)
$summaryMdPath = Join-Path $ReportsDir "_summary.md"
$validCount   = ($summary | Where-Object { $_.Status -eq "VALID" }).Count
$warningCount = ($summary | Where-Object { $_.Status -eq "WARNING" }).Count

$mdLines = @()
$mdLines += "# Skill & Agent Validation Summary"
$mdLines += ""
$mdLines += "Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
$mdLines += ""
$mdLines += "- Total files checked: $($summary.Count)"
$mdLines += "- Valid: $validCount"
$mdLines += "- Warnings: $warningCount"
$mdLines += ""
$mdLines += "| Type | Name | Status | Issues | Report |"
$mdLines += "|------|------|--------|--------|--------|"
foreach ($item in $summary | Sort-Object Type, Name) {
    $reportRel = Split-Path $item.ReportPath -Leaf
    $mdLines += "| $($item.Type) | $($item.Name) | $($item.Status) | $($item.IssueCount) | [$reportRel]($reportRel) |"
}
Set-Content -Path $summaryMdPath -Value ($mdLines -join "`n") -Encoding utf8

# Summary index (JSON, machine-readable for future diffing)
$summaryJsonPath = Join-Path $ReportsDir "_summary.json"
$summary | ConvertTo-Json -Depth 4 | Set-Content -Path $summaryJsonPath -Encoding utf8

Write-Host "`n=== SUMMARY ===" -ForegroundColor Cyan
Write-Host "Total: $($summary.Count)  Valid: $validCount  Warnings: $warningCount"
Write-Host "Per-file reports: $ReportsDir"
Write-Host "Summary index: $summaryMdPath"

if ($hardFailures.Count -gt 0) {
    Write-Host "`nFAILED: $($hardFailures.Count) blocking problem(s)" -ForegroundColor Red
    $hardFailures | ForEach-Object { Write-Host "  - $_" -ForegroundColor Red }
    exit 1
}
