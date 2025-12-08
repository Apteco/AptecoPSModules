Function Get-BestReferencePath {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [String]$PackageRoot   # e.g. "$HOME\.nuget\packages\myPkg\1.0.0"
    )

    process {

        $bestFramework = $null
        $Script:frameworkPreference | ForEach-Object {

            $tfm = $_
            $genericPath = Join-Path $PackageRoot "ref/$( $tfm )"
            $dll = Get-ChildItem -Path $genericPath -Filter "*.dll" -File -ErrorAction SilentlyContinue | Select-Object -First 1
            if ( $dll.Count -gt 0 -and $null -eq $bestFramework ) {
                $bestFramework = $dll.DirectoryName
            }
            
        }

        If ( $null -ne $bestFramework ) {
            return $bestFramework
        } else {
            throw "No compatible assembly found in $( $PackageRoot ) for reference $( $Script:frameworkPreference -join ',' )"
        }

    }
}
