Function Get-VcRedistStatus {

    <#
    .SYNOPSIS
        Checks the registry for an installed Visual C++ Redistributable.
    .DESCRIPTION
        Scans HKLM:\SOFTWARE\Wow6432Node\Microsoft\VisualStudio\*\VC\Runtimes\* for installed VC++ runtimes,
        the same locations ImportDependency's Get-PSEnvironment checks at module import time. Unlike that
        cached snapshot, this always re-reads the registry, so it can be used both before and right after
        an install to verify it actually landed.
    #>

    [CmdletBinding()]
    Param()

    $installed = $false
    $is64Bit = $false
    $versions = $null

    try {

        $vcReg = [Array]@( Get-ItemProperty 'HKLM:\SOFTWARE\Wow6432Node\Microsoft\VisualStudio\*\VC\Runtimes\*' -ErrorAction Stop )

        If ( $vcReg.Count -gt 0 ) {

            $installed = $true
            $versions = [Hashtable]@{}

            $vcReg | ForEach-Object {
                $item = $_
                If ( $item.PSChildName -like "*64" -and $item.Installed -gt 0 ) {
                    $is64Bit = $true
                }
                $versions.Add($item.PSChildName, ([PSCustomObject]@{
                    "Version"   = $item.Version
                    "Major"     = $item.Major
                    "Minor"     = $item.Minor
                    "Build"     = $item.Build
                    "Installed" = $item.Installed
                }))
            }

        }

    } catch {
        Write-Verbose "vcredist not found"
    }

    [PSCustomObject]@{
        "Installed" = $installed
        "Is64Bit"   = $is64Bit
        "Versions"  = $versions
    }

}
