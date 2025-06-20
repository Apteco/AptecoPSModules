﻿
<#PSScriptInfo

.VERSION 0.1.9

.GUID 4c029c8e-09fa-48ee-9d62-10895150ce83

.AUTHOR florian.von.bracht@apteco.de

.COMPANYNAME Apteco GmbH

.COPYRIGHT (c) 2024 Apteco GmbH. All rights reserved.

.TAGS "PSEdition_Desktop", "Windows", "Apteco"

.LICENSEURI https://gist.github.com/gitfvb/58930387ee8677b5ccef93ffc115d836

.PROJECTURI https://github.com/Apteco/AptecoPSModules/tree/main/Install-Dependencies

.ICONURI https://www.apteco.de/sites/default/files/favicon_3.ico

.EXTERNALMODULEDEPENDENCIES WriteLog

.REQUIREDSCRIPTS

.EXTERNALSCRIPTDEPENDENCIES

.RELEASENOTES
0.1.9 Changing default name for NuGet repository to "NuGet v2"
0.1.8 Removed the admin elevated check for local packages/modules/scripts
0.1.7 Added a switch when setting the logfile if it should be overridden or not
0.1.6 Fixed script and m odule version checking
0.1.5 Fixed script version checking
0.1.4 Fixed temporary module and script path loading
0.1.3 Added common module and script paths
0.1.2 Fixed another check of PackageManagement
0.1.1 Fixed check of PackageManagement. Fixed Scripts check. Fixed version check for scripts and modules
0.1.0 Bumping to new version and checking PowerShellGet and PackageManagement dependencies
0.0.11 Fixed the way to install scripts and modules with names instead of pipeline
0.0.10 Added the flag -ExcludeDependencies
0.0.9 Bumped the copyright year to 2024
0.0.8 Fixed wrong formatted output
0.0.7 Allowed empty arrays for wrapping the script into other modules
      Changed internal function prompt-choice to request-choice to only allow approved verbs
0.0.6 Admin privileges are now checked in another way and is not needed for local packages anymore
      Fix for installation if package names are strings
      Adding status information at the end
0.0.5 Fix of rounded status percentage
0.0.4 Changed the way to temporarily save packages when an error happens in dependency check
0.0.3 Some bigger changes for getting it to run
0.0.2 Ignore already installed global packages because they would need to be loaded first
0.0.1 Initial release of this script

.PRIVATEDATA

#>

#Requires -Module WriteLog
#Requires -Module @{ModuleName = 'PowerShellGet'; ModuleVersion = '2.0'}
#Requires -Module @{ModuleName = 'PackageManagement'; ModuleVersion = '1.4'}

<#

.DESCRIPTION
 Downloads and installs the latest versions of some scripts, modules and packages (saved in current folder of machine folder) from the PowerShell Gallery and NuGet.

#>


# The admin rights are only needed for modules and scripts and global packages, but not local packages, but this way we can ensure everythings in the right place


<#
.SYNOPSIS
    Downloads and installs the latest versions of some scripts, modules and packages (saved in current folder of machine folder) from the PowerShell Gallery and NuGet.
.DESCRIPTION
    Script to install dependencies from the PowerShell Gallery and NuGet. It is possible to install scripts, modules and packages.
    The packages can be installed from the PowerShell Gallery and packages from a NuGet repository.
    Packages can defined as a raw string array or as a pscustomobject with a specific version number.

    Please make sure to have the Modules WriteLog and PowerShellGet (>= 2.2.4) installed.

.EXAMPLE
    Install-Dependencies -Module "WriteLog" -LocalPackage "SQLitePCLRaw.core", "Npgsql" -Verbose
.EXAMPLE
    $packages = [Array]@(
        [PSCustomObject]@{
            name="Npgsql"
            version = "4.1.12"
            includeDependencies = $true
        }
    )
    Install-Dependencies -Module "WriteLog" -LocalPackage $packages -Verbose

.PARAMETER Script
    Array of scripts to install on local machine via PowerShellGallery.
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
.PARAMETER ExcludeDependencies
    By default, this script is installing dependencies for every nuget package. This can be deactivated with this switch
.NOTES
    Created by : gitfvb
.LINK
    Project Site: https://github.com/Apteco/Install-Dependencies/tree/main/Install-Dependencies
#>


[CmdletBinding()]
Param(
     [Parameter(Mandatory=$false)][String[]]$Script = [Array]@()
    ,[Parameter(Mandatory=$false)][String[]]$Module = [Array]@()
    ,[Parameter(Mandatory=$false)][String[]]$GlobalPackage = [Array]@()
    ,[Parameter(Mandatory=$false)][String[]]$LocalPackage = [Array]@()
    ,[Parameter(Mandatory=$false)][String]$LocalPackageFolder = "lib"
    ,[Parameter(Mandatory=$false)][Switch]$InstallScriptAndModuleForCurrentUser = $false
    ,[Parameter(Mandatory=$false)][Switch]$ExcludeDependencies = $false
)


#-----------------------------------------------
# DEBUG
#-----------------------------------------------

<#
Set-Location -Path "C:\Users\Florian\Downloads\20230918"

$Script = [Array]@()
$Module = [Array]@()
$GlobalPackage = [Array]@()
$LocalPackage = [Array]@("npgsql")
$LocalPackageFolder = "lib"
$InstallScriptAndModuleForCurrentUser = $false
$VerbosePreference = "Continue"
#>


# TODO check if we can check if this is an admin user rather than enforce it
# TODO use write log instead of write verbose?

#-----------------------------------------------
# INPUT DEFINITION
#-----------------------------------------------


<#

$psScripts = @(
    #"WriteLogfile"
)

$psModules = @(
    "WriteLog"
    "MeasureRows"
    "EncryptCredential"
    "ExtendFunction"
    "ConvertUnixTimestamp"
    #"Microsoft.PowerShell.Utility"
)

# Define either a simple string or provide a pscustomobject with a specific version number
$psPackages = @(
    [PSCustomObject]@{
        name="Npgsql"
        version = "4.1.12"
        includeDependencies = $true
        type = "local"  # local|global
    }
#>

<#

Example to use

$stringArray = @("Frankfurt","Aachen","Braunschweig")
$choice = Request-Choice -title "City" -message "Which city would you prefer?" -choices $stringArray
$choiceMatchedWithArray = $stringArray[$choice -1]

# TODO [ ] put this into a module

#>

# Add a time measure

#-----------------------------------------------
# FUNCTIONS
#-----------------------------------------------

Function Request-Choice {

    param(
         [Parameter(Mandatory=$true)][string]$title
        ,[Parameter(Mandatory=$true)][string]$message
        ,[Parameter(Mandatory=$true)][string[]]$choices
        ,[Parameter(Mandatory=$false)][int]$defaultChoice = 0
    )

    $i = 1
    $choicesConverted = [System.Collections.ArrayList]@()
    $choices | ForEach-Object {
        $choice = $_
        [void]$choicesConverted.add((New-Object System.Management.Automation.Host.ChoiceDescription "`b&$( $i ) - $( $choice )`n" )) # putting a string afterwards shows it as a help message
        $i += 1
    }
    $options = [System.Management.Automation.Host.ChoiceDescription[]]$choicesConverted
    $result = $host.ui.PromptForChoice($title, $message, $options, $defaultChoice)

    return $result +1 # add one for index

}


#-----------------------------------------------
# START
#-----------------------------------------------

$processStart = [datetime]::now
If ( ( Get-LogfileOverride ) -eq $false ) {
    Set-Logfile -Path ".\dependencies_install.log"
    Write-Log -message "----------------------------------------------------" -Severity VERBOSE
}


#-----------------------------------------------
# TEST
#-----------------------------------------------

#Write-Warning "Please make sure to start this script as administrator!"
# Write-Verbose "hello world"
# write-verbose $PSScriptRoot

# exit 0

#-----------------------------------------------
# DOING SOME CHECKS
#-----------------------------------------------

# Check if this is Pwsh Core
$isCore = ($PSVersionTable.Keys -contains "PSEdition") -and ($PSVersionTable.PSEdition -ne 'Desktop')
$psVersion = $psversiontable.psversion

Write-Log -Message "Using PowerShell version $( $PSVersionTable.PSVersion.ToString() ) and $( $PSVersionTable.PSEdition ) edition"


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


# Check execution policy
$executionPolicy = Get-ExecutionPolicy
Write-Log -Message "Your execution policy is currently: $( $executionPolicy )" -Severity VERBOSE

# Check if elevated rights are needed
#If (( $GlobalPackage.Count -gt 0 -or $Module.Count -gt 0 -or $Script.count -gt 0 ) -and $isElevated -eq $false) {
If ( $GlobalPackage.Count -gt 0 -and $isElevated -eq $false) {
    throw "To install global packages, you need elevated rights, so please restart PowerShell with Administrator privileges!"
}


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
# NUGET SETTINGS
#-----------------------------------------------

$packageSourceName = "NuGet v2" # otherwise you could create a local repository and put all dependencies in there. You can find more infos here: https://github.com/Apteco/HelperScripts/tree/master/functions/Log#installation-via-local-repository
$packageSourceLocation = "https://www.nuget.org/api/v2"
$packageSourceProviderName = "NuGet"

# TODO [x] allow local repositories


#-----------------------------------------------
# POWERSHELL GALLERY SETTINGS
#-----------------------------------------------

$powerShellSourceName = "PSGallery" # otherwise you could create a local repository and put all dependencies in there. You can find more infos here: https://github.com/Apteco/HelperScripts/tree/master/functions/Log#installation-via-local-repository
$powerShellSourceLocation = "https://www.powershellgallery.com/api/v2"
$powerShellSourceProviderName = "PowerShellGet"
If ( $InstallScriptAndModuleForCurrentUser -eq $true ) {
    $psScope = "CurrentUser" # CurrentUser|AllUsers
} else {
    $psScope = "AllUsers" # CurrentUser|AllUsers
}

Write-Log -Message "Using installation scope: $( $psScope )" -Severity VERBOSE


#-----------------------------------------------
# CHECK POWERSHELL GALLERY REPOSITORY
#-----------------------------------------------

If ( $Script.Count -gt 0 -or $Module.Count -gt 0 ) {
    $powershellRepo = @( Get-PackageSource -ProviderName $powerShellSourceProviderName ) #@( Get-PSRepository -ProviderName $powerShellSourceProviderName ) #@( Get-PSRepository | where { $_.SourceLocation -like "https://www.powershellgallery.com*" } )
    If ( $powershellRepo.Count -eq 0 ) {
        Write-Log "No module/script repository found! Please make sure to add a repository to your machine!" -Severity WARNING
    }
}

# Install newer PackageManagement
$currentPM = get-installedmodule | where-object { $_.Name -eq "PackageManagement" }
If ( $currentPM.Version -eq "1.0.0.1" -or $currentPM.Count -eq 0 ) {
    Write-Log "PackageManagement is outdated with v$( $currentPM.Version ). This is updating it now." -Severity WARNING
    #Install-Module PackageManagement -Force -Verbose -AllowClobber
    Install-Package -Name PackageManagement -Force
}

# Install newer PowerShellGet version when it is the default at 1.0.0.1
$currentPSGet = get-installedmodule | where-object { $_.Name -eq "PowerShellGet" }
If ( $currentPSGet.Version -eq "1.0.0.1" -or $currentPSGet.Count -eq 0 ) {
    Write-Log "PowerShellGet is outdated with v$( $currentPSGet.Version ). This is updating it now." -Severity WARNING
    #Install-Module PowerShellGet -Force -Verbose -AllowClobber
    Install-Package -Name PowerShellGet -Force
}

If ( $Script.Count -gt 0 -or $Module.Count -gt 0 ) {

    try {

        # Get PowerShellGet sources
        $powershellRepo = @( Get-PackageSource -ProviderName $powerShellSourceProviderName ) #@( Get-PSRepository -ProviderName $powerShellSourceProviderName )

        # See if PSRepo needs to get registered
        If ( $powershellRepo.count -ge 1 ) {
            Write-Log -Message "You have at minimum 1 $( $powerShellSourceProviderName ) repository. Good!"  -Severity VERBOSE
        } elseif ( $powershellRepo.count -eq 0 ) {
            Write-Log -Message "You don't have $( $powerShellSourceProviderName ) as a module/script source, do you want to register it now?" -Severity WARNING
            $registerPsRepoDecision = $Host.UI.PromptForChoice("", "Register $( $powerShellSourceProviderName ) as repository?", @('&Yes'; '&No'), 1)
            If ( $registerPsRepoDecision -eq "0" ) {

                # Means yes and proceed
                Register-PSRepository -Name $powerShellSourceName -SourceLocation $powerShellSourceLocation
                #Register-PackageSource -Name $packageSourceName -Location $packageSourceLocation -ProviderName $packageSourceProviderName

                # Load sources again
                $powershellRepo = @( Get-PSRepository -ProviderName $powerShellSourceProviderName )

            } else {
                # Means no and leave
                Write-Log "No package repository found! Please make sure to add a PowerShellGet repository to your machine!" -Severity ERROR
                exit 0
            }
        }

        # Choose repository
        If ( $powershellRepo.count -gt 1 ) {

            $psGetSources = $powershellRepo.Name
            $psGetSourceChoice = Request-Choice -title "Script/module Source" -message "Which $( $powerShellSourceProviderName ) repository do you want to use?" -choices $psGetSources
            $psGetSource = $psGetSources[$psGetSourceChoice -1]

        } elseif ( $powershellRepo.count -eq 1 ) {

            $psGetSource = $powershellRepo[0]

        } else {

            Write-Log -Message "There is no $( $powerShellSourceProviderName ) repository available"  -Severity WARNING
            Exit 0

        }

        # TODO [x] ask if you want to trust the new repository

        # Do you want to trust that source?
        If ( $psGetSource.IsTrusted -eq $false ) {
            Write-Log -Message "Your source is not trusted. Do you want to trust it now?" -Severity WARNING
            $trustChoice = Request-Choice -title "Trust script/module Source" -message "Do you want to trust $( $psGetSource.Name )?" -choices @("Yes", "No")
            If ( $trustChoice -eq 1 ) {
                # Use
                # Set-PSRepository -Name $psGetSource.Name -InstallationPolicy Untrusted
                # To get it to the untrusted status again

                Set-PSRepository -Name $psGetSource.Name -InstallationPolicy Trusted
            }
        }

    } catch {

        Write-Log -Message "There is a problem with the repository check!" -Severity WARNING

    }

}

# TODO [x] allow local repositories


#-----------------------------------------------
# CHECK SCRIPT DEPENDENCIES FOR INSTALLATION AND UPDATE
#-----------------------------------------------

$s = 0
If ( $Script.Count -gt 0 ) {

    # TODO [ ] Add psgallery possibly, too

    try {

        #If ( $ScriptsOnly -eq $true -or ( $PackagesOnly -eq $false -and $ScriptsOnly -eq $false -and $ModulesOnly -eq $false) ) {

        Write-Log "Checking Script dependencies" -Severity VERBOSE

        # SCRIPTS
        #$installedScripts = Get-InstalledScript
        $Script | ForEach-Object {

            $psScript = $_

            Write-Log "Checking script: $( $psScript )" -Severity VERBOSE

            $installedScripts = Get-InstalledScript

            # TODO [ ] possibly add dependencies on version number
            # This is using -force to allow updates

            If ( $ExcludeDependencies -eq $true ) {
                $psScriptDependencies = Find-Script -Name $psScript
            } else {
                $psScriptDependencies = Find-Script -Name $psScript -IncludeDependencies
            }

            #$psScriptDependencies | Where-Object { $_.Name -notin $installedScripts.Name } | Install-Script -Scope AllUsers -Verbose -Force
            $psScriptDependencies | ForEach-Object {

                $scr = $_

                If ( $installedScripts.Name -contains $scr.Name ) {
                    Write-Log -Message "Script $( $scr.Name ) is already installed" -Severity VERBOSE

                    $alreadyInstalledScript = $installedScripts | Where-Object { $_.Name -eq $scr.Name } #| Select -first 1

                    If ( $scr.Version -gt $alreadyInstalledScript.Version ) {
                        Write-Log -Message "Script $( $scr.Name ) is installed with an older version $( $alreadyInstalledScript.Version ) than the available version $( $scr.Version )" -Severity VERBOSE
                        Update-Script -Name $scr.Name
                        $s += 1
                    } else {
                        Write-Log -Message "No need to update $( $scr.Name )" -Severity VERBOSE
                    }
                } else {
                    Write-Log -Message "Installing Script $( $scr.Name )" -Severity VERBOSE
                    Install-Script -Name $scr.Name -Scope $psScope #-Force
                    $s += 1
                }

            }

        }

        #}

    } catch {

        Write-Log -Message "Cannot install scripts!" -Severity WARNING
        #$success = $false

    }

} else {

    Write-Log "There is no script to install" -Severity VERBOSE

}


#-----------------------------------------------
# CHECK MODULES DEPENDENCIES FOR INSTALLATION AND UPDATE
#-----------------------------------------------

$m = 0
If ( $Module.count -gt 0 ) {

    try {

        # PSGallery should have been added automatically yet

        Write-Log "Checking Module dependencies" -Severity VERBOSE

        #$installedModules = Get-InstalledModule
        $Module | Where-Object { $_ -notin @("PowerShellGet","PackageManagement") } | ForEach-Object {

            $psModule = $_

            Write-Log "Checking module: $( $psModule )" -Severity VERBOSE

            $installedModules = Get-InstalledModule

            # TODO [ ] possibly add dependencies on version number
            # This is using -force to allow updates
            If ( $ExcludeDependencies -eq $true ) {
                $psModuleDependencies = Find-Module -Name $psModule #-IncludeDependencies
            } else {
                $psModuleDependencies = Find-Module -Name $psModule -IncludeDependencies
            }
            $psModuleDependencies | ForEach-Object {

                $mod = $_

                If ( $installedModules.Name -contains $mod.Name ) {
                    Write-Log -Message "Module $( $mod.Name ) is already installed" -Severity VERBOSE

                    $alreadyInstalledModule = $installedModules | Where-Object { $_.Name -eq $mod.Name } #| Select -first 1

                    If ( $mod.Version -gt $alreadyInstalledModule.Version ) {
                        Write-Log -Message "Module $( $mod.Name ) is installed with an older version $( $alreadyInstalledModule.Version ) than the available version $( $mod.Version )" -Severity VERBOSE
                        Update-Module -Name $mod.Name
                        $m += 1
                    } else {
                        Write-Log -Message "No need to update $( $mod.Name )" -Severity VERBOSE
                    }
                } else {
                    Write-Log -Message "Installing Module $( $mod.Name )" -Severity VERBOSE
                    Install-Module -Name $mod.Name -Scope $psScope #-Force
                    $m += 1
                }

            }
            #$psModuleDependencies | where { $_.Name -notin $installedModules.Name } | Install-Module -Scope AllUsers -Verbose -Force

        }

    } catch {

        Write-Log -Message "Cannot install modules!" -Severity WARNING

        #Write-Error -Message $_.Exception.Message #-Severity ERROR

    }

} else {

    Write-Log "There is no module to install" -Severity VERBOSE

}


#-----------------------------------------------
# CHECK PACKAGES NUGET REPOSITORY
#-----------------------------------------------

<#

If this module is not installed via nuget, then this makes sense to check again

# Add nuget first or make sure it is set

Register-PackageSource -Name "Nuget v2" -Location "https://www.nuget.org/api/v2" –ProviderName Nuget

# Make nuget trusted
Set-PackageSource -Name NuGet -Trusted

#>

# Get-PSRepository

#Install-Package Microsoft.Data.Sqlite.Core -RequiredVersion 7.0.0-rc.2.22472.11

If ( $GlobalPackage.Count -gt 0 -or $LocalPackage.Count -gt 0 ) {

    try {

        # Get NuGet sources
        $sources = @( Get-PackageSource -ProviderName $packageSourceProviderName ) #| where { $_.Location -like "https://www.nuget.org*" }

        # See if Nuget needs to get registered
        If ( $sources.count -ge 1 ) {
            Write-Log -Message "You have at minimum 1 $( $packageSourceProviderName ) repository. Good!" -Severity VERBOSE
        } elseif ( $sources.count -eq 0 ) {
            Write-Log -Message "You don't have $( $packageSourceProviderName ) as a PackageSource, do you want to register it now?" -Severity WARNING
            $registerNugetDecision = $Host.UI.PromptForChoice("", "Register $( $packageSourceProviderName ) as repository?", @('&Yes'; '&No'), 1)
            If ( $registerNugetDecision -eq "0" ) {

                # Means yes and proceed
                Register-PackageSource -Name $packageSourceName -Location $packageSourceLocation -ProviderName $packageSourceProviderName

                # Load sources again
                $sources = @( Get-PackageSource -ProviderName $packageSourceProviderName ) #| where { $_.Location -like "https://www.nuget.org*" }

            } else {
                # Means no and leave
                Write-Log "No package repository found! Please make sure to add a NuGet repository to your machine!" -Severity ERROR
                exit 0
            }
        }

        # Choose repository
        If ( $sources.count -gt 1 ) {

            $packageSources = $sources.Name
            $packageSourceChoice = Request-Choice -title "PackageSource" -message "Which $( $packageSourceProviderName ) repository do you want to use?" -choices $packageSources
            $packageSource = $sources[$packageSourceChoice -1]

        } elseif ( $sources.count -eq 1 ) {

            $packageSource = $sources[0]

        } else {

            Write-Log -Message "There is no $( $packageSourceProviderName ) repository available" -Severity WARNING
            Exit 0

        }

        # TODO [x] ask if you want to trust the new repository

        # Do you want to trust that source?
        If ( $packageSource.IsTrusted -eq $false ) {
            Write-Log -Message "Your source is not trusted. Do you want to trust it now?" -Severity WARNING
            $trustChoice = Request-Choice -title "Trust Package Source" -message "Do you want to trust $( $packageSource.Name )?" -choices @("Yes", "No")
            If ( $trustChoice -eq 1 ) {
                # Use
                # Set-PackageSource -Name NuGet
                # To get it to the untrusted status again
                Set-PackageSource -Name $packageSource.Name -Trusted
            }
        }

    } catch {

        Write-Log -Message "There is a problem with the repository" -Severity WARNING

    }

}


#-----------------------------------------------
# CHECK LOCAL PACKAGES DEPENDENCIES FOR INSTALLATION AND UPDATE
#-----------------------------------------------

$l = 0
$g = 0
If ( $LocalPackage.count -gt 0 -or $GlobalPackage.Count -gt 0) {

    try {

        Write-Log "Check lib folder" -Severity VERBOSE

        If ( (Test-Path -Path $LocalPackageFolder) -eq $false ) {
            New-Item -Name $LocalPackageFolder -ItemType Directory
        }

        Write-Log "Checking package dependencies with $( $packageSource.Name )" -Severity VERBOSE

        $localPackages = Get-Package -Destination $LocalPackageFolder
        $globalPackages = Get-Package
        $installedPackages = $localPackages + $globalPackages
        $packagesToInstall = [System.Collections.ArrayList]@()
        @( $LocalPackage + $GlobalPackage ) | ForEach-Object {

            $psPackage = $_
            $globalFlag = $false
            $pkg = [System.Collections.ArrayList]@()
            If ( $GlobalPackage -contains $psPackage ) {
                $globalFlag = $true
            } # TODO [ ] Especially test global and local installation

            Write-Log "Checking package: $( $psPackage )" -severity VERBOSE

            # This is using -force to allow updates
            <#
                Use of continue in case of error because sometimes this happens
                AUSFÜHRLICH: Total package yield:'2' for the specified package 'System.ObjectModel'.
                Find-Package : Unable to find dependent package(s) (nuget:Microsoft.NETCore.Platforms/3.1.0)
            #>

            If ( ($psPackage.gettype()).Name -eq "PsCustomObject" ) {
                If ( $null -eq $psPackage.version ) {
                    Write-Verbose "Looking for $( $psPackage.name ) without specific version."
                    If ( $ExcludeDependencies -eq $true ) {
                        [void]@( Find-Package $psPackage.name -Source $packageSource.Name -ErrorAction Continue ).foreach({$pkg.add($_)}) # add elements directly instead of saving everything into a variable
                    } else {
                        [void]@( Find-Package $psPackage.name -IncludeDependencies -Source $packageSource.Name -ErrorAction Continue ).foreach({$pkg.add($_)}) # add elements directly instead of saving everything into a variable
                    }
                } else {
                    Write-Verbose "Looking for $( $psPackage.name ) with version $( $psPackage.version )"
                    If ( $ExcludeDependencies -eq $true ) {
                        [void]@( Find-Package $psPackage.name -Source $packageSource.Name -ErrorAction Continue -RequiredVersion $psPackage.version ).foreach({$pkg.add($_)}) # add elements directly instead of saving everything into a variable
                    } else {
                        [void]@( Find-Package $psPackage.name -IncludeDependencies -Source $packageSource.Name -ErrorAction Continue -RequiredVersion $psPackage.version ).foreach({$pkg.add($_)}) # add elements directly instead of saving everything into a variable
                    }
                }
            } else {
                Write-Verbose "Looking for $( $psPackage ) without specific version"
                If ( $ExcludeDependencies -eq $true ) {
                    [void]@( Find-Package $psPackage -Source $packageSource.Name -ErrorAction Continue ).foreach({$pkg.add($_)}) # add elements directly instead of saving everything into a variable
                } else {
                    [void]@( Find-Package $psPackage -IncludeDependencies -Source $packageSource.Name -ErrorAction Continue ).foreach({$pkg.add($_)}) # add elements directly instead of saving everything into a variable                }
                }
            }

            $pkg | ForEach-Object { # | Where-Object { $_.Name -notin $installedPackages.Name } # | Sort-Object Name, Version -Unique -Descending
                $p = $_
                $pd = [PSCustomObject]@{
                    "GlobalFlag" = $globalFlag
                    "Package" = $p
                    "Name" = $p.Name
                    "Version" = $p.Version
                }
                [void]$packagesToInstall.Add($pd)

            }

        }

        Write-Log -Message "Done with searching for $( $packagesToInstall.Count ) packages"

        # Install the packages now, we only use packages of the current repository, so in there if other repositories are used for cross-reference, this won't work at the moment
        $pack = $packagesToInstall | Where-Object { $_.Package.Summary -notlike "*not reference directly*" -and $_.Package.Name -notlike "Xamarin.*"} | Where-Object { $_.Package.Source -eq $packageSource.Name } | Sort-Object Name, Version -Unique -Descending
        Write-Log -Message "This is likely to install $( $pack.Count ) packages"
        #$packagesToInstall | Where-Object { $_.Source -eq $packageSource.Name -and $_.Name -notin $installedPackages.Name } | Sort-Object Name -Unique | ForEach-Object { #where-object { $_.Source -eq $packageSource.Name } | Select-Object * -Unique | ForEach-Object {

        $pack | ForEach-Object { #where-object { $_.Source -eq $packageSource.Name } | Select-Object * -Unique | ForEach-Object {

            $p = $_

            If ( $p.GlobalFlag -eq $true ) {
                Write-Log -message "Installing $( $p.Package.Name ) with version $( $p.Package.version ) from $( $p.Package.Source ) globally"
                Install-Package -Name $p.Name -Scope $psScope -Source $packageSource.Name -RequiredVersion $p.Version -SkipDependencies -Force
                $g += 1
            } else {
                Write-Log -message "Installing $( $p.Name ) with version $( $p.version ) from $( $p.Package.Source ) locally"
                Install-Package -Name $p.Name -Scope $psScope -Source $packageSource.Name -RequiredVersion $p.Version -SkipDependencies -Force -Destination $LocalPackageFolder
                $l += 1
            }

            # Write progress
            Write-Progress -Activity "Package installation in progress" -Status "$( [math]::Round($i/$pack.Count*100) )% Complete:" -PercentComplete ([math]::Round($i/$pack.Count*100))

        }

    } catch {

        Write-Log -Message "Cannot install local packages!" -Severity WARNING

    }

} else {

    Write-Log "There is no package to install" -Severity VERBOSE

}



#-----------------------------------------------
# FINISHING
#-----------------------------------------------

# Installation Status
Write-Log -Message "STATUS:" -Severity INFO
Write-Log -Message "  $( $l ) local packages installed into '$( $LocalPackageFolder )'" -Severity INFO
Write-Log -Message "  $( $g ) global packages installed" -Severity INFO
Write-Log -Message "  $( $m ) modules installed with scope '$( $psScope )'" -Severity INFO
Write-Log -Message "  $( $s ) scripts installed with scope '$( $psScope )'" -Severity INFO

# Performance information
$processEnd = [datetime]::now
$processDuration = New-TimeSpan -Start $processStart -End $processEnd
Write-Log -Message "Done! Needed $( [int]$processDuration.TotalSeconds ) seconds in total" -Severity INFO
