[CmdletBinding()]
param(
  [Parameter(Mandatory = $true)]
  [ValidateScript({ Test-Path -LiteralPath $_ -PathType Leaf })]
  [string]$RdlPath,
  [Parameter(Mandatory = $true)]
  [ValidatePattern('^[0-9a-fA-F-]{36}$')]
  [string]$WorkspaceId,
  [string]$DisplayName,
  [switch]$Overwrite,
  [ValidateRange(1, 300)]
  [int]$PollIntervalSeconds = 3,
  [ValidateRange(1, 200)]
  [int]$MaxPollAttempts = 40
)

$ErrorActionPreference = 'Stop'
$rdl = (Resolve-Path -LiteralPath $RdlPath).Path
$fileName = [System.IO.Path]::GetFileName($rdl)
if ([string]::IsNullOrWhiteSpace($DisplayName)) {
  $DisplayName = [System.IO.Path]::GetFileNameWithoutExtension($rdl)
}
if ([string]::IsNullOrWhiteSpace($DisplayName)) { throw 'DisplayName must not be empty.' }

# Abort is the safe first-publish default. Re-publication must opt in explicitly.
$nameConflict = if ($Overwrite) { 'Overwrite' } else { 'Abort' }
$token = (az account get-access-token --resource 'https://analysis.windows.net/powerbi/api' --query accessToken -o tsv).Trim()
if ([string]::IsNullOrWhiteSpace($token)) { throw 'Azure CLI returned no Power BI access token.' }

$base = "https://api.powerbi.com/v1.0/myorg/groups/$WorkspaceId"
$client = [System.Net.Http.HttpClient]::new()
$client.DefaultRequestHeaders.Authorization =
  [System.Net.Http.Headers.AuthenticationHeaderValue]::new('Bearer', $token)
$form = [System.Net.Http.MultipartFormDataContent]::new()
try {
  $bytes = [System.IO.File]::ReadAllBytes($rdl)
  $form.Add([System.Net.Http.ByteArrayContent]::new($bytes), 'file', $fileName)
  $encodedName = [uri]::EscapeDataString("$DisplayName.rdl")
  $url = "$base/imports?datasetDisplayName=$encodedName&nameConflict=$nameConflict"
  $resp = $client.PostAsync($url, $form).Result
  $respBody = $resp.Content.ReadAsStringAsync().Result
  if (-not $resp.IsSuccessStatusCode) {
    Write-Error "IMPORT_POST_HTTP $([int]$resp.StatusCode): $respBody"
    exit 1
  }
  $import = $respBody | ConvertFrom-Json
  if ([string]::IsNullOrWhiteSpace($import.id)) { throw 'Import response did not contain an operation id.' }
  Write-Output "Import id: $($import.id)"

  for ($i = 0; $i -lt $MaxPollAttempts; $i++) {
    $st = Invoke-RestMethod -Uri "$base/imports/$($import.id)" -Headers @{ Authorization = "Bearer $token" }
    Write-Output "importState: $($st.importState)"
    if ($st.importState -eq 'Succeeded') {
      if (-not $st.reports) { throw 'Import succeeded but returned no report metadata.' }
      $st.reports | ForEach-Object {
        Write-Output "REPORT name=$($_.name) id=$($_.id) webUrl=$($_.webUrl)"
      }
      exit 0
    }
    if ($st.importState -eq 'Failed') {
      $details = if ($st.error) { $st.error | ConvertTo-Json -Depth 8 -Compress } else { 'No error details returned.' }
      Write-Error "IMPORT_FAILED: $details"
      exit 1
    }
    Start-Sleep -Seconds $PollIntervalSeconds
  }
  Write-Error "Import did not reach a terminal state after $MaxPollAttempts attempts."
  exit 1
}
finally {
  $form.Dispose()
  $client.Dispose()
}
