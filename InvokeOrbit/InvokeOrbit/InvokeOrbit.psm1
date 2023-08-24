
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


#-----------------------------------------------
# LOAD DEFAULT SETTINGS
#-----------------------------------------------

$defaultsettingsFile = "$( $PSScriptRoot )/settings/defaultsettings.ps1"
Try {
    $Script:defaultSettings = [PSCustomObject]( . $defaultsettingsFile )
} Catch {
    Write-Error -Message "Failed to import default settings $( $defaultsettingsFile )"
}
$Script:settings = $Script:defaultSettings


#-----------------------------------------------
# IMPORT MODULES
#-----------------------------------------------

# Import-Module xxx


#-----------------------------------------------
# LOAD PUBLIC AND PRIVATE FUNCTIONS
#-----------------------------------------------

$Public  = @( Get-ChildItem -Path "$( $PSScriptRoot )/Public/*.ps1" -Recurse -ErrorAction SilentlyContinue )
$Private = @( Get-ChildItem -Path "$( $PSScriptRoot )/Private/*.ps1" -Recurse -ErrorAction SilentlyContinue )

# dot source the files
@( $Public + $Private ) | ForEach {
    $import = $_
    Try {
        . $import.fullname
    } Catch {
        Write-Error -Message "Failed to import function $( $import.fullname ): $( $_ )"
    }
}


#-----------------------------------------------
# READ IN CONFIG FILES AND VARIABLES
#-----------------------------------------------

# Define dependencies
#. "$( $PSScriptRoot )/bin/dependencies.ps1"

# TODO [ ] setup the Set-TLS.ps1 file


#-----------------------------------------------
# READ IN CONFIG FILES AND VARIABLES
#-----------------------------------------------

# Set DataView
# $dataview = $settings.login.dataView
# $fsSystem = $settings.fsSystem
# $psSystem = $settings.psSystem


#-----------------------------------------------
# READ IN CONFIG FILES AND VARIABLES
#-----------------------------------------------

Export-ModuleMember -Function $Public.Basename



#-----------------------------------------------
# SET SOME VARIABLES ONLY VISIBLE TO MODULE AND FUNCTIONS
#-----------------------------------------------

# Define the variables
New-Variable -Name execPath -Value $null -Scope Script -Force       # Path of the calling script
New-Variable -Name processId -Value $null -Scope Script -Force      # GUID process ID to identify log messages that belong to one process
New-Variable -Name timestamp -Value $null -Scope Script -Force      # Start time of this module
New-Variable -Name debugMode -Value $null -Scope Script -Force      # Debug mode switch
New-Variable -Name logDivider -Value $null -Scope Script -Force     # String of dashes to use in logs
New-Variable -Name moduleRoot -Value $null -Scope Script -Force     # Current location root of this module
New-Variable -Name debug -Value $null -Scope Script -Force          # Current location root of this module

New-Variable -Name endpoints -Value $null -Scope Script -Force      # List of endpoints for the API

# Set the variables now
$Script:timestamp = [datetime]::Now
$Script:debugMode = $false
$Script:logDivider = "----------------------------------------------------" # String used to show a new part of the log
$Script:moduleRoot = $PSScriptRoot.ToString()


#-----------------------------------------------
# SET THE LOGGING
#-----------------------------------------------

# Set a new process id first, but this can be overridden later
Set-ProcessIdentifier -Id ( [guid]::NewGuid().toString() )

# the path for the log file will be set with loading the settings

#-----------------------------------------------
# SET SOME VARIABLES ONLY VISIBLE TO MODULE AND FUNCTIONS
#-----------------------------------------------

$Script:Endpoints = $null


