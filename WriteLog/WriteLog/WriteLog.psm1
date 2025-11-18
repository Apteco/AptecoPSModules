
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
New-Variable -Name valueStore -Value $null -Scope Script -Force
New-Variable -Name defaultOutputFormat -Value $null -Scope Script -Force
New-Variable -Name defaultTimestampFormat -Value $null -Scope Script -Force
New-Variable -Name additionalLogs -Value $null -Scope Script -Force

# This will be overridden later
$Script:processId = [guid]::NewGuid().ToString()

# TODO maybe later save these settings in a config file
$Script:defaultTimestampFormat = "yyyyMMddHHmmss" #"yyyy-MM-dd HH:mm:ss.fff"
$Script:defaultOutputFormat = "TIMESTAMP`tPROCESSID`tSEVERITY`tMESSAGE"

# Find out the temporary directory
# TODO Support for MacOS
$tmpdir = Get-TemporaryPath
$f = Join-Path -Path $tmpdir -ChildPath "$( $Script:processId ).tmp"
$fAbsolute = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($f)
$Script:logfile = $fAbsolute

# This will be changed with the first override
$Script:logfileOverride = $false
$Script:processIdOverride = $false

$Script:additionalLogs = [System.Collections.ArrayList]@()


#-----------------------------------------------
# FILL VALUE STORE WITH DEFAULT VALUES
#-----------------------------------------------

$identity = [Security.Principal.WindowsIdentity]::GetCurrent()
$executingUser = $identity.Name
$principal = [Security.Principal.WindowsPrincipal]::new($identity)
$isElevated = $principal.IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)

$Script:valueStore = [Hashtable]@{
    "64BITOS" = If ( [System.Environment]::Is64BitOperatingSystem ) { "64BitOS" } Else { "32BitOS" }
    "64BITPROC" = If ( [System.Environment]::Is64BitProcess ) { "64BitProcess" } Else { "32BitProcess" }
    "USER" = $executingUser
    "MACHINE" = [System.Environment]::MachineName
    "PSVERSION" = $psversiontable.PSVersion.toString()
    "ISELEVATED" = If ( $isElevated ) { "Elevated" } Else { "NotElevated" }
    "SYSTEMPROCESSID" = [System.Diagnostics.Process]::GetCurrentProcess().Id
}
