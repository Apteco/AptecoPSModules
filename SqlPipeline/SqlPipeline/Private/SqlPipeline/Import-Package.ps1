
function Import-Package {
    [CmdletBinding()]
    param()

    process {

        $pse = Get-PSEnvironment
        $libPath = Join-Path -Path $PWD.Path -ChildPath "/lib"
        Write-Verbose "Looking for local packages in $libPath"
        If ( $Script:psPackages.Count -gt 0 -and $pse.InstalledLocalPackages.Count -gt 0 ) {
            Import-Dependency -LoadWholePackageFolder -LocalPackageFolder $libPath
            try {
                [duckdb.NET.Data.DuckDBConnection]::new("DataSource=:memory:")
                $Script:isDuckDBLoaded = $true
                Write-Verbose "DuckDB.NET is available and will be used for the SQL pipeline."
            } catch {
                Write-Warning "DuckDB.NET is not available. The SQL pipeline for DuckDB will not work. Please install DuckDB.NET.Data.Full via Install-SqlPipeline or manually and ensure it's in the lib folder."
            }
        }

    }


}