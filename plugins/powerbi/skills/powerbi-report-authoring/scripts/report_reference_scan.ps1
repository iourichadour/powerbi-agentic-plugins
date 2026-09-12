[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$Root,

    [Parameter(Mandatory = $true)]
    [string[]]$Terms,

    [switch]$Json,

    [int]$MaxItems = 0,

    [string]$Output
)

if ($Json -and $Output) {
    Write-Error '-Json and -Output cannot be used together.'
    exit 2
}

$interpreter = $null
foreach ($candidate in @('python', 'py')) {
    $command = Get-Command $candidate -ErrorAction SilentlyContinue
    if (-not $command) {
        continue
    }

    $commandPath = [string]$command.Source
    if ($commandPath -match '(?i)\\WindowsApps\\python(?:3)?\.exe$') {
        continue
    }

    $versionText = & $candidate --version 2>&1
    if ($LASTEXITCODE -ne 0 -or "$versionText" -notmatch 'Python\s+(\d+)\.(\d+)') {
        continue
    }

    $major = [int]$Matches[1]
    $minor = [int]$Matches[2]
    if ($major -gt 3 -or ($major -eq 3 -and $minor -ge 10)) {
        $interpreter = $candidate
        break
    }
}

if (-not $interpreter) {
    Write-Error 'Python 3.10 or later is required. Install Python from python.org and ensure python or py is available on PATH; the Windows Store execution alias is not supported.'
    exit 1
}

$scanner = Join-Path $PSScriptRoot 'report_reference_scan.py'
$arguments = @($scanner, '--root', $Root, '--terms') + $Terms + @('--max-items', "$MaxItems")
if ($Json) {
    $arguments += '--json'
}
if ($Output) {
    $arguments += @('--output', $Output)
}

& $interpreter @arguments
exit $LASTEXITCODE