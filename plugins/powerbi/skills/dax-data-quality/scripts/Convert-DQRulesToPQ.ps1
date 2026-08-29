
<#
.SYNOPSIS
    Converts a DQ rules CSV file into an inline Power Query M JSON string.

.DESCRIPTION
    Reads the dq_rules CSV (using the schema defined in documents/dq_rules.generated.csv),
    builds a JSON object, and outputs the full Power Query block ready to paste into
    the Advanced Editor as the DQ_Rules query.

    The output uses double-quote escaping (") required inside M text literals.

.PARAMETER CsvPath
    Path to the DQ rules CSV file.
    Defaults to <repo-root>\documents\dq_rules.generated.csv

.PARAMETER OutFile
    Optional. If provided, the generated M query is written to this file
    instead of (or in addition to) stdout.

.PARAMETER TableFilter
    Optional. Comma-separated list of TableName values to include.
    If omitted, all tables are included.
    Example: -TableFilter "FactLoan,DimProperty"

.EXAMPLE
    # Print to console
    .\Convert-DQRulesToPQ.ps1

    # Filter to one table and save to file
    .\Convert-DQRulesToPQ.ps1 -TableFilter "FactLoan" -OutFile ".\dq_rules_query.pq"
#>

[CmdletBinding()]
param(
    [string] $CsvPath    = "",
    [string] $OutFile    = "",
    [string] $TableFilter = ""
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# ── 1. Load CSV ────────────────────────────────────────────────────────────────
# Resolve default CSV path relative to this script file's real location
if ($CsvPath -eq "") {
    $scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
    $CsvPath   = Join-Path $scriptDir "..\..\..\..\documents\dq_rules.generated.csv"
    $CsvPath   = [System.IO.Path]::GetFullPath($CsvPath)
}

if (-not (Test-Path $CsvPath)) {
    Write-Error "CSV not found: $CsvPath"
    exit 1
}

$rules = Import-Csv -Path $CsvPath

# Optionally filter to specific tables
if ($TableFilter -ne "") {
    $tables = $TableFilter -split "," | ForEach-Object { $_.Trim() }
    $rules = $rules | Where-Object { $tables -contains $_.TableName }
}

if ($rules.Count -eq 0) {
    Write-Error "No rules found after filtering. Check -TableFilter or the CSV path."
    exit 1
}

# ── 2. Helper: convert CSV row → JSON object string ───────────────────────────
function ConvertTo-RuleJson {
    param($rule, [int]$index)

    # Normalize nulls: blank strings → JSON null
    function jVal([string]$v) {
        if ([string]::IsNullOrWhiteSpace($v)) { return "null" }
        return "`"$($v.Trim())`""
    }

    function jNum([string]$v) {
        if ([string]::IsNullOrWhiteSpace($v)) { return "null" }
        return $v.Trim()
    }

    function jBool([string]$v) {
        if ($v.Trim().ToUpper() -eq "TRUE") { return "true" } else { return "false" }
    }

    $id          = $index + 1
    $ruleId      = $rule.RuleId.Trim()
    $tableName   = $rule.TableName.Trim()
    $columnName  = $rule.ColumnName.Trim()
    $ruleType    = $rule.RuleType.Trim()
    $expectedType= $rule.ExpectedType.Trim()
    $allowBlank  = jBool $rule.AllowBlank
    $minValue    = jNum  $rule.MinValue
    $maxValue    = jNum  $rule.MaxValue
    $allowed     = jVal  $rule.AllowedValues
    $refTable    = jVal  $rule.RefTable
    $refColumn   = jVal  $rule.RefColumn
    # NOTE: In the generated CSV the Severity column holds the rule description
    # and ConditionDAX holds the High/Medium/Low severity level (column alignment artifact)
    $severity    = jVal  $rule.ConditionDAX
    $notes       = jVal  $rule.Severity

    return @"
        {
          "id": $id, "rule_id": "$ruleId",
          "table_name": "$tableName", "column_name": "$columnName",
          "rule_type": "$ruleType", "expected_type": "$expectedType",
          "allow_blank": $allowBlank,
          "min_value": $minValue, "max_value": $maxValue,
          "allowed_values": $allowed,
          "ref_table": $refTable, "ref_column": $refColumn,
          "severity": $severity, "notes": $notes
        }
"@
}

# ── 3. Build the JSON object string ───────────────────────────────────────────
$ruleJsonItems = @()
for ($i = 0; $i -lt $rules.Count; $i++) {
    $ruleJsonItems += (ConvertTo-RuleJson $rules[$i] $i)
}

$rulesArray = $ruleJsonItems -join ","

# Pretty JSON block (standard double-quotes — NOT yet M-escaped)
$jsonBlock = @"
{
  "dq_rules": [
$rulesArray
  ]
}
"@

# ── 4. M-escape: replace every " with "" ──────────────────────────────────────
# The outer " in the M text literal is handled by wrapping in "..." further below.
# Every embedded " must become "" for M to treat it as a literal quote.
$mEscaped = $jsonBlock.Replace('"', '""')

# ── 5. Wrap in the complete M query ───────────────────────────────────────────
$mQuery = @"
let
  RawJson =
    "$mEscaped",
  Source = Json.Document(Text.ToBinary(RawJson)),
  Rules  = Table.FromRecords(Source[dq_rules])
in
  Rules
"@

# ── 6. Output ──────────────────────────────────────────────────────────────────
Write-Output $mQuery

if ($OutFile -ne "") {
    $mQuery | Set-Content -Path $OutFile -Encoding UTF8
    Write-Host "`nSaved to: $((Resolve-Path $OutFile).Path)" -ForegroundColor Green
}
