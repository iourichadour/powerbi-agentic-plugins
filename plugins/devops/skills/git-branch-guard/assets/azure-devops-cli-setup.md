# Plan: Set Up Azure CLI (`az`) + Azure DevOps Extension for the Team

## Context
Since we do not have admin rights to run the standard Azure CLI MSI
installer, `az` is installed from the no-admin ZIP distribution instead, unzipped to:
`C:\Users\<username>\AppData\Local\GitHubCopilotCLI\az\`

It ships with `bin\az.cmd` but is not on PATH by default, so `az` commands
fail until the folder is added to the environment.

## Script to run

All of the steps below (download/unzip, PATH, extension install, default
org/project, access verification) are automated by
[`setup_azure_cli.ps1`](./setup_azure_cli.ps1), and every step is idempotent
— safe to re-run on a machine that already has some or all of it set up.

```powershell
powershell -ExecutionPolicy Bypass -File setup_azure_cli.ps1 -Organization "https://dev.azure.com/bayviewasset" -Project "BAMDataServices"
```

- `-Organization`/`-Project` are optional (default organization is already
  `bayviewasset`); omit `-Project` to skip setting a default project.
- Pass `-SkipDefaults` to skip the `az devops configure --defaults` step, or
  `-SkipExtension`/`-SkipPath` to skip those individual steps.
- `az login` is intentionally **not** run by the script — it opens an
  interactive browser prompt, so the script only reports whether you're
  already authenticated and tells you to run `az login` yourself if not.

The manual steps below are kept for reference/troubleshooting if you need
to run a piece by hand.

## Steps

1. **Download and unzip the Azure CLI (no-admin, zip install)**
   ```powershell
   $zipUrl = "https://aka.ms/installazurecliwindowszipx64"
   $destDir = "C:\Users\<username>\AppData\Local\GitHubCopilotCLI\az"
   $zipPath = "$env:TEMP\azure-cli.zip"
   Invoke-WebRequest -Uri $zipUrl -OutFile $zipPath
   New-Item -ItemType Directory -Path $destDir -Force | Out-Null
   Expand-Archive -Path $zipPath -DestinationPath $destDir -Force
   Remove-Item $zipPath -Force
   ```
   - The CLI entry point ends up at: `<destDir>\bin\az.cmd`
   - See [Install Azure CLI on Windows (ZIP)](https://learn.microsoft.com/en-us/cli/azure/install-azure-cli-windows?view=azure-cli-latest&pivots=zip)
     for the official reference.

2. **Add `az\bin` to the User PATH (persistent)**
   ```powershell
   $dir = "C:\Users\<username>\AppData\Local\GitHubCopilotCLI\az\bin"
   $current = [Environment]::GetEnvironmentVariable("Path","User")
   if ($current -notlike "*$dir*") {
       [Environment]::SetEnvironmentVariable("Path", "$current;$dir", "User")
   }
   ```
   - Open a **new terminal** afterward so the updated PATH is picked up.

3. **Verify the CLI works**
   ```powershell
   az --version
   ```

4. **Install the Azure DevOps extension**
   ```powershell
   az extension add --name azure-devops --only-show-errors
   az devops -h
   ```

5. **Log in to Azure**
   ```powershell
   az login
   az account show -o table
   ```

6. **Set the default Azure DevOps organization**
   ```powershell
   az devops configure --defaults organization=https://dev.azure.com/bayviewasset
   ```
   - This avoids having to pass `--organization` on every command and avoids
     auto-detect warnings when not inside a git repo with an Azure DevOps remote.

7. **Verify DevOps access**
   ```powershell
   az devops project list -o table
   ```
   Confirmed projects returned for org `bayviewasset`:
   - BAMCloudProjects
   - BAMDataServices
   - BAMITAnalytics
   - Investor Database
   - Oceanview Actuarial

## Notes for Team Rollout
- Each team member needs the `az\` folder distributed (or installed via the
  standard Azure CLI MSI) and PATH updated on their own machine — PATH changes
  are per-user/per-machine, not shared.
- `az login` is per-user (uses their own Azure AD credentials/permissions).
- The `az devops configure --defaults organization=...` step is also per-user
  local config (stored under the user's `%USERPROFILE%\.azure` folder) and
  must be run once per machine/user.
- Optionally set a default project too, e.g.:
  ```powershell
  az devops configure --defaults project=BAMDataServices
  ```
