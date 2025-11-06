Function Get-BestRuntimePath {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$PackageRoot   # e.g. "$HOME\.nuget\packages\myPkg\1.0.0"
    )

    process {

        $bestRuntime = $null
        $Script:runtimePreference | ForEach-Object {

            # 1 Look in the RID‑specific folder first
            $runtimeId = $_
            $runtimePath = Join-Path $PackageRoot "runtimes/$( $runtimeId )"
            $dll = Get-ChildItem -Path $runtimePath -Filter "*.dll" -Recurse -File -ErrorAction SilentlyContinue | Select-Object -First 1
            if ( $dll.Count -gt 0 -and $null -eq $bestRuntime ) {
                $bestRuntime = $dll.DirectoryName
            }
            
        }

        If ( $null -ne $bestRuntime ) {
            return $bestRuntime
        } else {
            throw "No compatible assembly found in $( $PackageRoot ) for runtime $( $Script:runtimePreference -join ',' )"
        }


    }
}
