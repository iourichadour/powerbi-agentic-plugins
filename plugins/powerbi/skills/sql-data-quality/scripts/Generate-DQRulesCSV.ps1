[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$ServerInstance,

    [Parameter(Mandatory = $true)]
    [string]$Database,

    [Parameter(Mandatory = $true)]
    [string[]]$TableName,

    [string]$Schema = 'dbo',

    [string]$OutFile = 'documents/dq_rules.generated.csv'
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Quote-SqlLiteral {
    param([Parameter(Mandatory = $true)][string]$Value)

    return "'" + $Value.Replace("'", "''") + "'"
}

function Get-ExpectedType {
    param([Parameter(Mandatory = $true)][string]$SqlType)

    switch -Regex ($SqlType.ToLowerInvariant()) {
        'bit' { return 'Boolean' }
        'date|datetime|datetime2|smalldatetime|datetimeoffset|time' { return 'Date' }
        'int|bigint|smallint|tinyint|decimal|numeric|float|real|money|smallmoney' { return 'Number' }
        default { return 'Text' }
    }
}

function New-Rule {
    param(
        [Parameter(Mandatory = $true)][string]$RuleId,
        [Parameter(Mandatory = $true)][string]$TableName,
        [Parameter(Mandatory = $true)][string]$ColumnName,
        [Parameter(Mandatory = $true)][string]$RuleType,
        [string]$ExpectedType = '',
        [string]$AllowBlank = '',
        [string]$MinValue = '',
        [string]$MaxValue = '',
        [string]$AllowedValues = '',
        [string]$RefTable = '',
        [string]$RefColumn = '',
        [string]$ConditionSQL = '',
        [Parameter(Mandatory = $true)][string]$Severity,
        [string]$Notes = 'Auto-detected'
    )

    return [pscustomobject][ordered]@{
        RuleId = $RuleId
        TableName = $TableName
        ColumnName = $ColumnName
        RuleType = $RuleType
        ExpectedType = $ExpectedType
        AllowBlank = $AllowBlank
        MinValue = $MinValue
        MaxValue = $MaxValue
        AllowedValues = $AllowedValues
        RefTable = $RefTable
        RefColumn = $RefColumn
        ConditionSQL = $ConditionSQL
        Severity = $Severity
        Notes = $Notes
    }
}

function Get-DefaultRange {
    param([Parameter(Mandatory = $true)][string]$ColumnName)

    $lowerName = $ColumnName.ToLowerInvariant()
    switch -Regex ($lowerName) {
        'rate|percent|percentage|probability' { return @{ Min = '0'; Max = '100' } }
        'amount|balance|value|cost|price|commitment' { return @{ Min = '0'; Max = '1000000000' } }
        'days|term|duration' { return @{ Min = '0'; Max = '36500' } }
        default { return $null }
    }
}

if (-not (Get-Command Invoke-Sqlcmd -ErrorAction SilentlyContinue)) {
    throw 'Invoke-Sqlcmd was not found. Install the SqlServer PowerShell module or run this workflow through an MSSQL MCP-enabled agent session.'
}

$tableFilter = ($TableName | ForEach-Object { Quote-SqlLiteral $_ }) -join ', '

$columnQuery = @"
SELECT
    c.TABLE_NAME,
    c.COLUMN_NAME,
    c.DATA_TYPE,
    c.IS_NULLABLE,
    c.ORDINAL_POSITION
FROM INFORMATION_SCHEMA.COLUMNS AS c
WHERE c.TABLE_SCHEMA = $(Quote-SqlLiteral $Schema)
  AND c.TABLE_NAME IN ($tableFilter)
ORDER BY c.TABLE_NAME, c.ORDINAL_POSITION;
"@

$pkQuery = @"
SELECT
    t.name AS TableName,
    c.name AS ColumnName,
    ic.key_ordinal AS KeyOrdinal
FROM sys.key_constraints AS kc
INNER JOIN sys.tables AS t
    ON kc.parent_object_id = t.object_id
INNER JOIN sys.schemas AS s
    ON t.schema_id = s.schema_id
INNER JOIN sys.index_columns AS ic
    ON kc.parent_object_id = ic.object_id
   AND kc.unique_index_id = ic.index_id
INNER JOIN sys.columns AS c
    ON ic.object_id = c.object_id
   AND ic.column_id = c.column_id
WHERE kc.type = 'PK'
  AND s.name = $(Quote-SqlLiteral $Schema)
  AND t.name IN ($tableFilter)
ORDER BY t.name, ic.key_ordinal;
"@

$fkQuery = @"
SELECT
    pt.name AS TableName,
    pc.name AS ColumnName,
    rt.name AS RefTable,
    rc.name AS RefColumn
FROM sys.foreign_key_columns AS fkc
INNER JOIN sys.tables AS pt
    ON fkc.parent_object_id = pt.object_id
INNER JOIN sys.schemas AS ps
    ON pt.schema_id = ps.schema_id
INNER JOIN sys.columns AS pc
    ON pc.object_id = fkc.parent_object_id
   AND pc.column_id = fkc.parent_column_id
INNER JOIN sys.tables AS rt
    ON fkc.referenced_object_id = rt.object_id
INNER JOIN sys.columns AS rc
    ON rc.object_id = fkc.referenced_object_id
   AND rc.column_id = fkc.referenced_column_id
WHERE ps.name = $(Quote-SqlLiteral $Schema)
  AND pt.name IN ($tableFilter)
ORDER BY pt.name, pc.column_id;
"@

$columns = Invoke-Sqlcmd -ServerInstance $ServerInstance -Database $Database -Query $columnQuery
$pks = Invoke-Sqlcmd -ServerInstance $ServerInstance -Database $Database -Query $pkQuery
$fks = Invoke-Sqlcmd -ServerInstance $ServerInstance -Database $Database -Query $fkQuery

$pkLookup = @{}
foreach ($pk in $pks) {
    $key = "{0}.{1}" -f $pk.TableName, $pk.ColumnName
    $pkLookup[$key] = $true
}

$fkLookup = @{}
foreach ($fk in $fks) {
    $key = "{0}.{1}" -f $fk.TableName, $fk.ColumnName
    $fkLookup[$key] = $fk
}

$rules = New-Object System.Collections.Generic.List[object]

foreach ($column in $columns) {
    $table = [string]$column.TABLE_NAME
    $columnName = [string]$column.COLUMN_NAME
    $dataType = [string]$column.DATA_TYPE
    $isNullable = [string]$column.IS_NULLABLE
    $expectedType = Get-ExpectedType -SqlType $dataType
    $allowBlank = if ($isNullable -eq 'YES') { '1' } else { '0' }
    $columnKey = "{0}.{1}" -f $table, $columnName
    $lowerColumnName = $columnName.ToLowerInvariant()
    $isPrimaryKey = $pkLookup.ContainsKey($columnKey)
    $isForeignKey = $fkLookup.ContainsKey($columnKey)

    if ($isPrimaryKey) {
        $rules.Add((New-Rule -RuleId "${table}_${columnName}_KeyNotBlank" -TableName $table -ColumnName $columnName -RuleType 'KeyNotBlank' -ExpectedType $expectedType -AllowBlank '0' -Severity 'Error' -Notes 'Auto-detected: primary key must not be blank'))
        $rules.Add((New-Rule -RuleId "${table}_${columnName}_KeyUnique" -TableName $table -ColumnName $columnName -RuleType 'KeyUnique' -ExpectedType $expectedType -AllowBlank '0' -Severity 'Error' -Notes 'Auto-detected: primary key must be unique'))
    }

    if ($isForeignKey) {
        $fk = $fkLookup[$columnKey]
        $rules.Add((New-Rule -RuleId "${table}_${columnName}_RI" -TableName $table -ColumnName $columnName -RuleType 'RI' -ExpectedType $expectedType -AllowBlank $allowBlank -RefTable ([string]$fk.RefTable) -RefColumn ([string]$fk.RefColumn) -Severity 'Error' -Notes 'Auto-detected: foreign key relationship'))
    }

    if ($dataType -match 'int|bigint|smallint|tinyint|decimal|numeric|float|real|money|smallmoney') {
        $rules.Add((New-Rule -RuleId "${table}_${columnName}_TypeNumber" -TableName $table -ColumnName $columnName -RuleType 'TypeNumber' -ExpectedType 'Number' -AllowBlank $allowBlank -Severity 'Warn' -Notes 'Auto-detected: numeric column'))

        $range = Get-DefaultRange -ColumnName $columnName
        if ($null -ne $range) {
            $rules.Add((New-Rule -RuleId "${table}_${columnName}_Range" -TableName $table -ColumnName $columnName -RuleType 'Range' -ExpectedType 'Number' -AllowBlank $allowBlank -MinValue $range.Min -MaxValue $range.Max -Severity 'Warn' -Notes 'Auto-detected: suggested numeric bounds'))
        }
    }

    if ($dataType -match 'date|datetime|datetime2|smalldatetime|datetimeoffset') {
        $rules.Add((New-Rule -RuleId "${table}_${columnName}_TypeDate" -TableName $table -ColumnName $columnName -RuleType 'TypeDate' -ExpectedType 'Date' -AllowBlank $allowBlank -Severity 'Warn' -Notes 'Auto-detected: date or datetime column'))
    }

    if ($dataType -match 'varchar|nvarchar|char|nchar|text|ntext') {
        if ((-not $isPrimaryKey) -and $isNullable -eq 'NO') {
            $rules.Add((New-Rule -RuleId "${table}_${columnName}_KeyNotBlank" -TableName $table -ColumnName $columnName -RuleType 'KeyNotBlank' -ExpectedType 'Text' -AllowBlank '0' -Severity 'Warn' -Notes 'Auto-detected: non-nullable text column'))
        }


                # We use TOP 21 to sample up to 21 distinct values. If the result count is <= 20, we treat the column as low-cardinality and generate a Domain rule.
                $distinctQuery = @"
SELECT DISTINCT TOP 21
        CAST([$columnName] AS NVARCHAR(4000)) AS SampleValue
FROM [$Schema].[$table]
WHERE [$columnName] IS NOT NULL
    AND LTRIM(RTRIM(CAST([$columnName] AS NVARCHAR(4000)))) <> ''
ORDER BY SampleValue;
"@

        $sampleValues = Invoke-Sqlcmd -ServerInstance $ServerInstance -Database $Database -Query $distinctQuery |
            Select-Object -ExpandProperty SampleValue

        if ($sampleValues.Count -gt 0 -and $sampleValues.Count -le 20 -and $lowerColumnName -match 'status|stage|type|category') {
            $allowedValues = ($sampleValues | ForEach-Object { [string]$_ }) -join '|'
            $rules.Add((New-Rule -RuleId "${table}_${columnName}_Domain" -TableName $table -ColumnName $columnName -RuleType 'Domain' -ExpectedType 'Text' -AllowBlank $allowBlank -AllowedValues $allowedValues -Severity 'Warn' -Notes 'Auto-detected: low-cardinality domain column'))
        }
    }
}

$rules = $rules |
    Sort-Object TableName, ColumnName, RuleType, RuleId -Unique

$outputDirectory = Split-Path -Path $OutFile -Parent
if ($outputDirectory) {
    New-Item -ItemType Directory -Path $outputDirectory -Force | Out-Null
}

$rules | Export-Csv -Path $OutFile -NoTypeInformation -Encoding UTF8
Write-Host "Generated $($rules.Count) rules into $OutFile"
