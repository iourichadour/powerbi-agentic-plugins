#Requires -Version 5.1
[CmdletBinding()]
param([int]$TimeoutMilliseconds = 30000)

$ErrorActionPreference = 'Stop'
if ([Environment]::OSVersion.Platform -ne [PlatformID]::Win32NT -or -not [Environment]::Is64BitOperatingSystem) {
    throw 'Power BI Modeling MCP smoke test requires Windows x64.'
}

$npx = Get-Command npx.cmd -ErrorAction SilentlyContinue
if (-not $npx) { throw 'npx.cmd was not found. Install Node.js 18+ and ensure npm is on PATH.' }

$package = '@microsoft/powerbi-modeling-mcp-win32-x64@1.0.0'
$startInfo = New-Object System.Diagnostics.ProcessStartInfo
$startInfo.FileName = $npx.Source
$startInfo.Arguments = "-y $package --start"
$startInfo.UseShellExecute = $false
$startInfo.CreateNoWindow = $true
$startInfo.RedirectStandardInput = $true
$startInfo.RedirectStandardOutput = $true
$startInfo.RedirectStandardError = $true
$process = New-Object System.Diagnostics.Process
$process.StartInfo = $startInfo
$request = @{ jsonrpc = '2.0'; id = 1; method = 'initialize'; params = @{ protocolVersion = '2025-06-18'; capabilities = @{}; clientInfo = @{ name = 'powerbi-agentic-plugins-smoke'; version = '1.0.0' } } } | ConvertTo-Json -Compress -Depth 10
$started = $false
try {
    if (-not $process.Start()) { throw 'The MCP process did not start.' }
    $started = $true
    $stderrTask = $process.StandardError.ReadToEndAsync()
    $process.StandardInput.WriteLine($request)
    $process.StandardInput.Flush()
    $deadline = [DateTime]::UtcNow.AddMilliseconds($TimeoutMilliseconds)
    $response = $null
    while ([DateTime]::UtcNow -lt $deadline) {
        $remaining = [Math]::Max(1, [int]$deadline.Subtract([DateTime]::UtcNow).TotalMilliseconds)
        $lineTask = $process.StandardOutput.ReadLineAsync()
        if (-not $lineTask.Wait($remaining)) { throw "No initialize response within $TimeoutMilliseconds ms." }
        $line = $lineTask.Result
        if ($null -eq $line) { break }
        try {
            $candidate = $line | ConvertFrom-Json
            if ($candidate.id -eq 1) { $response = $candidate; break }
        } catch { }
    }
    if (-not $response) {
        $stderrTask.Wait(1000) | Out-Null
        $stderr = if ($stderrTask.IsCompleted) { $stderrTask.Result.Trim() } else { '' }
        throw "The pinned MCP package exited or returned no initialize response (exit $($process.ExitCode)): $stderr"
    }
    if ($response.PSObject.Properties['error']) { throw "MCP initialize failed: $($response.error.message)" }
    if (-not $response.PSObject.Properties['result']) { throw 'MCP initialize response did not contain a result.' }
    Write-Output "Power BI Modeling MCP smoke test passed: $package remained alive through initialize."
} finally {
    if ($started -and -not $process.HasExited) { $process.Kill() }
    $process.Dispose()
}