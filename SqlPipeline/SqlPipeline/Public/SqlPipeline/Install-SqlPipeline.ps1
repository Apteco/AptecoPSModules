# TODO Move Download-NuGetPackage to a common module and use it in Install-SqlPipeline


function Install-SqlPipeline {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [switch]$WindowsPowerShell
    )

    process {

        Write-Verbose "Starting installation of SQLPipeline dependencies..."

        # Windows PowerShell 5.1 requires specific older package versions:
        #   DuckDB.NET 1.4.4 (last version compatible with .NET Framework / WinPS 5.1)
        #   System.Memory 4.6.0 (required polyfill not included in .NET Framework)
        $packagesToInstall = if ($WindowsPowerShell) {
            [Array]@(
                [PSCustomObject]@{ Name = "DuckDB.NET.Bindings.Full"; Version = "1.4.4" }
                [PSCustomObject]@{ Name = "DuckDB.NET.Data.Full";     Version = "1.4.4" }
                [PSCustomObject]@{ Name = "System.Memory";            Version = "4.6.0" }
            )
        } else {
            $Script:psPackages
        }

        If ( $packagesToInstall.Count -gt 0 ) {

            $pse = Get-PSEnvironment
            Write-Verbose "There are currently $($packagesToInstall.Count) packages to install."
            Write-Verbose "Checking for already installed packages..."
            Write-Verbose "Installed local packages: $( $pse.InstalledLocalPackages.Id -join ", ")"
            Write-Verbose "To update already installed packages, please remove them first and then run Install-SqlPipeline again."

            $outputDir = Join-Path -Path $PWD.Path -ChildPath "/lib"
            New-Item -Path $outputDir -ItemType Directory -Force | Out-Null

            $packagesToInstall | ForEach-Object {
                $pkg = $_
                $pkgName    = if ( $pkg -is [string] ) { $pkg } elseif ( $pkg -is [pscustomobject] -and $pkg.Name ) { $pkg.Name } else { throw "Invalid package definition: $pkg" }
                $pkgVersion = if ( $pkg -is [pscustomobject] -and $pkg.Version ) { $pkg.Version } else { "" }
                Write-Verbose "Checking if package $pkgName is already installed..."
                If ( -not ( $pse.InstalledLocalPackages.Id -contains $pkgName ) ) {
                    Write-Verbose "Package $pkgName is not installed. Downloading and installing..."
                    Install-NuGetPackage -PackageId $pkgName -Version $pkgVersion -OutputDir $outputDir
                } else {
                    Write-Verbose "Package $pkgName is already installed. Skipping download."
                }
            }

            # Now try the re-import of all packages
            Import-Package

        }

    }


}