
<#
.SYNOPSIS
Returns the current .NET runtime identifier for the running PowerShell process. Function written by chatGPT-5

.DESCRIPTION
Detects the .NET runtime version used by the current PowerShell session and returns a string such as "net6.0", "net5.0", or "net48".
#>
function Get-CurrentRuntimeId {
    [CmdletBinding()]
    param()

    $ver = [System.Environment]::Version
    if ($IsWindows) {
        # Detect classic .NET Framework if PowerShell is Windows PowerShell (not Core)
        if ($PSVersionTable.PSEdition -eq 'Desktop') {
            return "net$($ver.Major)$($ver.Minor)"   # e.g. net48
        }
    }
    # PowerShell 7+ runs on .NET (Core) – map major.minor to netX.Y
    return "net$($ver.Major).$($ver.Minor)"        # e.g. net6.0
}
