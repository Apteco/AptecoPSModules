
Function Get-TemporaryPath {

    <#
    .SYNOPSIS
        Returns the path to the system's temporary directory, cross-platform.
    #>

    [CmdletBinding()]
    param()

    process {

        $tmpdir = $null
        If ( $IsLinux -eq $True ) {
        
            If ( $null -ne $env:TMPDIR ) {
                $tmpdir = $env:TMPDIR
            } elseif ( (Test-Path -Path "/tmp") -eq $True ) {
                $tmpdir = "/tmp"
            } else {
                $tmpdir = "./"
            }

        } else {
            # IsWindows
            $tmpdir = $Env:tmp
        }

        return $tmpdir

    }

}