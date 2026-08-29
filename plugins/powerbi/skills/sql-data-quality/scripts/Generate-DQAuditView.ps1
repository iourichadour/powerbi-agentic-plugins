[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$CsvPath,

    [string[]]$TableFilter,

    [string]$Schema = 'dbo',

    [string]$OutFile,

    [switch]$Execute,

    [string]$ServerInstance,

    [string]$Database
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Quote-SqlIdentifier {
    param([Parameter(Mandatory = $true)][string]$Name)

    return '[' + $Name.Replace(']', ']]') + ']'
}

function Quote-SqlString {
    param([Parameter(Mandatory = $true)][string]$Value)

    return "N'" + $Value.Replace("'", "''") + "'"
}

function Get-SafeAlias {
    param([Parameter(Mandatory = $true)][string]$Value)

    $alias = $Value -replace '[^A-Za-z0-9_]', '_'
    $alias = $alias -replace '_+', '_'
    return $alias.Trim('_')
}

function Test-AllowBlank {
    param([string]$Value)

    return $Value -in @('1', 'true', 'True', 'TRUE', 'yes', 'Yes', 'YES')
}

function Get-FlagAlias {
    param([Parameter(Mandatory = $true)]$Rule)

    if (-not [string]::IsNullOrWhiteSpace([string]$Rule.ConditionSQL)) {
        return (Get-SafeAlias -Value ([string]$Rule.RuleId))
    }

    $column = Get-SafeAlias -Value ([string]$Rule.ColumnName)
    switch ([string]$Rule.RuleType) {
        'KeyNotBlank' { return "${column}_IsBlank" }
        'KeyUnique' { return "${column}_IsDuplicate" }
        'Duplicate' { return "${column}_IsDuplicate" }
        'TypeNumber' { return "${column}_IsInvalidNumber" }
        'TypeDate' { return "${column}_IsInvalidDate" }
        'Domain' { return "${column}_IsOutOfDomain" }
        'Range' { return "${column}_IsOutOfRange" }
        'RI' { return "${column}_IsMissingInDim" }
        'Custom' { return "${column}_IsCustomIssue" }
        default { return "${column}_Issue" }
    }
}

function Wrap-ConditionalExpression {
    param(
        [Parameter(Mandatory = $true)][string]$Expression,
        [string]$ConditionSql
    )

    if ([string]::IsNullOrWhiteSpace($ConditionSql)) {
        return $Expression
    }

    return "CASE WHEN ($ConditionSql) THEN $Expression ELSE 0 END"
}

function Get-FlagExpression {
    param([Parameter(Mandatory = $true)]$Rule)

    $columnName = [string]$Rule.ColumnName
    $columnRef = 'src.' + (Quote-SqlIdentifier -Name $columnName)
    $allowBlank = Test-AllowBlank -Value ([string]$Rule.AllowBlank)
    $nullResult = if ($allowBlank) { '0' } else { '1' }

    switch ([string]$Rule.RuleType) {
        'KeyNotBlank' {
            return "CASE WHEN $columnRef IS NULL OR LTRIM(RTRIM(CAST($columnRef AS NVARCHAR(MAX)))) = '' THEN $nullResult ELSE 0 END"
        }
        'KeyUnique' {
            return "CASE WHEN $columnRef IS NULL THEN $nullResult WHEN COUNT(*) OVER (PARTITION BY $columnRef) > 1 THEN 1 ELSE 0 END"
        }
        'Duplicate' {
            return "CASE WHEN $columnRef IS NULL THEN $nullResult WHEN COUNT(*) OVER (PARTITION BY $columnRef) > 1 THEN 1 ELSE 0 END"
        }
        'TypeNumber' {
            return "CASE WHEN $columnRef IS NULL THEN $nullResult WHEN TRY_CAST($columnRef AS FLOAT) IS NOT NULL THEN 0 ELSE 1 END"
        }
        'TypeDate' {
            return "CASE WHEN $columnRef IS NULL THEN $nullResult WHEN TRY_CAST($columnRef AS DATE) IS NOT NULL THEN 0 ELSE 1 END"
        }
        'Domain' {
            if ([string]::IsNullOrWhiteSpace([string]$Rule.AllowedValues)) {
                throw "Domain rule '$($Rule.RuleId)' is missing AllowedValues."
            }

            $allowedSql = ([string]$Rule.AllowedValues).Split('|') |
                Where-Object { -not [string]::IsNullOrWhiteSpace($_) } |
                ForEach-Object { Quote-SqlString -Value $_ }

            if ($allowedSql.Count -eq 0) {
                throw "Domain rule '$($Rule.RuleId)' has no usable AllowedValues."
            }

            return "CASE WHEN $columnRef IS NULL THEN $nullResult WHEN $columnRef IN ($($allowedSql -join ', ')) THEN 0 ELSE 1 END"
        }
        'Range' {
            $minValue = [string]$Rule.MinValue
            $maxValue = [string]$Rule.MaxValue
            if ([string]::IsNullOrWhiteSpace($minValue) -and [string]::IsNullOrWhiteSpace($maxValue)) {
                throw "Range rule '$($Rule.RuleId)' is missing MinValue and MaxValue."
            }

            if (-not [string]::IsNullOrWhiteSpace($minValue) -and -not [string]::IsNullOrWhiteSpace($maxValue)) {
                return "CASE WHEN $columnRef IS NULL THEN $nullResult WHEN TRY_CAST($columnRef AS FLOAT) BETWEEN $minValue AND $maxValue THEN 0 ELSE 1 END"
            }

            if (-not [string]::IsNullOrWhiteSpace($minValue)) {
                return "CASE WHEN $columnRef IS NULL THEN $nullResult WHEN TRY_CAST($columnRef AS FLOAT) >= $minValue THEN 0 ELSE 1 END"
            }

            return "CASE WHEN $columnRef IS NULL THEN $nullResult WHEN TRY_CAST($columnRef AS FLOAT) <= $maxValue THEN 0 ELSE 1 END"
        }
        'RI' {
            if ([string]::IsNullOrWhiteSpace([string]$Rule.RefTable) -or [string]::IsNullOrWhiteSpace([string]$Rule.RefColumn)) {
                throw "RI rule '$($Rule.RuleId)' is missing RefTable or RefColumn."
            }

            $refTable = (Quote-SqlIdentifier -Name $Schema) + '.' + (Quote-SqlIdentifier -Name ([string]$Rule.RefTable))
            $refColumn = Quote-SqlIdentifier -Name ([string]$Rule.RefColumn)
            return "CASE WHEN $columnRef IS NULL THEN $nullResult WHEN NOT EXISTS (SELECT 1 FROM $refTable AS ref WHERE ref.$refColumn = $columnRef) THEN 1 ELSE 0 END"
        }
        'Custom' {
            if ([string]::IsNullOrWhiteSpace([string]$Rule.ConditionSQL)) {
                throw "Custom rule '$($Rule.RuleId)' requires ConditionSQL as the failure predicate."
            }

            return "CASE WHEN ($([string]$Rule.ConditionSQL)) THEN 1 ELSE 0 END"
        }
        default {
            throw "Unsupported RuleType '$($Rule.RuleType)' in rule '$($Rule.RuleId)'."
        }
    }
}

$rules = Import-Csv -Path $CsvPath
if (-not $rules -or $rules.Count -eq 0) {
    throw "No rules found in $CsvPath."
}

if ($TableFilter -and $TableFilter.Count -gt 0) {
    $rules = $rules | Where-Object { $_.TableName -in $TableFilter }
}

if (-not $rules -or $rules.Count -eq 0) {
    throw 'No rules matched the requested table filter.'
}

$requiredColumns = 'RuleId','TableName','ColumnName','RuleType','ExpectedType','AllowBlank','MinValue','MaxValue','AllowedValues','RefTable','RefColumn','ConditionSQL','Severity','Notes'
foreach ($requiredColumn in $requiredColumns) {
    if ($rules[0].PSObject.Properties.Name -notcontains $requiredColumn) {
        throw "CSV is missing required column '$requiredColumn'."
    }
}

$viewStatements = New-Object System.Collections.Generic.List[string]

foreach ($tableGroup in ($rules | Group-Object TableName)) {
    $tableName = [string]$tableGroup.Name
    $orderedRules = $tableGroup.Group | Sort-Object ColumnName, RuleType, RuleId
    $flagEntries = New-Object System.Collections.Generic.List[object]

    foreach ($rule in $orderedRules) {
        $flagAlias = Get-FlagAlias -Rule $rule
        $rawExpression = Get-FlagExpression -Rule $rule
        $expression = Wrap-ConditionalExpression -Expression $rawExpression -ConditionSql ([string]$rule.ConditionSQL)
        $flagEntries.Add([pscustomobject]@{
            Rule = $rule
            Alias = $flagAlias
            Expression = $expression
            Severity = [string]$rule.Severity
        })
    }

    $duplicateAliases = $flagEntries | Group-Object Alias | Where-Object { $_.Count -gt 1 }
    foreach ($duplicateAlias in $duplicateAliases) {
        foreach ($entry in $duplicateAlias.Group) {
            $entry.Alias = Get-SafeAlias -Value ([string]$entry.Rule.RuleId)
        }
    }

    $flagSelectLines = $flagEntries |
        Group-Object Alias |
        ForEach-Object {
            $entry = $_.Group[0]
            "        {0} AS {1}" -f $entry.Expression, (Quote-SqlIdentifier -Name $entry.Alias)
        }

    $rowHasIssuesClauses = $flagEntries |
        Group-Object Alias |
        ForEach-Object { "[{0}] = 1" -f $_.Name }

    $errorClauses = $flagEntries |
        Where-Object { $_.Severity -eq 'Error' } |
        Group-Object Alias |
        ForEach-Object { "[{0}] = 1" -f $_.Name }

    $warnClauses = $flagEntries |
        Where-Object { $_.Severity -eq 'Warn' } |
        Group-Object Alias |
        ForEach-Object { "[{0}] = 1" -f $_.Name }

    $issueListClauses = $flagEntries |
        Group-Object Alias |
        ForEach-Object { "            CASE WHEN [{0}] = 1 THEN '; {0}' ELSE '' END" -f $_.Name }

    $viewName = (Quote-SqlIdentifier -Name $Schema) + '.' + (Quote-SqlIdentifier -Name ("${tableName}_DQ_Audit"))
    $sourceName = (Quote-SqlIdentifier -Name $Schema) + '.' + (Quote-SqlIdentifier -Name $tableName)

    $viewStatement = @"
CREATE OR ALTER VIEW $viewName AS
WITH Flags AS (
    SELECT
        src.*,
$($flagSelectLines -join ",`n")
    FROM $sourceName AS src
)
SELECT
    *,
    CASE WHEN $($rowHasIssuesClauses -join ' OR ') THEN 1 ELSE 0 END AS RowHasIssues,
    CASE
        WHEN $($errorClauses -join ' OR ') THEN 'Error'
        WHEN $($warnClauses -join ' OR ') THEN 'Warn'
        ELSE NULL
    END AS MaxSeverity,
    NULLIF(STUFF(
$($issueListClauses -join " +`n")
    , 1, 2, ''), '') AS IssueList
FROM Flags;
GO
"@

    $viewStatements.Add($viewStatement.Trim())
}

$finalSql = ($viewStatements -join "`r`n`r`n") + "`r`n"

if ([string]::IsNullOrWhiteSpace($OutFile)) {
    Write-Output $finalSql
}
else {
    $outputDirectory = Split-Path -Path $OutFile -Parent
    if ($outputDirectory) {
        New-Item -ItemType Directory -Path $outputDirectory -Force | Out-Null
    }

    Set-Content -Path $OutFile -Value $finalSql -Encoding UTF8
    Write-Host "Wrote audit view DDL to $OutFile"
}

if ($Execute) {
    if (-not $ServerInstance -or -not $Database) {
        throw 'Execute requires -ServerInstance and -Database.'
    }

    if (-not (Get-Command Invoke-Sqlcmd -ErrorAction SilentlyContinue)) {
        throw 'Invoke-Sqlcmd was not found. Install the SqlServer PowerShell module before using -Execute.'
    }

    Invoke-Sqlcmd -ServerInstance $ServerInstance -Database $Database -Query $finalSql | Out-Null
    Write-Host 'Executed generated DDL successfully.'
}
