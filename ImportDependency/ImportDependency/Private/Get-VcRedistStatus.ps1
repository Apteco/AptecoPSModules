Function Get-VcRedistStatus {

    <#
    .SYNOPSIS
        Checks the registry for an installed Visual C++ Redistributable.
    .DESCRIPTION
        Always re-reads the registry rather than relying on a cached value, so callers see the current state
        even if vcredist was installed or removed after this module was imported (e.g. via InstallDependency's
        Install-VcRedist).
    #>

    [CmdletBinding()]
    Param()

    $vcredistInstalled = $False
    $vcredist64 = $False
    $vcRedistCollection = $null

    # Possible registry paths for Visual C++ Redistributable installations
    If ( $Script:os -eq "Windows" ) {

        try {

            # Attempt to retrieve the Visual C++ Redistributable registry entries
            $vcReg = [Array]@( Get-ItemProperty 'HKLM:\SOFTWARE\Wow6432Node\Microsoft\VisualStudio\*\VC\Runtimes\*' -ErrorAction Stop )

            If ( $vcReg.Count -gt 0 ) {
                $vcredistInstalled = $True

                $vcRedistCollection = [hashtable]@{}
                $vcReg | ForEach-Object {
                    $vcRegItem = $_
                    If ( $vcRegItem.PSChildName -like "*64" -and $vcRegItem.Installed -gt 0 ) {
                        $vcredist64 = $True
                    }
                    $vcRedistCollection.Add($vcRegItem.PSChildName, ([PSCustomObject]@{
                                "Version"   = $vcRegItem.Version
                                "Major"     = $vcRegItem.Major
                                "Minor"     = $vcRegItem.Minor
                                "Build"     = $vcRegItem.Build
                                "Installed" = $vcRegItem.Installed
                            }
                        )
                    )

                }

            }
        } catch {
            Write-Verbose "VCRedist is not installed"
        }

    }

    [PSCustomObject]@{
        "installed" = $vcredistInstalled
        "is64bit"   = $vcredist64
        "versions"  = $vcRedistCollection
    }

}
