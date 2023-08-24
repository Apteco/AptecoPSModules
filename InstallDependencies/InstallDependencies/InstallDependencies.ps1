
<#PSScriptInfo

.VERSION 0.1

.GUID 4c029c8e-09fa-48ee-9d62-10895150ce83

.AUTHOR florian.von.bracht@apteco.de

.COMPANYNAME Apteco GmbH

.COPYRIGHT (c) 2023 Apteco GmbH. All rights reserved.

.TAGS "PSEdition_Desktop", "Windows", "Apteco"

.LICENSEURI https://gist.github.com/gitfvb/58930387ee8677b5ccef93ffc115d836

.PROJECTURI https://github.com/Apteco/InstallDependencies/tree/main/InstallDependencies

.ICONURI https://www.apteco.de/sites/default/files/favicon_3.ico

.EXTERNALMODULEDEPENDENCIES 

.REQUIREDSCRIPTS

.EXTERNALSCRIPTDEPENDENCIES

.RELEASENOTES


.PRIVATEDATA

#>

<# 

.DESCRIPTION 
 Description 

#> 
Param(
     [Parameter(Mandatory=$false)][String[]]$Script = [Array]@()
    ,[Parameter(Mandatory=$false)][String[]]$Module = [Array]@()
    ,[Parameter(Mandatory=$false)][String[]]$GlobalPackage = [Array]@()
    ,[Parameter(Mandatory=$false)][String[]]$LocalPackage = [Array]@()
    ,[Parameter(Mandatory=$false)][String]$LocalPackageFolder = "lib"
)


#-----------------------------------------------
# RESOLVE PATH
#-----------------------------------------------

Write-Verbose "hello world"
write-verbose $PSScriptRoot

exit 0

#-----------------------------------------------
# NUGET SETTINGS
#-----------------------------------------------

$packageSourceName = "NuGet" # otherwise you could create a local repository and put all dependencies in there. You can find more infos here: https://github.com/Apteco/HelperScripts/tree/master/functions/Log#installation-via-local-repository
$packageSourceLocation = "https://www.nuget.org/api/v2"
$packageSourceProviderName = "NuGet"


#-----------------------------------------------
# POWERSHELL GALLERY SETTINGS
#-----------------------------------------------

# TODO [ ] Implement this



#-----------------------------------------------
# CHECK EXECUTION POLICY
#-----------------------------------------------


$executionPolicy = Get-ExecutionPolicy
Write-Verbose -Message "Your execution policy is currently: $( $executionPolicy )"  -Verbose #-severity INFO


#-----------------------------------------------
# CURRENT POWERSHELL VERSION
#-----------------------------------------------


Write-Verbose "Your are currently using PowerShell version $( $psversiontable.psversion.tostring() )"  -Verbose #-severity INFO



#-----------------------------------------------
# CHECK SCRIPT DEPENDENCIES FOR INSTALLATION AND UPDATE
#-----------------------------------------------


If ( $Scripts.count -gt 0 ) {

    # TODO [] Add psgallery possibly, too

    try {

        If ( $ScriptsOnly -eq $true -or ( $PackagesOnly -eq $false -and $ScriptsOnly -eq $false -and $ModulesOnly -eq $false) ) {

            Write-Verbose "Checking Script dependencies" -Verbose

            # SCRIPTS
            $installedScripts = Get-InstalledScript
            $psScripts | ForEach-Object {

                Write-Verbose "Checking script: $( $_ )" -Verbose

                # TODO [ ] possibly add dependencies on version number
                # This is using -force to allow updates
                $psScript = $_
                $psScriptDependencies = Find-Script -Name $psScript -IncludeDependencies
                $psScriptDependencies | Where-Object { $_.Name -notin $installedScripts.Name } | Install-Script -Scope AllUsers -Verbose -Force

            }

        }

    } catch {

        Write-Warning -Message "Cannot install scripts!" #-Severity WARNING
        $success = $false

    }

} else {

    Write-Verbose "There is no script to install"

}


#-----------------------------------------------
# CHECK MODULES DEPENDENCIES FOR INSTALLATION AND UPDATE
#-----------------------------------------------

If ( $psModules.count -gt 0 ) {

    try {

        # PSGallery should have been added automatically yet

        If ( $ModulesOnly -eq $true -or ( $PackagesOnly -eq $false -and $ScriptsOnly -eq $false -and $ModulesOnly -eq $false) ) {

            Write-Verbose "Checking Module dependencies" -Verbose

            $installedModules = Get-InstalledModule
            $psModules | ForEach-Object {

                Write-Verbose "Checking module: $( $_ )" -Verbose

                # TODO [ ] possibly add dependencies on version number
                # This is using -force to allow updates
                $psModule = $_
                $psModuleDependencies = Find-Module -Name $psModule -IncludeDependencies
                $psModuleDependencies | Install-Module -Scope AllUsers -Verbose -Force
                #$psModuleDependencies | where { $_.Name -notin $installedModules.Name } | Install-Module -Scope AllUsers -Verbose -Force

            }

        }

    } catch {

        Write-Warning -Message "Cannot install modules!" #-Severity WARNING
        $success = $false

        Write-Error -Message $_.Exception.Message #-Severity ERROR

    }

} else {

    Write-Verbose "There is no module to install" -Verbose

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

If ( $Packages.count -gt 0 ) {

    try {

        # See if Nuget needs to get registered
        $sources = Get-PackageSource -ProviderName $packageSourceProviderName
        If ( $sources.count -ge 1 ) {
            Write-Verbose -Message "You have at minimum 1 $( $packageSourceProviderName ) repository. Good!" -Verbose
        } elseif ( $sources.count -eq 0 ) {
            Write-Verbose -Message "You don't have $( $packageSourceProviderName ) as a PackageSource, do you want to register it now?" -Verbose
            $registerNugetDecision = $Host.UI.PromptForChoice("", "Register $( $packageSourceProviderName ) as repository?", @('&Yes'; '&No'), 1)
            If ( $registerNugetDecision -eq "0" ) {
                # Means yes and proceed
                Register-PackageSource -Name $packageSourceName -Location $packageSourceLocation -ProviderName $packageSourceProviderName
            } else {
                # Means no and leave
                Write-Verbose -Message "Then we will leave here" -Verbose
                exit 0
            }
        }

        $sources = Get-PackageSource -ProviderName $packageSourceProviderName
        If ( $sources.count -gt 1 ) {

            $packageSources = $sources.Name
            $packageSourceChoice = Prompt-Choice -title "PackageSource" -message "Which $( $packageSourceProviderName ) repository do you want to use?" -choices $packageSources
            $packageSource = $packageSources[$packageSourceChoice -1]

        } elseif ( $sources.count -eq 1 ) {

            $packageSource = $sources[0]

        } else {

            Write-Verbose -Message "There is no $( $packageSourceProviderName ) repository available" -Verbose

        }

        # TODO [x] ask if you want to trust the new repository

        # Do you want to trust that source?
        If ( $packageSource.IsTrusted -eq $false ) {
            Write-Verbose -Message "Your source is not trusted. Do you want to trust it now?" -Verbose
            $trustChoice = Prompt-Choice -title "Trust Package Source" -message "Do you want to trust $( $packageSource.Name )?" -choices @("Yes", "No")
            If ( $trustChoice -eq 1 ) {
                # Use
                # Set-PackageSource -Name NuGet
                # To get it to the untrusted status again
                Set-PackageSource -Name NuGet -Trusted
            }
        }

        # Install single packages
        # Install-Package -Name SQLitePCLRaw.core -Scope CurrentUser -Source NuGet -Verbose -SkipDependencies -Destination ".\lib" -RequiredVersion 2.0.6

    } catch {

        Write-Warning -Message "Cannot install nuget packages!" #-Severity WARNING
        $success = $false

    }

}  else {

    Write-Verbose "There is no nuget package to install" -Verbose

}



#-----------------------------------------------
# CHECK LOCAL PACKAGES DEPENDENCIES FOR INSTALLATION AND UPDATE
#-----------------------------------------------

If ( $psPackages.count -gt 0 ) {

    try {

        If ( $PackagesOnly -eq $true -or ( $PackagesOnly -eq $false -and $ScriptsOnly -eq $false -and $ModulesOnly -eq $false) ) {

            Write-Verbose "Checking package dependencies" -Verbose

            $localPackages = Get-package -Destination .\lib
            $globalPackages = Get-package
            $installedPackages = $localPackages + $globalPackages
            $psPackages | ForEach-Object {

                Write-Verbose "Checking package: $( $_ )" -Verbose

                # This is using -force to allow updates
                $psPackage = $_
                If ( $psPackage -is [pscustomobject] ) {
                    If ( $null -eq $psPackage.version ) {
                        $pkg = Find-Package $psPackage.name -IncludeDependencies -Verbose
                    } else {
                        $pkg = Find-Package $psPackage.name -IncludeDependencies -Verbose -RequiredVersion $psPackage.version
                    }
                    #$pkg = Find-Package $psPackage.name -IncludeDependencies -Verbose -RequiredVersion $psPackage.version
                } else {
                    $pkg = Find-Package $psPackage -IncludeDependencies -Verbose
                }
                $pkg | Where-object { $_.Name -notin $installedPackages.Name } | Select-Object Name, Version -Unique | ForEach-Object {
                    Install-Package -Name $_.Name -Scope CurrentUser -Source NuGet -Verbose -RequiredVersion $_.Version -SkipDependencies -Destination ".\lib" -Force # "$( $script:execPath )\lib"
                }

            }

        }

    } catch {

        Write-Warning -Message "Cannot install local packages!" #-Severity WARNING
        $success = $false

    }

} else {

    Write-Verbose "There is no local package to install" -Verbose

}