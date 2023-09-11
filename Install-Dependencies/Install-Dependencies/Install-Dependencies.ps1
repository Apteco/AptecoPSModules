
<#PSScriptInfo

.VERSION 0.1

.GUID 4c029c8e-09fa-48ee-9d62-10895150ce83

.AUTHOR florian.von.bracht@apteco.de

.COMPANYNAME Apteco GmbH

.COPYRIGHT (c) 2023 Apteco GmbH. All rights reserved.

.TAGS "PSEdition_Desktop", "Windows", "Apteco"

.LICENSEURI https://gist.github.com/gitfvb/58930387ee8677b5ccef93ffc115d836

.PROJECTURI https://github.com/Apteco/Install-Dependencies/tree/main/Install-Dependencies

.ICONURI https://www.apteco.de/sites/default/files/favicon_3.ico

.EXTERNALMODULEDEPENDENCIES 

.REQUIREDSCRIPTS

.EXTERNALSCRIPTDEPENDENCIES

.RELEASENOTES
0.0.1 Initial release of this script

.PRIVATEDATA

#>


<#
.SYNOPSIS
    Downloads and installs the latest versions of some scripts, modules and packages (saved in current folder of machine folder) from the PowerShell Gallery and NuGet.
.DESCRIPTION
    Script to install dependencies from the PowerShell Gallery and NuGet. It is possible to install scripts, modules and packages.
    The packages can be installed from the PowerShell Gallery and packages from a NuGet repository.
    Packages can defined as a raw string array or as a pscustomobject with a specific version number.

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
.NOTES
    Created by : gitfvb
.LINK
    Project Site: https://github.com/Apteco/Install-Dependencies/tree/main/Install-Dependencies
#>

#> 
Param(
     [Parameter(Mandatory=$false)][ValidateNotNullOrEmpty()][String[]]$Script = [Array]@()
    ,[Parameter(Mandatory=$false)][ValidateNotNullOrEmpty()][String[]]$Module = [Array]@()
    ,[Parameter(Mandatory=$false)][ValidateNotNullOrEmpty()][String[]]$GlobalPackage = [Array]@()
    ,[Parameter(Mandatory=$false)][ValidateNotNullOrEmpty()][String[]]$LocalPackage = [Array]@()
    ,[Parameter(Mandatory=$false)][ValidateNotNullOrEmpty()][String]$LocalPackageFolder = "lib"
    ,[Parameter(Mandatory=$false)][Switch]$InstallScriptAndModuleForCurrentUser = $false
)

#Requires -RunAsAdministrator

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
$choice = Prompt-Choice -title "City" -message "Which city would you prefer?" -choices $stringArray
$choiceMatchedWithArray = $stringArray[$choice -1]

# TODO [ ] put this into a module

#>


#-----------------------------------------------
# FUNCTIONS
#-----------------------------------------------

Function Prompt-Choice {

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
# TEST
#-----------------------------------------------

Write-Warning "Please make sure to start this script as administrator!"
# Write-Verbose "hello world"
# write-verbose $PSScriptRoot

# exit 0


#-----------------------------------------------
# NUGET SETTINGS
#-----------------------------------------------

$packageSourceName = "NuGet" # otherwise you could create a local repository and put all dependencies in there. You can find more infos here: https://github.com/Apteco/HelperScripts/tree/master/functions/Log#installation-via-local-repository
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


#-----------------------------------------------
# CHECK EXECUTION POLICY
#-----------------------------------------------

$executionPolicy = Get-ExecutionPolicy
Write-Verbose -Message "Your execution policy is currently: $( $executionPolicy )"


#-----------------------------------------------
# CURRENT POWERSHELL VERSION
#-----------------------------------------------

$psVersion = $psversiontable.psversion
Write-Verbose "Your are currently using PowerShell version $( $psVersion.toString() )"


#-----------------------------------------------
# CHECK POWERSHELL GALLERY REPOSITORY
#-----------------------------------------------

If ( $Script.Count -gt 0 -or $Module.Count -gt 0 ) {
    $powershellRepo = @( Get-PSRepository -ProviderName $powerShellSourceProviderName ) #@( Get-PSRepository | where { $_.SourceLocation -like "https://www.powershellgallery.com*" } )
    If ( $powershellRepo.Count -eq 0 ) {
        Write-Warning "No module/script repository found! Please make sure to add a repository to your machine!"
    }
}


If ( $Script.Count -gt 0 -or $Module.Count -gt 0 ) {

    try {

        # Get PowerShellGet sources
        $powershellRepo = @( Get-PSRepository -ProviderName $powerShellSourceProviderName )

        # See if PSRepo needs to get registered
        If ( $powershellRepo.count -ge 1 ) {
            Write-Verbose -Message "You have at minimum 1 $( $powerShellSourceProviderName ) repository. Good!"
        } elseif ( $powershellRepo.count -eq 0 ) {
            Write-Warning -Message "You don't have $( $powerShellSourceProviderName ) as a module/script source, do you want to register it now?"
            $registerPsRepoDecision = $Host.UI.PromptForChoice("", "Register $( $powerShellSourceProviderName ) as repository?", @('&Yes'; '&No'), 1)
            If ( $registerPsRepoDecision -eq "0" ) {
                
                # Means yes and proceed
                Register-PSRepository -Name $powerShellSourceName -SourceLocation $powerShellSourceLocation
                #Register-PackageSource -Name $packageSourceName -Location $packageSourceLocation -ProviderName $packageSourceProviderName

                # Load sources again
                $powershellRepo = @( Get-PSRepository -ProviderName $powerShellSourceProviderName )

            } else {
                # Means no and leave
                Write-Error "No package repository found! Please make sure to add a PowerShellGet repository to your machine!"
                exit 0
            }
        }

        # Choose repository
        If ( $powershellRepo.count -gt 1 ) {

            $psGetSources = $powershellRepo.Name
            $psGetSourceChoice = Prompt-Choice -title "Script/module Source" -message "Which $( $powerShellSourceProviderName ) repository do you want to use?" -choices $psGetSources
            $psGetSource = $psGetSources[$psGetSourceChoice -1]

        } elseif ( $powershellRepo.count -eq 1 ) {

            $psGetSource = $powershellRepo[0]

        } else {

            Write-Warning -Message "There is no $( $powerShellSourceProviderName ) repository available"
            Exit 0

        }

        # TODO [x] ask if you want to trust the new repository

        # Do you want to trust that source?
        If ( $psGetSource.IsTrusted -eq $false ) {
            Write-Warning -Message "Your source is not trusted. Do you want to trust it now?"
            $trustChoice = Prompt-Choice -title "Trust script/module Source" -message "Do you want to trust $( $psGetSource.Name )?" -choices @("Yes", "No")
            If ( $trustChoice -eq 1 ) {
                # Use
                # Set-PSRepository -Name $psGetSource.Name -InstallationPolicy Untrusted
                # To get it to the untrusted status again

                Set-PSRepository -Name $psGetSource.Name -InstallationPolicy Trusted
            }
        }

    } catch {

        Write-Warning -Message "There is a problem with the repository check!" #-Severity WARNING

    }

}

# TODO [x] allow local repositories


#-----------------------------------------------
# CHECK SCRIPT DEPENDENCIES FOR INSTALLATION AND UPDATE
#-----------------------------------------------

If ( $Script.count -gt 0 ) {

    # TODO [ ] Add psgallery possibly, too

    try {

        #If ( $ScriptsOnly -eq $true -or ( $PackagesOnly -eq $false -and $ScriptsOnly -eq $false -and $ModulesOnly -eq $false) ) {

        Write-Verbose "Checking Script dependencies"

        # SCRIPTS
        #$installedScripts = Get-InstalledScript
        $Script | ForEach-Object {

            $psScript = $_

            Write-Verbose "Checking script: $( $psScript )"

            # TODO [ ] possibly add dependencies on version number
            # This is using -force to allow updates
            
            $psScriptDependencies = Find-Script -Name $psScript -IncludeDependencies
            #$psScriptDependencies | Where-Object { $_.Name -notin $installedScripts.Name } | Install-Script -Scope AllUsers -Verbose -Force
            $psScriptDependencies | Install-Script -Scope $psScope -Force

        }

        #}

    } catch {

        Write-Warning -Message "Cannot install scripts!" #-Severity WARNING
        #$success = $false

    }

} else {

    Write-Verbose "There is no script to install"

}


#-----------------------------------------------
# CHECK MODULES DEPENDENCIES FOR INSTALLATION AND UPDATE
#-----------------------------------------------

If ( $Module.count -gt 0 ) {

    try {

        # PSGallery should have been added automatically yet

        Write-Verbose "Checking Module dependencies"

        #$installedModules = Get-InstalledModule
        $Module | ForEach-Object {

            $psModule = $_

            Write-Verbose "Checking module: $( $psModule )"

            # TODO [ ] possibly add dependencies on version number
            # This is using -force to allow updates
            $psModuleDependencies = Find-Module -Name $psModule -IncludeDependencies
            $psModuleDependencies | Install-Module -Scope $psScope -Force
            #$psModuleDependencies | where { $_.Name -notin $installedModules.Name } | Install-Module -Scope AllUsers -Verbose -Force

        }


    } catch {

        Write-Warning -Message "Cannot install modules!" #-Severity WARNING

        #Write-Error -Message $_.Exception.Message #-Severity ERROR

    }

} else {

    Write-Verbose "There is no module to install"

}


#-----------------------------------------------
# CHECK PACKAGES NUGET REPOSITORY
#-----------------------------------------------

<#

If this module is not installed via nuget, then this makes sense to check again

# Add nuget first or make sure it is set

Register-PackageSource -Name Nuget -Location "https://www.nuget.org/api/v2" –ProviderName Nuget

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
            Write-Verbose -Message "You have at minimum 1 $( $packageSourceProviderName ) repository. Good!"
        } elseif ( $sources.count -eq 0 ) {
            Write-Warning -Message "You don't have $( $packageSourceProviderName ) as a PackageSource, do you want to register it now?"
            $registerNugetDecision = $Host.UI.PromptForChoice("", "Register $( $packageSourceProviderName ) as repository?", @('&Yes'; '&No'), 1)
            If ( $registerNugetDecision -eq "0" ) {
                
                # Means yes and proceed
                Register-PackageSource -Name $packageSourceName -Location $packageSourceLocation -ProviderName $packageSourceProviderName

                # Load sources again
                $sources = @( Get-PackageSource -ProviderName $packageSourceProviderName ) #| where { $_.Location -like "https://www.nuget.org*" }

            } else {
                # Means no and leave
                Write-Error "No package repository found! Please make sure to add a NuGet repository to your machine!"
                exit 0
            }
        }

        # Choose repository
        If ( $sources.count -gt 1 ) {

            $packageSources = $sources.Name
            $packageSourceChoice = Prompt-Choice -title "PackageSource" -message "Which $( $packageSourceProviderName ) repository do you want to use?" -choices $packageSources
            $packageSource = $packageSources[$packageSourceChoice -1]

        } elseif ( $sources.count -eq 1 ) {

            $packageSource = $sources[0]

        } else {

            Write-Warning -Message "There is no $( $packageSourceProviderName ) repository available"
            Exit 0

        }

        # TODO [x] ask if you want to trust the new repository

        # Do you want to trust that source?
        If ( $packageSource.IsTrusted -eq $false ) {
            Write-Warning -Message "Your source is not trusted. Do you want to trust it now?"
            $trustChoice = Prompt-Choice -title "Trust Package Source" -message "Do you want to trust $( $packageSource.Name )?" -choices @("Yes", "No")
            If ( $trustChoice -eq 1 ) {
                # Use
                # Set-PackageSource -Name NuGet
                # To get it to the untrusted status again
                Set-PackageSource -Name $packageSource.Name -Trusted
            }
        }

    } catch {

        Write-Warning -Message "There is a problem with the repository" #-Severity WARNING

    }

}


#-----------------------------------------------
# CHECK LOCAL PACKAGES DEPENDENCIES FOR INSTALLATION AND UPDATE
#-----------------------------------------------

If ( $LocalPackage.count -gt 0 -or $GlobalPackage -gt 0) {

    try {

        Write-Verbose "Checking package dependencies" -Verbose

        $localPackages = Get-Package -Destination $LocalPackageFolder
        $globalPackages = Get-Package
        $installedPackages = $localPackages + $globalPackages
        $packagesToInstall = [System.Collections.ArrayList]@()
        $LocalPackage + $GlobalPackage | ForEach-Object {

            $psPackage = $_
            $globalFlag = $false
            If ( $GlobalPackage -contains $psPackage ) {
                $globalFlag = $true
            } # TODO [ ] Especially test global and local installation

            Write-Verbose "Checking package: $( $psPackage )" -Verbose

            # This is using -force to allow updates

            If ( $psPackage -is [pscustomobject] ) {
                If ( $null -eq $psPackage.version ) {
                    $pkg = Find-Package $psPackage.name -IncludeDependencies
                } else {
                    $pkg = Find-Package $psPackage.name -IncludeDependencies -RequiredVersion $psPackage.version
                }
            } else {
                $pkg = Find-Package $psPackage -IncludeDependencies
            }

            $pkg | Select-Object Name, Version -Unique | ForEach-Object { # | Where-Object { $_.Name -notin $installedPackages.Name }
                $p = $_
                $pd = [PSCustomObject]@{
                    "GlobalFlag" = $globalFlag
                    "Package" = $p
                }
                [void]$packagesToInstall.Add($pd)

            }

        }

        # Install the packages now
        $packagesToInstall | Select-Object * -Unique | ForEach-Object {
            $p = $_
            If ( $p.GlobalFlag -eq $true ) {
                Install-Package -Name $p.Package.Name -Scope $psScope -Source $packageSource.Name -RequiredVersion $p.Package.Version -SkipDependencies -Force
            } else {
                Install-Package -Name $p.Package.Name -Scope $psScope -Source $packageSource.Name -RequiredVersion $p.Package.Version -SkipDependencies -Destination $LocalPackageFolder -Force
            }

        }

    } catch {

        Write-Warning -Message "Cannot install local packages!" #-Severity WARNING

    }

} else {

    Write-Verbose "There is no package to install"

}