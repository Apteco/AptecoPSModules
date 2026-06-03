function Copy-DataDispatch {
    <#
    .SYNOPSIS
        Copies the DataDispatch application files from the module to a target directory.

    .DESCRIPTION
        Deploys all dispatcher files (dispatch.ps1, setup-task.ps1, handlers/, endpoints/,
        .env.example) from the installed module to the specified destination so the
        dispatcher can be configured and scheduled there.

        After copying, follow these steps in the destination directory:
          1. Copy and edit .env:
               Copy-Item .env.example .env
               notepad .env     — set SQL Server connection for the source database (WebhookEvents)
          2. Edit or copy endpoints\*.yaml — one file per webhook endpoint, defines targets
          3. Install PowerShell dependencies (once per machine):
               Install-Module WriteLog        -Scope CurrentUser
               Install-Module SimplySql       -Scope CurrentUser
               Install-Module powershell-yaml -Scope CurrentUser
               # For DuckDB targets also:
               Install-Module ImportDependency -Scope CurrentUser
          4. Register the Scheduled Task (as Administrator):
               .\setup-task.ps1 -Action install
          5. Run once to verify:
               .\setup-task.ps1 -Action run
               Get-Content logs\dispatch_$(Get-Date -Format 'yyyy-MM-dd').log -Tail 30

    .PARAMETER Destination
        Target directory. Defaults to the current working directory.

    .PARAMETER Force
        Overwrite existing files without prompting.

    .EXAMPLE
        Copy-DataDispatch
        # Copies to the current directory.

    .EXAMPLE
        Copy-DataDispatch -Destination 'C:\FastStats\Scripts\DataDispatch' -Force
        # Copies to the given path, overwriting existing files.
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory = $false)]
        [string] $Destination = $PWD.Path,

        [switch] $Force
    )

    process {

        $moduleRoot = Join-Path $PSScriptRoot '..'
        $moduleRoot = (Resolve-Path $moduleRoot).Path

        $itemsToCopy = @(
            'dispatch.ps1',
            'setup-task.ps1',
            '.env.example',
            'endpoints',
            'handlers'
        )

        if (-not (Test-Path $Destination)) {
            New-Item -ItemType Directory -Path $Destination -Force | Out-Null
            Write-Verbose "Created directory: $Destination"
        }

        foreach ($item in $itemsToCopy) {
            $src = Join-Path $moduleRoot $item
            if (-not (Test-Path $src)) {
                Write-Verbose "Skipping (not found): $item"
                continue
            }

            $dst = Join-Path $Destination $item

            if ($PSCmdlet.ShouldProcess($dst, "Copy $item")) {
                Copy-Item -Path $src -Destination $dst -Recurse -Force:$Force.IsPresent
                Write-Verbose "Copied: $item"
            }
        }

        Write-Host ""
        Write-Host "DataDispatch files copied to: $Destination" -ForegroundColor Green
        Write-Host ""
        Write-Host "Next steps:" -ForegroundColor Cyan
        Write-Host "  1. Copy-Item $Destination\.env.example $Destination\.env"
        Write-Host "     notepad $Destination\.env"
        Write-Host "  2. notepad $Destination\endpoints\brevo-marketing.yaml"
        Write-Host "  3. Install-Module WriteLog, SimplySql, powershell-yaml  -Scope CurrentUser"
        Write-Host "  4. .\setup-task.ps1 -Action install   (run as Administrator)"
        Write-Host "  5. .\setup-task.ps1 -Action run"
        Write-Host "     Get-Content $Destination\logs\dispatch_`$(Get-Date -Format 'yyyy-MM-dd').log -Tail 30"
        Write-Host ""

    }

}
