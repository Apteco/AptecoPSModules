Function Select-CompatiblePackage {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [Object[]]$Package = [Array]@()   # Objects from Get-LocalPackage/Get-Package with Id, Version, Path
    )

    process {

        $Package | Group-Object -Property Id | ForEach-Object {

            $group = @( $_.Group )

            If ( $group.Count -eq 1 ) {
                $group
                return
            }

            # Multiple versions of the same package Id were found on disk (e.g. a Desktop-compatible
            # DuckDB.NET.Bindings.Full 1.4.4 sitting next to a Core-only 1.5.0 so both PS editions can
            # share one lib folder). Only one may ever be loaded into the process: two versions of the
            # same native library both loading under the same base filename is not a clean per-edition
            # split -- Windows resolves an unqualified LoadLibrary("x.dll") process-wide by name, so
            # whichever native DLL happens to load first silently wins every later implicit P/Invoke
            # lookup, even calls coming from the other managed assembly. So exactly one version per Id
            # is selected here, before anything gets loaded.
            $ordered = $group | Sort-Object { [version]( $_.Version -replace '[^0-9.]', '0' ) } -Descending

            # Get-BestFrameworkPath throws (rather than writing a non-terminating error) when no
            # folder matches, so -ErrorAction SilentlyContinue alone would not stop it from
            # propagating out of this filter -- it needs an actual try/catch
            $compatible = @( $ordered | Where-Object {
                If ( ( Test-Path -Path ( Join-Path $_.Path "lib" ) ) -eq $false ) {
                    $true
                } else {
                    try {
                        $null -ne ( Get-BestFrameworkPath -PackageRoot $_.Path -ErrorAction Stop )
                    } catch {
                        $false
                    }
                }
            } )

            If ( $compatible.Count -gt 0 ) {
                # Highest version that is actually loadable under the current PS edition
                $compatible | Select-Object -First 1
            } else {
                # None of the versions offer a compatible framework folder -- still surface exactly
                # one candidate so the existing per-package "no compatible framework" warning further
                # down the pipeline fires once, instead of silently dropping the package or attempting
                # (and failing) every version in turn
                $ordered | Select-Object -First 1
            }

        }

    }
}
