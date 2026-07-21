
function Install-SqlPipeline {
    [CmdletBinding()]
    param(
    )

    process {

        Write-Verbose "Starting installation of SQLPipeline dependencies..."

        # Check if InstallDependency is present -- it does the actual pinned/latest version
        # installation and correctly keeps distinct pinned versions of the same package Id side
        # by side (needed here since $Script:psPackages pins DuckDB.NET 1.4.4 for Windows
        # PowerShell alongside an unpinned "latest" request for pwsh, both installed unconditionally
        # so the same lib folder works for either PowerShell edition)
        If ( @( Get-InstalledModule | Where-Object { $_.Name -eq "InstallDependency" } ).Count -lt 1 ) {
            Write-Verbose "Missing dependency, executing: 'Install-Module InstallDependency'"
            Install-Module InstallDependency -Force -AllowClobber
        }
        Import-Module InstallDependency -Force

        $outputDir = Join-Path -Path $PWD.Path -ChildPath "/lib"

        Install-Dependency -LocalPackage $Script:psPackages -LocalPackageFolder $outputDir -ExcludeDependencies

        # Now try the re-import of all packages
        Import-Package

    }


}
