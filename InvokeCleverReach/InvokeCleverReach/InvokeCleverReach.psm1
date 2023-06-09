
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

$Env:PSModulePath = @(
    $Env:PSModulePath
    "$( $Env:ProgramFiles )\WindowsPowerShell\Modules"
    "$( $Env:HOMEDRIVE )\$( $Env:HOMEPATH )\Documents\WindowsPowerShell\Modules"
    "$( $Env:windir )\system32\WindowsPowerShell\v1.0\Modules"
) -join ";"


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
# LOAD NETWORK SETTINGS
#-----------------------------------------------

# Allow only newer security protocols
# hints: https://www.frankysweb.de/powershell-es-konnte-kein-geschuetzter-ssltls-kanal-erstellt-werden/
if ( $Script:settings.changeTLS ) {
    # $AllProtocols = @(    
    #     [System.Net.SecurityProtocolType]::Tls12
    #     #[System.Net.SecurityProtocolType]::Tls13,
    #     #,[System.Net.SecurityProtocolType]::Ssl3
    # )
    [System.Net.ServicePointManager]::SecurityProtocol = @( $Script:settings.allowedProtocols )
}

# TODO look for newer version of this network stuff


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


# Set the variables now
$Script:timestamp = [datetime]::Now
$Script:debugMode = $false
$Script:logDivider = "----------------------------------------------------" # String used to show a new part of the log
$Script:moduleRoot = $PSScriptRoot.ToString()


#-----------------------------------------------
# IMPORT MODULES
#-----------------------------------------------

# Load dependencies
. "$( $PSScriptRoot )/bin/dependencies.ps1"

try {
    $psModules | ForEach-Object {
        $mod = $_
        Import-Module -Name $mod -ErrorAction Stop
    }
} catch {
    Write-Error "Error loading dependencies. Please execute 'Install-CleverReach' now"
    Exit 0
}

# Import-Module xxx
# Import-Module -Name "WriteLog"
# Import-Module -Name "EncryptCredential"
# Import-Module -Name "ConvertUnixTimestamp"


#-----------------------------------------------
# LOAD SECURITY SETTINGS
#-----------------------------------------------

If ($null -ne $Script:settings.keyfile) {
    If ( Test-Path -Path $Script:settings.keyfile -eq $true ) {
        Import-Keyfile -Path $Script:settings.keyfile
    } else {
        Write-Error "Path to keyfile is not valid. Please check your settings json file!"
    }
}


#-----------------------------------------------
# READ IN CONFIG FILES AND VARIABLES
#-----------------------------------------------

Export-ModuleMember -Function $Public.Basename  #+ "Set-Logfile"


#-----------------------------------------------
# SET THE LOGGING
#-----------------------------------------------

# Set a new process id first, but this can be overridden later
Set-ProcessIdentifier -Id ( [guid]::NewGuid().toString() )

# the path for the log file will be set with loading the settings