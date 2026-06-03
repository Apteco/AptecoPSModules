function Copy-NodeWebhook {
    <#
    .SYNOPSIS
        Copies the NodeWebhook application files from the module to a target directory.

    .DESCRIPTION
        Deploys all Node.js application files (src/, sql/, setup.ps1, configuration
        templates, etc.) from the installed module to the specified destination so the
        webhook receiver can be configured and started there.

        After copying, follow these steps in the destination directory:
          1. Edit .env            — SQL Server connection, port, log level
          2. Edit endpoints.yaml  — endpoint names, URL keys, bearer tokens
          3. Edit ecosystem.config.js — verify APP_DIR resolves correctly (uses __dirname)
          4. Edit pm2_watchdog.ps1   — set $workDir, $nodeExe, $pm2Bin to local paths
          5. Run: .\setup.ps1 -Action setup   (as Administrator)
             Installs npm dependencies, configures IIS ARR and registers the pm2 autostart task.
          6. Run: .\setup.ps1 -Action status  to verify receiver and worker are online.

        pm2_watchdog.ps1 is an optional scheduled watchdog that checks pm2 process health
        every N minutes and restarts crashed apps automatically. Set it up as a Scheduled Task
        after setup.ps1 has completed successfully. Configure $workDir, $nodeExe and $pm2Bin
        at the top of the script to match the target installation.

    .PARAMETER Destination
        Target directory. Defaults to the current working directory.

    .PARAMETER Force
        Overwrite existing files without prompting.

    .EXAMPLE
        Copy-NodeWebhook
        # Copies to the current directory.

    .EXAMPLE
        Copy-NodeWebhook -Destination 'C:\FastStats\Scripts\node_webhook' -Force
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
            'src',
            'sql',
            '.env.example',
            '.gitignore',
            'endpoints.yaml',
            'ecosystem.config.js',
            'package.json',
            'web.config',
            'setup.ps1',
            'setup_notify.ps1',
            'pm2_watchdog.ps1',
            'start.ps1'
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
        Write-Host "NodeWebhook files copied to: $Destination" -ForegroundColor Green
        Write-Host ""
        Write-Host "Next steps:" -ForegroundColor Cyan
        Write-Host "  1. notepad $Destination\.env"
        Write-Host "  2. notepad $Destination\endpoints.yaml"
        Write-Host "  3. # Configure pm2_watchdog.ps1: set `$workDir, `$nodeExe, `$pm2Bin"
        Write-Host "     notepad $Destination\pm2_watchdog.ps1"
        Write-Host "  4. .\setup.ps1 -Action setup   (run as Administrator)"
        Write-Host "  5. .\setup.ps1 -Action status"
        Write-Host ""
        Write-Host "SQL Server tables (run once):" -ForegroundColor Cyan
        Write-Host "  sqlcmd -S <server> -d <db> -i $Destination\sql\create-tables.sql"
        Write-Host ""

    }

}
