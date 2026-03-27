# TODO Move Download-NuGetPackage to a common module and use it in Install-SqlPipeline


function Install-SqlPipeline {
    [CmdletBinding()]
    param()

    process {

        Write-Verbose "Starting installation of SQLPipeline dependencies..."

        If ( $Script:psPackages.Count -gt 0 ) {

            $pse = Get-PSEnvironment
            Write-Verbose "There are currently $($Script:psPackages.Count) packages defined as dependencies: $($Script:psPackages -join ", ")"
            Write-Verbose "Checking for already installed packages..."
            Write-Verbose "Installed local packages: $( $pse.InstalledLocalPackages.Id -join ", ")"
            Write-Verbose "To update already installed packages, please remove them first and then run Install-SqlPipeline again."

            $outputDir = Join-Path -Path $PWD.Path -ChildPath "/lib"
            New-Item -Path $outputDir -ItemType Directory -Force | Out-Null

            $psPackages | ForEach-Object {
                $pkg = $_
                $pkgName = if ( $pkg -is [string] ) { $pkg } elseif ( $pkg -is [pscustomobject] -and $pkg.Name ) { $pkg.Name } else { throw "Invalid package definition: $pkg" }
                Write-Verbose "Checking if package $pkg is already installed..."
                If ( -not ( $pse.InstalledLocalPackages.Id -contains $pkgName ) ) {
                    Write-Verbose "Package $pkg is not installed. Downloading and installing..."
                    Install-NuGetPackage -PackageId $pkg -OutputDir $outputDir
                } else {
                    Write-Verbose "Package $pkg is already installed. Skipping download."
                }
            }

            # Now try the re-import of all packages
            Import-Package

        }

    }


}