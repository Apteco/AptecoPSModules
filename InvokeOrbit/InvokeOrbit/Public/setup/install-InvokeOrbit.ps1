

################################################
#
# SCRIPT ROOT
#
################################################
<#
# Load scriptpath
if ($MyInvocation.MyCommand.CommandType -eq "ExternalScript") {
    $scriptPath = Split-Path -Parent -Path $MyInvocation.MyCommand.Definition
} else {
    $scriptPath = Split-Path -Parent -Path ([Environment]::GetCommandLineArgs()[0])
}

Set-Location -Path $scriptPath
#>


Function Install-InvokeOrbit {

<#

Calling the function without parameters does the whole part

Calling with one of the Flags, just does this part

#>

    [cmdletbinding()]
    param(
         [Parameter(Mandatory=$false)][Switch]$ScriptsOnly
        ,[Parameter(Mandatory=$false)][Switch]$ModulesOnly
        ,[Parameter(Mandatory=$false)][Switch]$PackagesOnly
    )

    Begin {

        #-----------------------------------------------
        # NUGET SETTINGS
        #-----------------------------------------------

        $packageSourceName = "NuGet" # otherwise you could create a local repository and put all dependencies in there. You can find more infos here: https://github.com/Apteco/HelperScripts/tree/master/functions/Log#installation-via-local-repository
        $packageSourceLocation = "https://www.nuget.org/api/v2"
        $packageSourceProviderName = "NuGet"


        #-----------------------------------------------
        # LOG
        #-----------------------------------------------

        $moduleName = "INSTALLATION"

        # Start the log
        Write-Log -message $Script:logDivider
        Write-Log -message $moduleName -Severity INFO


    }

    Process {
    
        #-----------------------------------------------
        # CHECK EXECUTION POLICY
        #-----------------------------------------------

        <#

        If you get

            .\load.ps1 : File C:\Users\WDAGUtilityAccount\scripts\load.ps1 cannot be loaded because running scripts is disabled on this system. For more information, see
            about_Execution_Policies at https:/go.microsoft.com/fwlink/?LinkID=135170.
            At line:1 char:1
            + .\load.ps1
            + ~~~~~~~~~~
                + CategoryInfo          : SecurityError: (:) [], PSSecurityException
                + FullyQualifiedErrorId : UnauthorizedAccess

        Then change your Execution Policy to something like

        #>

        # Set-ExecutionPolicy -ExecutionPolicy Unrestricted   
        $executionPolicy = Get-ExecutionPolicy
        Write-Log -Message "Your execution policy is currently: $( $executionPolicy )" -severity INFO


        #-----------------------------------------------
        # INSTALLATION POWERSHELL 5.1
        #-----------------------------------------------

        <#
        Please make sure to have PowerShell 5.1 installed
        PeopleStage code is using runspaces, which is using the default PowerShell engine on the host

        The version is checked by the metadata of this module

        #>

        Write-Log "Your are currently using PowerShell version $( $psversiontable.psversion.tostring() )" -severity INFO
        If ( $psedition -eq "Core" ) {
            Write-Log "Please be aware that runspaces (used by PeopleStage) use PS5.1 Windows by default!" -severity WARNING
        }


        #-----------------------------------------------
        # CHECK PSGALLERY
        #-----------------------------------------------

        # TODO [ ] Implement this


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

        If ( $psPackages.count -gt 0 ) {

            # See if Nuget needs to get registered
            $sources = Get-PackageSource -ProviderName $packageSourceProviderName
            If ( $sources.count -ge 1 ) {
                Write-Log -Message "You have at minimum 1 $( $packageSourceProviderName ) repository. Good!"
            } elseif ( $sources.count -eq 0 ) {
                Write-Log -Message "You don't have $( $packageSourceProviderName ) as a PackageSource, do you want to register it now?"
                $registerNugetDecision = $Host.UI.PromptForChoice("", "Register $( $packageSourceProviderName ) as repository?", @('&Yes'; '&No'), 1)
                If ( $registerNugetDecision -eq "0" ) {
                    # Means yes and proceed
                    Register-PackageSource -Name $packageSourceName -Location $packageSourceLocation -ProviderName $packageSourceProviderName
                } else {
                    # Means no and leave
                    Write-Log -Message "Then we will leave here"
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
                
                Write-Log -Message "There is no $( $packageSourceProviderName ) repository available"

            }

            # TODO [x] ask if you want to trust the new repository

            # Do you want to trust that source?
            If ( $packageSource.IsTrusted -eq $false ) {
                Write-Log -Message "Your source is not trusted. Do you want to trust it now?"
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

        } 

        #-----------------------------------------------
        # CHECK SCRIPT DEPENDENCIES FOR INSTALLATION AND UPDATE
        #-----------------------------------------------


        If ( $psScripts.count -gt 0 ) {

            # TODO [] Add psgallery possibly, too

            If ( $ScriptsOnly -eq $true -or ( $PackagesOnly -eq $false -and $ScriptsOnly -eq $false -and $ModulesOnly -eq $false) ) {

                Write-Log "Checking Script dependencies"

                # SCRIPTS
                $installedScripts = Get-InstalledScript
                $psScripts | ForEach {

                    Write-Log "Checking script: $( $_ )"

                    # TODO [ ] possibly add dependencies on version number
                    # This is using -force to allow updates
                    $psScript = $_
                    $psScriptDependencies = Find-Script -Name $psScript -IncludeDependencies
                    $psScriptDependencies | where { $_.Name -notin $installedScripts.Name } | Install-Script -Scope AllUsers -Verbose -Force

                }

            }

        } else {

            Write-Log "There is no script to install"

        }
        

        #-----------------------------------------------
        # CHECK MODULES DEPENDENCIES FOR INSTALLATION AND UPDATE
        #-----------------------------------------------

        If ( $psModules.count -gt 0 ) {

            # TODO [] Add psgallery possibly, too

            If ( $ModulesOnly -eq $true -or ( $PackagesOnly -eq $false -and $ScriptsOnly -eq $false -and $ModulesOnly -eq $false) ) {

                Write-Log "Checking Module dependencies"

                $installedModules = Get-InstalledModule
                $psModules | ForEach {
                    
                    Write-Log "Checking module: $( $_ )"

                    # TODO [ ] possibly add dependencies on version number
                    # This is using -force to allow updates
                    $psModule = $_
                    $psModuleDependencies = Find-Module -Name $psModule -IncludeDependencies
                    $psModuleDependencies | where { $_.Name -notin $installedModules.Name } | Install-Module -Scope AllUsers -Verbose -Force
        
                }

            }

        } else {

            Write-Log "There is no module to install"

        }


        #-----------------------------------------------
        # CHECK PACKAGES DEPENDENCIES FOR INSTALLATION AND UPDATE
        #-----------------------------------------------

        If ( $psPackages.count -gt 0 ) {

            # TODO [] Add psgallery possibly, too

            If ( $PackagesOnly -eq $true -or ( $PackagesOnly -eq $false -and $ScriptsOnly -eq $false -and $ModulesOnly -eq $false) ) {

                Write-Log "Checking package dependencies"

                $localPackages = Get-package -Destination .\lib
                $globalPackages = Get-package 
                $installedPackages = $localPackages + $globalPackages
                $psPackages | ForEach {

                    Write-Log "Checking package: $( $_ )"

                    # This is using -force to allow updates
                    $psPackage = $_
                    If ( $psPackage -is [pscustomobject] ) {
                        $pkg = Find-Package $psPackage.name -IncludeDependencies -Verbose -RequiredVersion $psPackage.version
                    } else {
                        $pkg = Find-Package $psPackage -IncludeDependencies -Verbose
                    }
                    $pkg | where { $_.Name -notin $installedPackages.Name } | Select Name, Version -Unique | ForEach {
                        Install-Package -Name $_.Name -Scope CurrentUser -Source NuGet -Verbose -RequiredVersion $_.Version -SkipDependencies -Destination ".\lib" -Force # "$( $script:execPath )\lib"
                    }

                }

            }

        } else {

            Write-Log "There is no package to install"

        }

        #-----------------------------------------------
        # CHECK PACKAGES DEPENDENCIES FOR INSTALLATION AND UPDATE
        #-----------------------------------------------

        If ( $PackagesOnly -eq $false -and $ScriptsOnly -eq $false -and $ModulesOnly -eq $false) {

            

        }

        
    }

    End {

        #-----------------------------------------------
        # FINISH
        #-----------------------------------------------

        Write-Log -Message "All good. Installation finished!" -Severity INFO

    }
}

