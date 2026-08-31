<#
.SYNOPSIS
    Run skill-evaluator against every skill under a plugins directory and
    write one markdown (+ JSON) evaluation report per skill.

.EXAMPLE
    .\run-skill-eval.ps1
    .\run-skill-eval.ps1 -PluginsDir C:\Development\powerbi-agentic-plugins\plugins -Mode full
    .\run-skill-eval.ps1 -Mode security -OutDir .\reports
#>
[CmdletBinding()]
param(
    [string]$PluginsDir  = 'C:\Development\powerbi-agentic-plugins\plugins',
    [string]$EvaluatorDir = 'C:\Development\skill-evaluator\skill-evaluator\scripts',
    [string]$OutDir       = (Join-Path $PSScriptRoot 'reports'),
    [ValidateSet('full','security','pre-publish')]
    [string]$Mode         = 'full'
)

$ErrorActionPreference = 'Stop'
$env:PYTHONIOENCODING = 'utf-8'

$evalScript = Join-Path $EvaluatorDir 'evaluate_skill.py'
if (-not (Test-Path $evalScript)) { throw "evaluate_skill.py not found at $evalScript" }
if (-not (Test-Path $PluginsDir))  { throw "Plugins dir not found: $PluginsDir" }
New-Item -ItemType Directory -Force -Path $OutDir | Out-Null

# Each skill is the directory that directly contains a SKILL.md
$skillDirs = Get-ChildItem -Path $PluginsDir -Recurse -Filter 'SKILL.md' -File |
    Select-Object -ExpandProperty DirectoryName -Unique | Sort-Object

if (-not $skillDirs) { throw "No SKILL.md files found under $PluginsDir" }

$rows = @()
foreach ($dir in $skillDirs) {
    # plugin = path segment right after '\plugins\'; skill = leaf folder name
    $rel     = $dir.Substring($PluginsDir.Length).TrimStart('\','/')
    $plugin  = ($rel -split '[\\/]')[0]
    $skill   = Split-Path $dir -Leaf
    $stem    = "${plugin}__${skill}"
    $mdPath  = Join-Path $OutDir "$stem.md"
    $jsonPath = Join-Path $OutDir "$stem.json"

    Write-Host ">>> $plugin/$skill" -ForegroundColor Cyan
    & python $evalScript --mode $Mode -o $mdPath --json $jsonPath $dir
    # evaluate_skill.py exits 1/2 for DO NOT INSTALL / USE WITH CAUTION -- not a script failure
    if (-not (Test-Path $jsonPath)) { Write-Warning "No JSON produced for $plugin/$skill"; continue }

    $r = Get-Content $jsonPath -Raw | ConvertFrom-Json
    $o = $r.overall
    $rows += [pscustomobject]@{
        Skill          = "$plugin/$skill"
        Overall        = $o.overall_score
        Security       = $o.breakdown.security
        Quality        = [math]::Round([double]$o.breakdown.quality, 1)
        Utility        = $o.breakdown.utility
        Compliance     = $o.breakdown.compliance
        Risk           = $o.risk_level
        Recommendation = $o.recommendation
    }
}

$rows = $rows | Sort-Object Overall -Descending
$rows | Format-Table -AutoSize

# Write a combined summary table
$summary = Join-Path $OutDir 'SUMMARY.md'
$sb = [System.Text.StringBuilder]::new()
[void]$sb.AppendLine('# Skill Evaluation Summary')
[void]$sb.AppendLine('')
[void]$sb.AppendLine("Tool: skill-evaluator | Target: $PluginsDir | Mode: $Mode | Date: $(Get-Date -Format yyyy-MM-dd)")
[void]$sb.AppendLine('')
[void]$sb.AppendLine('| Plugin / Skill | Overall | Sec | Qual | Util | Comp | Risk | Recommendation |')
[void]$sb.AppendLine('|---|--:|--:|--:|--:|--:|---|---|')
foreach ($x in $rows) {
    [void]$sb.AppendLine("| $($x.Skill) | $($x.Overall) | $($x.Security) | $($x.Quality) | $($x.Utility) | $($x.Compliance) | $($x.Risk) | $($x.Recommendation) |")
}
Set-Content -Path $summary -Value $sb.ToString() -Encoding utf8
Write-Host "`nReports written to $OutDir (see SUMMARY.md)" -ForegroundColor Green

# evaluate_skill.py sets non-zero exit codes per-skill (1 = DO NOT INSTALL, 2 = caution);
# reset so a completed run reports success.
exit 0
