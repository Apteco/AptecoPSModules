﻿
<#PSScriptInfo

.VERSION 0.2.0

.GUID 06dbc814-edfe-4571-a01f-f4091ff5f3c2

.AUTHOR florian.von.bracht@apteco.de

.COMPANYNAME Apteco GmbH

.COPYRIGHT (c) 2025 Apteco GmbH. All rights reserved.

.TAGS "PSEdition_Desktop", "Windows", "Apteco"

.LICENSEURI https://gist.github.com/gitfvb/58930387ee8677b5ccef93ffc115d836

.PROJECTURI https://github.com/Apteco/AptecoPSModules/tree/main/Import-Dependencies

.ICONURI https://www.apteco.de/sites/default/files/favicon_3.ico

.EXTERNALMODULEDEPENDENCIES WriteLog

.REQUIREDSCRIPTS

.EXTERNALSCRIPTDEPENDENCIES

.RELEASENOTES
0.2.0 Added support for loading runtimes with Windows ARM64 architecture
0.1.4 Removed to not load WriteLog module as it is already required here
      Changed Get-LogfileOverride to new parameter KeepLogfile as WriteLog is loaded
        in this script and Get-LogfileOverride will always be the default value
0.1.3 Change the last message to VERBOSE instead of INFO
0.1.2 Fixed temporary module and script path loading
0.1.1 Improved the missing module load
0.1.0 Improving documentation, adding PATH variables, missing modules will not throw an error anymore
0.0.8 Added a parameter switch to suppress warnings to host
0.0.7 Added a note in the log that a runtime was only possibly loaded
0.0.6 Checking 64bit of OS and process
      Output last error when using Kernel32
      Adding runtime errors to log instead of console
0.0.5 Make sure Get-Package is from PackageManagement and NOT VS
0.0.4 Make sure to reuse a log, if already set
0.0.3 Minor Improvements
      Status information at the end
      Differentiation between .net core and windows/desktop priorities
0.0.2 Fixed a problem with out commented input parameters
0.0.1 Initial release of this script

.PRIVATEDATA

#>

#Requires -Module WriteLog

<#
.SYNOPSIS
    Imports modules and global/local packages. Local packages are loaded by default from the .\lib folder in the current directory
.DESCRIPTION
    Script to import dependencies from the PowerShell Gallery and NuGet.

    Please make sure to have the Modules WriteLog and PowerShellGet (>= 2.2.4) installed.

.EXAMPLE
    Import-Dependencies -Module WriteLog, AptecoPSFramework
.EXAMPLE
    Import-Dependencies -GlobalPackage MailKit
.EXAMPLE
    Import-Dependencies -LocalPackage MimeKit, Mailkit
.EXAMPLE
    Import-Dependencies -LocalPackageFolder lib -LoadWholePackageFolder # the default is a lib subfolder, so that does not need to be used

.PARAMETER Module
    Array of modules to install on local machine via PowerShellGallery.
.PARAMETER GlobalPackage
    Array of NuGet packages to install on local machine.
.PARAMETER LocalPackage
    Array of NuGet packages to install in a subfolder of the current folder. Can be changed with parameter LocalPackageFolder.
.PARAMETER LocalPackageFolder
    Folder name of the local package folder. Default is "lib".
.PARAMETER InstallScriptAndModuleForCurrentUser
    By default, the modules and scripts will be installed for all users. If you want to install them only for the current user, then set this parameter to $true.
.PARAMETER SuppressWarnings
    Flag to log warnings, but not put redirect to the host
.NOTES
    Created by : gitfvb
.LINK
    Project Site: https://github.com/Apteco/Install-Dependencies/tree/main/Import-Dependencies

#>

[CmdletBinding()]
Param(

     #[Parameter(Mandatory=$false)][ValidateNotNullOrEmpty()][String[]]$Script = [Array]@()              # Define specific scripts you want to load -> not needed as PATH will be added

     [Parameter(Mandatory=$false)][ValidateNotNullOrEmpty()]
     [String[]]$Module = [Array]@()              # Define specific modules you want to load

    ,[Parameter(Mandatory=$false)][ValidateNotNullOrEmpty()]
     [String[]]$GlobalPackage = [Array]@()       # Define specific global package to load

    ,[Parameter(Mandatory=$false)][ValidateNotNullOrEmpty()]
     [String[]]$LocalPackage = [Array]@()        # Define a specific local package to load

    ,[Parameter(Mandatory=$false)][ValidateNotNullOrEmpty()]
     [String]$LocalPackageFolder = "lib"         # Where to find local packages

    ,[Parameter(Mandatory=$false)][ValidateNotNullOrEmpty()]
     [Switch]$LoadWholePackageFolder = $false    # Load whole local package folder

    ,[Parameter(Mandatory=$false)][ValidateNotNullOrEmpty()]
     [Switch]$SuppressWarnings = $false           # Flag to log warnings, but not put redirect to the host

    ,[Parameter(Mandatory=$false)][ValidateNotNullOrEmpty()]
     [Switch]$KeepLogfile = $false           # Flag to log warnings, but not put redirect to the host

)


#-----------------------------------------------
# DEBUG
#-----------------------------------------------
<#
Set-Location -Path "C:\Users\Florian\Downloads\dep2"
$Module = [Array]@()              # Define specific modules you want to load
$GlobalPackage = [Array]@()       # Define specific global package to load
$LocalPackage = [Array]@()        # Define a specific local package to load
$LocalPackageFolder = "lib"         # Where to find local packages
$LoadWholePackageFolder = $true    # Load whole local package folder
$VerbosePreference = "Continue"
#>


#-----------------------------------------------
# INPUT DEFINITION
#-----------------------------------------------

# TODO fill out

# SETTTINGS FOR LOADING PACKAGES
# TODO [ ] Define a priority later for .net versions, but use fixed ones at the moment
# These lists will be checked in the defined order
$dotnetDesktopVersions = @("net48","net47","net462","netstandard2.1","netstandard2.0","netstandard1.5","netstandard1.3","netstandard1.1","netstandard1.0")
$dotnetCoreVersions = @("net6.0","net6.0-windows","net5.0","net5.0-windows","netcore50")
$targetFolders = @("ref","lib")
#$runtimes = @("win-x64","win-x86","win10","win7","win")


#-----------------------------------------------
# START
#-----------------------------------------------

# TODO use the parent logfile if used by a module
$processStart = [datetime]::now
If ( $KeepLogfile -eq $false ) {
    $currentLogfile = Get-Logfile
	$logfile = ".\dependencies_import.log"
    Set-Logfile -Path $logfile
    Write-Log -message "----------------------------------------------------" -Severity VERBOSE
	Write-Log -Message "Changed logfile from '$( $currentLogfile.fullname )' to '$( $logfile )'"
}

# Remember the current processID
$processId = Get-ProcessId

$writeToHost = $true
If ( $SuppressWarnings -eq $true ) {
    $writeToHost = $false
}


#-----------------------------------------------
# DOING SOME CHECKS
#-----------------------------------------------

# Check if this is Pwsh Core
$isCore = ($PSVersionTable.Keys -contains "PSEdition") -and ($PSVersionTable.PSEdition -ne 'Desktop')

Write-Log -Message "Using PowerShell version $( $PSVersionTable.PSVersion.ToString() ) and $( $PSVersionTable.PSEdition ) edition"

# Decide which lib priority to use
If ( $isCore -eq $true ) {
    $dotnetVersions = $dotnetCoreVersions + $dotnetDesktopVersions
} else {
    $dotnetVersions = $dotnetDesktopVersions
}

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

Write-Log -Message "Using OS: $( $os )"

# Used code from: https://gist.github.com/asheroto/cfa26dd00177a03c81635ea774406b2b
# Get OS details using Get-CimInstance because the registry key for Name is not always correct with Windows 11
$osDetails = Get-CimInstance -ClassName Win32_OperatingSystem

# Get architecture details of the OS (not the processor)
$architecture = $osDetails.OSArchitecture

# Normalize architecture
if ($architecture -match "(?i)32") {
    $architecture = "x32"
} elseif ($architecture -match "(?i)64" -and $architecture -match "(?i)ARM") {
    $architecture = "ARM64"
} elseif ($architecture -match "(?i)64") {
    $architecture = "x64"
} else {
    $architecture = "Unknown"
}

Write-Log -Message "Using architecture: $( $architecture )"

# Check elevation
if ($os -eq "Windows") {
    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = [Security.Principal.WindowsPrincipal]::new($identity)
    $isElevated = $principal.IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)
    Write-Log -Message "User: $( $identity.Name )"
    Write-Log -Message "Elevated: $( $isElevated )"
} else {
    Write-Log -Message "No user and elevation check due to OS"
}

# Check environment and process
Write-Log -Message "OS is 64bit: $( [System.Environment]::Is64BitOperatingSystem )"
Write-Log -Message "Process is 64bit: $( [System.Environment]::Is64BitProcess )"


#-----------------------------------------------
# LOAD SCRIPTS
#-----------------------------------------------

# Not needed here as they will be loaded through the PATH environment variable
# Make sure to have PowerShellGet >= 2.2.4 so the PATH for the scripts is set or add it like
<#
$scriptPath = @( $Env:Path -split ";" ) + @(
    "$( [System.Environment]::GetEnvironmentVariable("ProgramFiles") )\WindowsPowerShell\Scripts"
    "$( [System.Environment]::GetEnvironmentVariable("ProgramFiles(x86)") )\WindowsPowerShell\Scripts"
    "$( [System.Environment]::GetEnvironmentVariable("USERPROFILE") )\Documents\WindowsPowerShell\Scripts"
)
$Env:Path = ( $scriptPath | Select-Object -unique ) -join ";"
#>


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
# LOAD MODULES
#-----------------------------------------------

$modCount = 0
$successfulModules = [Array]@()
$failedModules = [Array]@()
$Module | Where-Object { $_ -ne "WriteLog" } | ForEach-Object {
    $mod = $_
    try {
        Write-Verbose "Loading $( $mod )"
        Import-Module -Name $mod -ErrorAction Stop
        $successfulModules += $mod
        $modCount += 1
    } catch {
        $failedModules += $mod
        Write-Warning -Message "Failed loading module '$( $mod )'" -Verbose #-Severity WARNING
    }
}


#-----------------------------------------------
# INITIATE LOGGING
#-----------------------------------------------

Set-ProcessId -Id $processId

Write-Log -Message "Loaded $( $modCount ) modules" #-Severity VERBOSE
Write-Log -Message "  Success: $( $successfulModules -join ", " )" #-Severity VERBOSE
Write-Log -Message "  Failed: $( $failedModules -join ", " )" #-Severity VERBOSE


#-----------------------------------------------
# LOAD KERNEL32 FOR ALTERNATIVE DLL LOADING
#-----------------------------------------------

$kernel32Loaded = $false
If ( ( $LocalPackage.Count -gt 0 -or $GlobalPackage.Count -gt 0 -or $LoadWholePackageFolder -eq $true ) -and $os -eq "Windows" ) {

    Add-Type -Language CSharp -TypeDefinition @"
    using System;
    using System.Runtime.InteropServices;

    public static class Kernel32 {
        [DllImport("kernel32.dll", SetLastError = true)]
        public static extern IntPtr LoadLibrary(string lpFileName);
        public static string GetError() { return Marshal.GetLastWin32Error().ToString(); }
        public static bool GetEnv() { return Environment.Is64BitProcess; }

    }
"@

    $kernel32Loaded = $true

    # Log Kernel32 environment
    Write-Log -Message "[kernel32] is 64bit: $( [Kernel32]::GetEnv() )"

}

Write-Log "[kernel32] loaded: $( $kernel32Loaded )"


# Taken from https://www.powershellgallery.com/packages/Az.Storage/5.10.0/Content/Az.Storage.psm1
<#

function Preload-Assembly {
    param (
        [string]
        $AssemblyDirectory
    )
    if($PSEdition -eq 'Desktop' -and (Test-Path $AssemblyDirectory -ErrorAction Ignore))
    {
        try
        {
            Get-ChildItem -ErrorAction Stop -Path $AssemblyDirectory -Filter "*.dll" | ForEach-Object {
                try
                {
                    Add-Type -Path $_.FullName -ErrorAction Ignore | Out-Null
                }
                catch {
                    Write-Verbose $_
                }
            }
        }
        catch {}
    }
}

#>


#-----------------------------------------------
# LOAD LIB FOLDER (DLLs AND ASSEMBLIES)
#-----------------------------------------------

# Find out the right runtimes folders
if ($os -eq "Windows") {
    # Windows specific runtimes
    If ($architecture -eq "x64") {
        $runtimes = @("win-x64")
    } elseif ($architecture -eq "x32") {
        $runtimes = @("win-x86")
    } elseif ($architecture -eq "ARM64") {
        $runtimes = @("win-arm64", "win10-arm64","win7-arm64")
    } else {
        $runtimes = @("win10","win7","win")
    }
} elseif ($os -eq "Linux") {
    # Linux specific runtimes
    $runtimes = @("linux-x64","linux-arm64","linux-arm") # TODO maybe not correct yet
} elseif ($os -eq "MacOS") {
    # MacOS specific runtimes
    $runtimes = @("osx-x64","osx-arm64") # TODO maybe not correct yet
} else {
    # Default runtimes for other OS
    #$runtimes = @("win10","win7","win")
    Write-Log -Message "Unknown OS and architecture. Please check the runtimes manually." -Severity "WARNING"
    $runtimes = [Array]@()
}

Write-Log -Message "Using runtimes in this order: $( $runtimes -join ", " )"

$successCounter = 0
$failureCounter = 0
$runtimeSuccessCounter = 0
$runtimePossibleSuccessCounter = 0
$runtimeFailureCounter = 0

If ( $LocalPackage.Count -gt 0 -or $GlobalPackage.Count -gt 0 -or $LoadWholePackageFolder -eq $true) {

    Write-Log -message "Loading libs..."

    # Load the packages we can find
    If ( $LocalPackage.Count -gt 0 -or $LoadWholePackageFolder -eq $true) {
        $localPackages = PackageManagement\Get-Package -Destination $LocalPackageFolder
    }
    $globalPackages = PackageManagement\Get-Package -ProviderName NuGet

    # Filter the packages
    $packagesToLoad = [System.Collections.ArrayList]@()
    $packagesToLoad.AddRange( @( $globalPackages | Where-Object { $_.Name -in $GlobalPackage } ))

    # Decide whether to load all local packages or just a selection
    If ( $LoadWholePackageFolder -eq $true ) {
        $packagesToLoad.AddRange( @( $localPackages ))
    } else {
        $packagesToLoad.AddRange( @($localPackages | Where-Object { $_.Name -in $LocalPackage } ))
    }

    Write-Log -Message "There are $( $packagesToLoad.Count ) packages to load"

    # Load through the packages objects instead of going through the folders
    $i = 0
    $packagesToLoad | ForEach-Object {

        # This is the whole path to the nupkg, but we can use the parent directory
        $pkg = Get-Item -Path $_.source
        $package = $pkg.Directory

        # Counters
        $packageLoaded = 0
        $loadError = 0

        # Check the package ref folder
        If ( ( Test-Path -Path "$( $package.FullName )/ref" ) -eq $true ) {
            $subfolder = "ref"
            $dotnetVersions | ForEach-Object {
                $dotnetVersion = $_
                #"Checking $( $dotnetVersion )"
                $dotnetFolder = "$( $package.FullName )/$( $subfolder )/$( $dotnetVersion )"
                If ( (Test-Path -Path $dotnetFolder)  -eq $true -and $packageLoaded -eq 0) {
                    Get-ChildItem -Path $dotnetFolder -Filter "*.dll" | ForEach-Object {
                        $f = $_
                        #"Loading $( $f.FullName )"
                        try {
                            Write-Verbose -Message "Loading package ref '$( $f.FullName )'"
                            [void][Reflection.Assembly]::LoadFile($f.FullName)
                            $packageLoaded = 1
                            #"Loaded $( $dotnetFolder )"
                        } catch {
                            Write-Verbose -Message "Failed! Loading package ref '$( $f.FullName )'"
                            $loadError = 1
                        }
                    }
                }
            }
        }


        # Check the package lib folder
        if ( ( Test-Path -Path "$( $package.FullName )/lib" ) -eq $true -and $packageLoaded -eq 0) {
            $subfolder = "lib"
            $dotnetVersions | ForEach-Object {
                $dotnetVersion = $_
                #"Checking $( $dotnetVersion )"
                $dotnetFolder = "$( $package.FullName )/$( $subfolder )/$( $dotnetVersion )"
                If ( (Test-Path -Path $dotnetFolder)  -eq $true -and $packageLoaded -eq 0) {
                    Get-ChildItem -Path $dotnetFolder -Filter "*.dll" | ForEach-Object {
                        $f = $_
                        #"Loading $( $f.FullName )"
                        try {
                            Write-Verbose -Message "Loading package lib '$( $f.FullName )'"
                            [void][Reflection.Assembly]::LoadFile($f.FullName)
                            $packageLoaded = 1
                            #"Loaded $( $dotnetFolder )"
                        } catch {
                            Write-Verbose -Message "Failed! Loading package lib '$( $f.FullName )'"
                            $loadError = 1
                        }
                    }
                }
            }
        }

        # Output the current status
        If ($packageLoaded -eq 1) {
            $successCounter += 1
            #"OK lib/ref $( $f.fullname )"
        } elseif ($loadError -eq 1) {
            #"ERROR lib/ref $( $f.fullname )"
            $failureCounter += 1
        } else {
            #$notLoadedCounter += 1
            #"Not loaded lib/ref $( $package.fullname )"
        }


        # Check the runtimes folder
        $runtimeLoaded = 0
        $runtimePossiblyLoaded = 0
        $runtimeLoadError = 0
        #$useKernel32 = 0
        if ( ( Test-Path -Path "$( $package.FullName )/runtimes" ) -eq $true -and $runtimeLoaded -eq 0) {
            $subfolder = "runtimes"


            $runtimes | ForEach-Object {
                $runtime = $_
                #"Checking $( $dotnetVersion )"
                $runtimeFolder = "$( $package.FullName )/$( $subfolder )/$( $runtime )"
                If ( (Test-Path -Path $runtimeFolder)  -eq $true -and $runtimeLoaded -eq 0) {
                    Get-ChildItem -Path $runtimeFolder -Filter "*.dll" -Recurse | ForEach-Object {
                        $f = $_
                        #"Loading $( $f.FullName )"
                        try {
                            Write-Verbose -Message "Loading package runtime '$( $f.FullName )'"
                            [void][Reflection.Assembly]::LoadFile($f.FullName)
                            $runtimeLoaded = 1
                            #"Loaded $( $dotnetFolder )"
                        } catch [System.BadImageFormatException] {
                            # Try it one more time with LoadLibrary through Kernel, if the kernel was loaded
                            If ( $kernel32Loaded -eq $true ) {
                                Write-Log -Severity "WARNING" -Message "Failed! Using kernel32 for loading package runtime '$( $f.FullName )'" -WriteToHostToo $writeToHost
                                [void][Kernel32]::LoadLibrary($f.FullName)
                                Write-Log -Severity "WARNING" -Message "Last kernel32 error: $( [Kernel32]::GetError() )" -WriteToHostToo $writeToHost # Error list: https://learn.microsoft.com/en-us/windows/win32/debug/system-error-codes--0-499-
                                #Write-Log "$( [Kernel32]::GetEnv() )"
                                $runtimePossiblyLoaded = 1
                            }
                            #$useKernel32 = 1
                        }  catch {
                            $runtimeLoadError = 1
                        }
                    }

                }
            }
        }

        # Log stats
        If ( $runtimeLoaded -eq 1 ) {
            $runtimeSuccessCounter += 1
        } elseif ( $runtimePossiblyLoaded -eq 1 ) {
            $runtimePossibleSuccessCounter += 1
        } elseif ( $runtimeLoadError -eq 1 ) {
            $runtimeFailureCounter += 1
        } else {

        }

        # Write progress
        Write-Progress -Activity "Package load in progress" -Status "$( [math]::Round($i/$packagesToLoad.Count*100) )% Complete:" -PercentComplete ([math]::Round($i/$packagesToLoad.Count*100))
        $i += 1

    }



}


#-----------------------------------------------
# STATUS
#-----------------------------------------------

Write-Log -Message "Load status:"
Write-Log -Message "  Modules loaded: $( $modCount )" #-Severity VERBOSE
Write-Log -Message "  Lib/ref loaded: $( $successCounter )"
Write-Log -Message "  Lib/ref failed: $( $failureCounter )"
Write-Log -Message "  Runtime loaded: $( $runtimeSuccessCounter )"
Write-Log -Message "  Runtime possibly loaded: $( $runtimePossibleSuccessCounter )"
Write-Log -Message "  Runtime failed: $( $runtimeFailureCounter )"

#Add-Type -AssemblyName System.Security


#-----------------------------------------------
# FINISHING
#-----------------------------------------------

$processEnd = [datetime]::now
$processDuration = New-TimeSpan -Start $processStart -End $processEnd
Write-Log -Message "Done! Needed $( [int]$processDuration.TotalSeconds ) seconds in total" #-Severity INFO

Write-Log -Message "Logfile override: $( Get-LogfileOverride )"

If ( $KeepLogfile -eq $false ) {
	Write-Log -Message "Changing logfile back to '$( $currentLogfile.fullname )'"
    Set-Logfile -Path $currentLogfile.fullname
}
