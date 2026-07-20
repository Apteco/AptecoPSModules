Function Get-LatestModuleVersion {

    <#
    .SYNOPSIS
        Returns the highest available version of a named module found via Get-Module -ListAvailable.
    .DESCRIPTION
        Always re-scans live rather than relying on a cached value, so it reflects modules installed
        or updated after this module was imported (e.g. PackageManagement/PowerShellGet updated mid-session).
    .PARAMETER Name
        The module name to look up, e.g. "PackageManagement" or "PowerShellGet".
    #>

    [CmdletBinding()]
    Param(
        [Parameter(Mandatory=$true)]
        [String]$Name
    )

    ( Get-Module -Name $Name -ListAvailable -ErrorAction SilentlyContinue | Sort-Object Version -Descending | Select-Object -First 1 ).Version.ToString()

}
