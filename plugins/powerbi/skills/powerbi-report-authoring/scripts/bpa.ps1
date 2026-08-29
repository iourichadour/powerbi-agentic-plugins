param (    
    <#
    .PARAMETER reports
    Specifies the path(s) to the PBIR (Power BI Report) definition folder(s) to analyze with BPA.    
    #>
    [Parameter(Mandatory=$true)]
    [string[]]$reports
    ,
    $rulesFilePath = $null
)

# Run with a process-scoped bypass so helper scripts work without policy changes.
Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process -Force
  
$currentFolder = (Split-Path $MyInvocation.MyCommand.Definition -Parent)
$toolsPath = "$currentFolder\_tools"
$pbiInspectorEXE = "$toolsPath\PBIInspector\win-x64\CLI\PBIRInspectorCLI.exe"

if (!(Test-Path $pbiInspectorEXE)) {
    throw "Cannot find bundled PBI Inspector executable at path: '$pbiInspectorEXE'."
}

function Get-VersionPrefix {
    param(
        [Parameter(Mandatory = $true)]
        [string]$VersionText
    )

    $normalizedVersion = $VersionText.Trim()
    if ($normalizedVersion.StartsWith('v')) {
        $normalizedVersion = $normalizedVersion.Substring(1)
    }

    return $normalizedVersion.Split('+')[0]
}

function ConvertTo-ReleaseVersion {
    param(
        [Parameter(Mandatory = $true)]
        [string]$VersionText
    )

    $normalizedVersion = Get-VersionPrefix -VersionText $VersionText
    if ($normalizedVersion -match '^(\d+\.\d+\.\d+)') {
        return [version]$Matches[1]
    }

    return $null
}

function Get-LatestPbiInspectorRelease {
    $releaseApiUrl = "https://api.github.com/repos/NatVanG/PBI-InspectorV2/releases/latest"
    $headers = @{
        "User-Agent" = "powerbi-report-authoring-bpa"
        "Accept"     = "application/vnd.github+json"
    }

    return Invoke-RestMethod -Uri $releaseApiUrl -Headers $headers -Method Get
}

function Test-ShouldCheckLatestRelease {
    param(
        [Parameter(Mandatory = $true)]
        [string]$StateFilePath
    )

    if (!(Test-Path $StateFilePath)) {
        return $true
    }

    try {
        $state = Get-Content -Path $StateFilePath -Raw | ConvertFrom-Json
        $lastChecked = [datetime]::Parse($state.lastCheckedUtc)
        return ((Get-Date).ToUniversalTime() - $lastChecked).TotalDays -ge 7
    }
    catch {
        return $true
    }
}

function Save-ReleaseCheckState {
    param(
        [Parameter(Mandatory = $true)]
        [string]$StateFilePath,
        [Parameter(Mandatory = $true)]
        [string]$LatestTag,
        [Parameter(Mandatory = $true)]
        [string]$BundledVersion
    )

    $state = [ordered]@{
        lastCheckedUtc = (Get-Date).ToUniversalTime().ToString("o")
        latestTag      = $LatestTag
        bundledVersion  = $BundledVersion
    }

    $state | ConvertTo-Json -Depth 4 | Set-Content -Path $StateFilePath -Encoding UTF8
}

$releaseStatePath = Join-Path $toolsPath "PBIInspector\release-check.json"
$bundledVersion = ConvertTo-ReleaseVersion -VersionText ([System.Diagnostics.FileVersionInfo]::GetVersionInfo($pbiInspectorEXE).ProductVersion)

if ($null -eq $bundledVersion) {
    throw "Cannot determine bundled PBI Inspector version from '$pbiInspectorEXE'."
}

if (Test-ShouldCheckLatestRelease -StateFilePath $releaseStatePath) {
    try {
        $latestRelease = Get-LatestPbiInspectorRelease
        $latestTag = [string]$latestRelease.tag_name
        $latestVersion = ConvertTo-ReleaseVersion -VersionText $latestTag

        if ($null -ne $latestVersion -and $latestVersion -gt $bundledVersion) {
            Write-Warning "A newer PBI Inspector release is available: $latestTag. The bundled version is $bundledVersion. Update the checked-in executable manually if you want the newer release."
        }

        Save-ReleaseCheckState -StateFilePath $releaseStatePath -LatestTag $latestTag -BundledVersion $bundledVersion
    }
    catch {
        Write-Warning "Unable to check the latest PBI Inspector release on GitHub: $($_.Exception.Message)"
    }
}

if ($rulesFilePath -eq $null) {
    $rulesFilePath = "$currentFolder\bpa-rules-report.json"
}

if (!(Test-Path $rulesFilePath)) {
    throw "Cannot find PBI Inspector rules file at path: '$rulesFilePath'. Please provide a valid path to the BPA rules file"    
}

foreach ($report in $reports) {

    Write-Host "Running PBI Inspector BPA rules for: '$model'"

    $process = Start-Process -FilePath $pbiInspectorEXE -ArgumentList "-pbipreport ""$report"" -rules ""$rulesFilePath"" -formats ""GitHub""" -NoNewWindow -Wait -PassThru    

    if ($process.ExitCode -ne 0) {
    
        Write-Host "Detected critical errors for report '$report'"
    }           

}
