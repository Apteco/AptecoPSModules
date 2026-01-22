Function Get-BestRuntimePath {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [String]$PackageRoot   # e.g. "$HOME\.nuget\packages\myPkg\1.0.0"
    )

    process {

        $bestRuntime = $null
        $Script:runtimePreference | ForEach-Object {

            # 1 Look in the RID‑specific folder first
            $runtimeId = $_
            $runtimePath = Join-Path $PackageRoot "runtimes/$( $runtimeId )"

            # Check based on platform-specific RIDs
            If ( $runtimeId -like "win*" ) {

                # Windows runtime: look for .dll files
                $assembly = Get-ChildItem -Path $runtimePath -Filter "*.dll" -Recurse -File -ErrorAction SilentlyContinue | Select-Object -First 1
                if ( $assembly.Count -gt 0 -and $null -eq $bestRuntime ) {
                    $bestRuntime = $assembly.DirectoryName
                }

            } elseif ( $runtimeId -like "linux*" ) {

                # Linux runtime: look for .so files
                $assembly = Get-ChildItem -Path $runtimePath -Filter "*.so*" -Recurse -File -ErrorAction SilentlyContinue | Select-Object -First 1
                if ( $assembly.Count -gt 0 -and $null -eq $bestRuntime ) {
                    $bestRuntime = $assembly.DirectoryName
                }

            } elseif ( $runtimeId -like "osx*" -or $runtimeId -like "macos*" ) {

                # macOS runtime: look for .dylib files
                $assembly = Get-ChildItem -Path $runtimePath -Filter "*.dylib" -Recurse -File -ErrorAction SilentlyContinue | Select-Object -First 1
                if ( $assembly.Count -gt 0 -and $null -eq $bestRuntime ) {
                    $bestRuntime = $assembly.DirectoryName
                }

            } else {

                $bestRuntime = Get-BestFrameworkPath -PackageRoot $runtimePath

            }
            
        }

        If ( $null -ne $bestRuntime ) {
            return $bestRuntime
        } else {
            throw "No compatible assembly found in $( $PackageRoot ) for runtime $( $Script:runtimePreference -join ',' )"
        }


    }
}
