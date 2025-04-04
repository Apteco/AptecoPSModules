
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
# CHECKING PS AND OS
#-----------------------------------------------

Write-Verbose "Check PowerShell and Operating system" -Verbose

# Check if this is Pwsh Core
$isCore = ($PSVersionTable.Keys -contains "PSEdition") -and ($PSVersionTable.PSEdition -ne 'Desktop')

Write-Verbose -Message "Using PowerShell version $( $PSVersionTable.PSVersion.ToString() ) and $( $PSVersionTable.PSEdition ) edition" -Verbose

# Check the operating system, if Core
if ($isCore -eq $true) {
    $os = If ( $IsWindows -eq $true ) {
        "Windows"
    } elseif ( $IsLinux -eq $true ) {
        "Linux"
    } elseif ( $IsMacOS -eq $true ) {
        "MacOS"
    } else {
        throw "Unknown operating system"
    }
} else {
    # [System.Environment]::OSVersion.VersionString()
    # [System.Environment]::Is64BitOperatingSystem
    $os = "Windows"
}

Write-Verbose -Message "Using OS: $( $os )" -Verbose


#-----------------------------------------------
# ADD MODULE PATH, IF NOT PRESENT
#-----------------------------------------------

$modulePath = @( [System.Environment]::GetEnvironmentVariable("PSModulePath") -split ";" ) + @(
    "$( [System.Environment]::GetEnvironmentVariable("ProgramFiles") )\WindowsPowerShell\Modules"
    "$( [System.Environment]::GetEnvironmentVariable("ProgramFiles(x86)") )\WindowsPowerShell\Modules"
    "$( [System.Environment]::GetEnvironmentVariable("USERPROFILE") )\Documents\WindowsPowerShell\Modules"
    "$( [System.Environment]::GetEnvironmentVariable("windir") )\system32\WindowsPowerShell\v1.0\Modules"
)

# Add the 64bit path, if present. In 32bit the ProgramFiles variables only returns the x86 path
If ( [System.Environment]::GetEnvironmentVariables().keys -contains "ProgramW6432" ) {
    $modulePath += "$( [System.Environment]::GetEnvironmentVariable("ProgramW6432") )\WindowsPowerShell\Modules"
}

# Add pwsh core path
If ( $isCore -eq $true ) {
    If ( [System.Environment]::GetEnvironmentVariables().keys -contains "ProgramW6432" ) {
        $modulePath += "$( [System.Environment]::GetEnvironmentVariable("ProgramW6432") )\powershell\7\Modules"
    }
    $modulePath += "$( [System.Environment]::GetEnvironmentVariable("ProgramFiles") )\powershell\7\Modules"
    $modulePath += "$( [System.Environment]::GetEnvironmentVariable("ProgramFiles(x86)") )\powershell\7\Modules"
}

# Add all paths
# Using $env:PSModulePath for only temporary override
$Env:PSModulePath = @( $modulePath | Sort-Object -unique ) -join ";"


#-----------------------------------------------
# ADD SCRIPT PATH, IF NOT PRESENT
#-----------------------------------------------

#$envVariables = [System.Environment]::GetEnvironmentVariables()
$scriptPath = @( [System.Environment]::GetEnvironmentVariable("Path") -split ";" ) + @(
    "$( [System.Environment]::GetEnvironmentVariable("ProgramFiles") )\WindowsPowerShell\Scripts"
    "$( [System.Environment]::GetEnvironmentVariable("ProgramFiles(x86)") )\WindowsPowerShell\Scripts"
    "$( [System.Environment]::GetEnvironmentVariable("USERPROFILE") )\Documents\WindowsPowerShell\Scripts"
)

# Add the 64bit path, if present. In 32bit the ProgramFiles variables only returns the x86 path
If ( [System.Environment]::GetEnvironmentVariables().keys -contains "ProgramW6432" ) {
    $scriptPath += "$( [System.Environment]::GetEnvironmentVariable("ProgramW6432") )\WindowsPowerShell\Scripts"
}

# Add pwsh core path
If ( $isCore -eq $true ) {
    If ( [System.Environment]::GetEnvironmentVariables().keys -contains "ProgramW6432" ) {
        $scriptPath += "$( [System.Environment]::GetEnvironmentVariable("ProgramW6432") )\powershell\7\Scripts"
    }
    $scriptPath += "$( [System.Environment]::GetEnvironmentVariable("ProgramFiles") )\powershell\7\Scripts"
    $scriptPath += "$( [System.Environment]::GetEnvironmentVariable("ProgramFiles(x86)") )\powershell\7\Scripts"
}

# Using $env:Path for only temporary override
$Env:Path = @( $scriptPath | Sort-Object -unique ) -join ";"


#-----------------------------------------------
# LOAD NETWORK SETTINGS
#-----------------------------------------------

# Allow only newer security protocols
# hints: https://www.frankysweb.de/powershell-es-konnte-kein-geschuetzter-ssltls-kanal-erstellt-werden/
#if ( $Script:settings.changeTLS ) {
    # $AllProtocols = @(
    #     [System.Net.SecurityProtocolType]::Tls12
    #     #[System.Net.SecurityProtocolType]::Tls13,
    #     #,[System.Net.SecurityProtocolType]::Ssl3
    # )
#    [System.Net.ServicePointManager]::SecurityProtocol = @( $Script:settings.allowedProtocols )
#}

# TODO look for newer version of this network stuff


#-----------------------------------------------
# LOAD PUBLIC AND PRIVATE FUNCTIONS
#-----------------------------------------------

#$Plugins  = @( Get-ChildItem -Path "$( $PSScriptRoot )/plugins/*.ps1" -Recurse -ErrorAction SilentlyContinue )
$Public  = @( Get-ChildItem -Path "$( $PSScriptRoot )/public/*.ps1" -Recurse -ErrorAction SilentlyContinue )
$Private = @( Get-ChildItem -Path "$( $PSScriptRoot )/private/*.ps1" -Recurse -ErrorAction SilentlyContinue )

# dot source the files
@( $Public + $Private ) | ForEach-Object {
    $import = $_
    Write-Verbose "Load $( $import.fullname )"
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
New-Variable -Name timestamp -Value $null -Scope Script -Force      # Start time of this module
New-Variable -Name logDivider -Value $null -Scope Script -Force     # String of dashes to use in logs
New-Variable -Name moduleRoot -Value $null -Scope Script -Force     # Current location root of this module

# Set the variables now
$Script:timestamp = [datetime]::Now
$Script:logDivider = "----------------------------------------------------" # String used to show a new part of the log
$Script:moduleRoot = $PSScriptRoot.ToString()


#-----------------------------------------------
# IMPORT DEPENDENCIES
#-----------------------------------------------

# Load dependencies
. ( Join-Path -Path $PSScriptRoot.ToString() -ChildPath "/bin/dependencies.ps1" )

# Load scripts
# -> They are automatically loaded

# Load modules
try {
    $psModules | ForEach-Object {
        $mod = $_
        Import-Module -Name $mod -ErrorAction Stop
    }
} catch {
    Write-Error "Error loading dependencies. Please execute 'Install-PSOAuth' now"
    Exit 0
}

# TODO For future you need in linux maybe this module for outgrid-view, which is also supported on console only: microsoft.powershell.consoleguitools

# Load packages from current local libfolder
If ( $psPackages.Count -gt 0 ) {
    Import-Dependencies -LoadWholePackageFolder
}

# Load assemblies
$psAssemblies | ForEach-Object {
    $ass = $_
    Add-Type -AssemblyName $ass
}


#-----------------------------------------------
# LOAD SECURITY SETTINGS
#-----------------------------------------------

<#
If ("" -ne $Script:settings.keyfile) {
    If ( Test-Path -Path $Script:settings.keyfile -eq $true ) {
        Import-Keyfile -Path $Script:settings.keyfile
    } else {
        Write-Error "Path to keyfile is not valid. Please check your settings json file!"
    }
}
#>


#-----------------------------------------------
# READ IN CONFIG FILES AND VARIABLES
#-----------------------------------------------

Export-ModuleMember -Function $Public.Basename
#Export-ModuleMember -Function $Private.Basename


#-----------------------------------------------
# SET THE LOGGING
#-----------------------------------------------

# Set a new process id first, but this can be overridden later
#Set-ProcessId -Id ( [guid]::NewGuid().toString() )

# the path for the log file will be set with loading the settings
#Set-Logfile -Path ( Join-Path $Env:Temp -ChildPath "/psoauth.log" )