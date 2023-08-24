
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

$defaultsettingsFile = Join-Path -Path $PSScriptRoot -ChildPath "/settings/defaultsettings.ps1"
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
#New-Variable -Name execPath -Value $null -Scope Script -Force       # Path of the calling script
New-Variable -Name processId -Value $null -Scope Script -Force      # GUID process ID to identify log messages that belong to one process
New-Variable -Name timestamp -Value $null -Scope Script -Force      # Start time of this module
New-Variable -Name debugMode -Value $null -Scope Script -Force      # Debug mode switch
New-Variable -Name logDivider -Value $null -Scope Script -Force     # String of dashes to use in logs
New-Variable -Name moduleRoot -Value $null -Scope Script -Force     # Current location root of this module
New-Variable -Name debug -Value $null -Scope Script -Force          # Debug variable where you can put in any variables to read after executing the script, good for debugging

# Set the variables now
$Script:timestamp = [datetime]::Now
$Script:debugMode = $false
$Script:logDivider = "----------------------------------------------------" # String used to show a new part of the log
$Script:moduleRoot = $PSScriptRoot.ToString()


#-----------------------------------------------
# IMPORT DEPENDENCIES
#-----------------------------------------------

Write-Verbose "Loading dependencies..."

# Load dependencies
. ( Join-Path -Path $PSScriptRoot.ToString() -ChildPath "/bin/dependencies.ps1" )

try {

    # $psScripts | ForEach-Object {
    #     $mod = $_
    #     Import-Script -Name $mod -ErrorAction Stop
    # }

    $psModules | ForEach-Object {
        $mod = $_
        Import-Module -Name $mod -ErrorAction Stop
    }

    $psAssemblies | ForEach-Object {
        $assembly = $_
        Add-Type -AssemblyName $assembly -ErrorAction Stop
    }

} catch {

    Write-Error "Error loading dependencies. Please execute 'Install-InvokeGeocoding' now"
    Exit 0
    
}

# TODO For future you need in linux maybe this module for outgrid-view, which is also supported on console only: microsoft.powershell.consoleguitools


#-----------------------------------------------
# LOAD KERNEL32 FOR ALTERNATIVE DLL LOADING
#-----------------------------------------------

Write-Verbose "Loading kernel32..."

Add-Type @"
    using System;
    using System.Runtime.InteropServices;
    
    public static class Kernel32 {
        [DllImport("kernel32")]
        public static extern IntPtr LoadLibrary(string lpFileName);
    }    
"@


#-----------------------------------------------
# LOAD LIB FOLDER (DLLs AND ASSEMBLIES)
#-----------------------------------------------

Write-Verbose "Loading libs..."

# TODO [ ] Define a priority later for .net versions, but use fixed ones at the moment
# These lists will be checked in the defined order
$dotnetVersions = @("net6.0","net6.0-windows","net5.0","net5.0-windows","netcore50","netstandard2.1","netstandard2.0","netstandard1.5","netstandard1.3","netstandard1.1","netstandard1.0")
$targetFolders = @("ref","lib")
$runtimes = @("win-x64","win-x86","win10","win7","win")

Get-ChildItem -Path ".\lib" -Directory | ForEach {

    $package = $_
    #"Checking package $( $package.BaseName )"
    $packageLoaded = 0
	$loadError = 0

    # Check the ref folder
    If ( ( Test-Path -Path "$( $package.FullName )/ref" ) -eq $true ) {
        $subfolder = "ref"
        $dotnetVersions | ForEach {
            $dotnetVersion = $_
		    #"Checking $( $dotnetVersion )"
            $dotnetFolder = "$( $package.FullName )/$( $subfolder )/$( $dotnetVersion )"
            If ( (Test-Path -Path $dotnetFolder)  -eq $true -and $packageLoaded -eq 0) {
                Get-ChildItem -Path $dotnetFolder -Filter "*.dll" | ForEach {
                    $f = $_
			        #"Loading $( $f.FullName )"                    
                    try {
                        [void][Reflection.Assembly]::LoadFile($f.FullName)
                        $packageLoaded = 1
                        #"Loaded $( $dotnetFolder )"
                    } catch {
                        $loadError = 1
                    }
                }                
            }
        }
    }
    
    # Check the lib folder
    if ( ( Test-Path -Path "$( $package.FullName )/lib" ) -eq $true -and $packageLoaded -eq 0) {
        $subfolder = "lib"
        $dotnetVersions | ForEach {
            $dotnetVersion = $_
		    #"Checking $( $dotnetVersion )"
            $dotnetFolder = "$( $package.FullName )/$( $subfolder )/$( $dotnetVersion )"
            If ( (Test-Path -Path $dotnetFolder)  -eq $true -and $packageLoaded -eq 0) {
                Get-ChildItem -Path $dotnetFolder -Filter "*.dll" | ForEach {
                    $f = $_
			        #"Loading $( $f.FullName )"                    
                    try {
                        [void][Reflection.Assembly]::LoadFile($f.FullName)
                        $packageLoaded = 1
                        #"Loaded $( $dotnetFolder )"
                    } catch {
                        $loadError = 1
                    }
                }
                
                
            }
        }
    }
    <#
    # Output the current status
	If ($packageLoaded -eq 1) {
	    "OK lib/ref $( $f.fullname )"
    } elseif ($loadError -eq 1) {
	    "ERROR lib/ref $( $f.fullname )"
    } else {
        #"Not loaded lib/ref $( $package.fullname )"
    }
    #>
    # Check the runtimes folder
    $runtimeLoaded = 0
    $runtimeLoadError = 0
    #$useKernel32 = 0
    if ( ( Test-Path -Path "$( $package.FullName )/runtimes" ) -eq $true -and $runtimeLoaded -eq 0) {
        $subfolder = "runtimes"
        $runtimes | ForEach {
            $runtime = $_
		    #"Checking $( $dotnetVersion )"
            $runtimeFolder = "$( $package.FullName )/$( $subfolder )/$( $runtime )"
            If ( (Test-Path -Path $runtimeFolder)  -eq $true -and $runtimeLoaded -eq 0) {
                Get-ChildItem -Path $runtimeFolder -Filter "*.dll" -Recurse | ForEach {
                    $f = $_
			        #"Loading $( $f.FullName )"                    
                    try {
                        [void][Reflection.Assembly]::LoadFile($f.FullName)
                        $runtimeLoaded = 1
                        #"Loaded $( $dotnetFolder )"
                    } catch [System.BadImageFormatException] {
                        # Try it one more time with LoadLibrary through Kernel
                        [Kernel32]::LoadLibrary($f.FullName)
                        $runtimeLoaded = 1
                        #$useKernel32 = 1
                    }  catch {
                        $runtimeLoadError = 1
                    }
                }
                
                
            }
        }
    }
<#
    If ($runtimeLoaded -eq 1) {
	    "OK runtime $( $f.fullname )"
    } elseif ($runtimeLoadError -eq 1) {
	    "ERROR runtime $( $f.fullname )"
    } else {
    #    "Not loaded runtime for $( $package.fullname )"
    }

    If ( $runtimeLoaded -eq 0 -and $packageLoaded -eq 0 ) {
        "NO $( $package.fullname )"
    } 
#>
    #} else {
    #    #"No ref or lib folder"
    #}

}


#-----------------------------------------------
# LOAD SECURITY SETTINGS
#-----------------------------------------------

If ("" -ne $Script:settings.keyfile) {
    If ( Test-Path -Path $Script:settings.keyfile -eq $true ) {
        Import-Keyfile -Path $Script:settings.keyfile
    } else {
        Write-Error "Path to keyfile is not valid. Please check your settings json file!"
    }
}


#-----------------------------------------------
# READ IN CONFIG FILES AND VARIABLES
#-----------------------------------------------

Export-ModuleMember -Function $Public.Basename


#-----------------------------------------------
# SET THE LOGGING
#-----------------------------------------------

# Set a new process id first, but this can be overridden later
Set-ProcessId -Id ( [guid]::NewGuid().toString() )

# the path for the log file will be set with loading the settings