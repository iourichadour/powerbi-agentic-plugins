param(
    [string]$Old = "HEAD~1",
    [string]$New = "HEAD",
    [string]$OutputPath,
    [Alias("KeepWorktrees")]
    [switch]$KeepFiles
)
$ErrorActionPreference = "Stop"

git rev-parse --show-toplevel | Out-Null
$scriptDir = $PSScriptRoot
$reviewer = Join-Path $scriptDir "pbip_change_reviewer.py"
if (-not (Test-Path $reviewer)) { throw "pbip_change_reviewer.py not found next to this script." }

$oldSha = (git rev-parse $Old).Trim()
$newSha = (git rev-parse $New).Trim()

$stamp = [guid]::NewGuid().ToString("N").Substring(0, 8)
$oldWt = Join-Path ([IO.Path]::GetTempPath()) "pbip-commit-diff-old-$stamp"
$newWt = Join-Path ([IO.Path]::GetTempPath()) "pbip-commit-diff-new-$stamp"
$summaryFile = Join-Path ([IO.Path]::GetTempPath()) "pbip-commit-diff-$stamp.md"

try {
    git worktree add --detach $oldWt $oldSha | Out-Null
    git worktree add --detach $newWt $newSha | Out-Null

    $pyLauncher = if (Get-Command py -ErrorAction SilentlyContinue) { "py" } else { "python" }
    $pyArgs = if ($pyLauncher -eq "py") { @("-3", $reviewer) } else { @($reviewer) }
    & $pyLauncher @pyArgs --old $oldWt --new $newWt --output $summaryFile
    if ($LASTEXITCODE -ne 0) { throw "pbip_change_reviewer.py failed." }

    $summary = Get-Content $summaryFile -Raw
    if ($OutputPath) {
        $outputDirectory = Split-Path -Parent $OutputPath
        if ($outputDirectory) { New-Item -ItemType Directory -Path $outputDirectory -Force | Out-Null }
        Set-Content -LiteralPath $OutputPath -Value $summary -Encoding UTF8
    }
    $summary
}
finally {
    if (-not $KeepFiles) {
        git worktree remove --force $oldWt 2>$null
        git worktree remove --force $newWt 2>$null
        Remove-Item $summaryFile -ErrorAction SilentlyContinue
    }
}
