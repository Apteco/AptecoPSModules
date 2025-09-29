
#-----------------------------------------------
# NOTES
#-----------------------------------------------

<#

Inspired by Tutorial of RamblingCookieMonster in
http://ramblingcookiemonster.github.io/Building-A-PowerShell-Module/
and
https://github.com/RamblingCookieMonster/PSStackExchange/blob/db1277453374cb16684b35cf93a8f5c97288c41f/PSStackExchange/PSStackExchange.psm1

#>


#-----------------------------------------------
# ENUMS
#-----------------------------------------------


# Severity Enumeration used by the log function
Enum LogSeverity {
    INFO      = 0
    VERBOSE   = 5
    WARNING   = 10
    ERROR     = 20
}


#-----------------------------------------------
# LOAD PUBLIC AND PRIVATE FUNCTIONS
#-----------------------------------------------

$Public  = @( Get-ChildItem -Path "$( $PSScriptRoot )/Public/*.ps1" -ErrorAction SilentlyContinue )
$Private = @( Get-ChildItem -Path "$( $PSScriptRoot )/Private/*.ps1" -ErrorAction SilentlyContinue )

# dot source the files
@( $Public + $Private ) | ForEach-Object {
    $import = $_
    Try {
        . $import.fullname
    } Catch {
        Write-Error -Message "Failed to import function $($import.fullname): $_"
    }
}


#-----------------------------------------------
# READ IN CONFIG FILES AND VARIABLES
#-----------------------------------------------

Export-ModuleMember -Function $Public.Basename


#-----------------------------------------------
# SET SOME VARIABLES ONLY VISIBLE TO MODULE AND FUNCTIONS
#-----------------------------------------------

New-Variable -Name logfile -Value $null -Scope Script -Force
New-Variable -Name processId -Value $null -Scope Script -Force
New-Variable -Name logfileOverride  -Value $null -Scope Script -Force
New-Variable -Name processIdOverride  -Value $null -Scope Script -Force

# This will be overridden later
$Script:processId = [guid]::NewGuid().ToString()

# Find out the temporary directory
# TODO Support for MacOS
$tmpdir = $null
If ( $IsLinux -eq $true ) {
   
    If ( $env:TMPDIR -ne $null ) {
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
$f = Join-Path -Path $tmpdir -ChildPath "$( $Script:processId ).tmp"
$fAbsolute = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($f)
$Script:logfile = $fAbsolute

# This will be changed with the first override
$Script:logfileOverride = $false
$Script:processIdOverride = $false
