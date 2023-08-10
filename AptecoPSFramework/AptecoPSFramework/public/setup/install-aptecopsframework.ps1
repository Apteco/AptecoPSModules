Function Install-AptecoPSFramework {

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
        # LOAD DEPENDENCY VARIABLES
        #-----------------------------------------------

        . "$( $Script:moduleRoot )/bin/dependencies.ps1"


        #-----------------------------------------------
        # LOG
        #-----------------------------------------------

        $moduleName = "INSTALLATION"

        # Start the log
        Write-Verbose -message $Script:logDivider -Verbose
        Write-Verbose -message $moduleName -Verbose #-Severity INFO


    }

    Process {

        $success = $true

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
        Write-Verbose -Message "Your execution policy is currently: $( $executionPolicy )"  -Verbose #-severity INFO


        #-----------------------------------------------
        # INSTALLATION POWERSHELL 5.1
        #-----------------------------------------------

        <#
        Please make sure to have PowerShell 5.1 installed
        PeopleStage code is using runspaces, which is using the default PowerShell engine on the host

        The version is checked by the metadata of this module

        #>

        Write-Verbose "Your are currently using PowerShell version $( $psversiontable.psversion.tostring() )"  -Verbose #-severity INFO
        If ( $psedition -eq "Core" ) {
            Write-Warning "Please be aware that runspaces (used by Apteco PeopleStage) use PS5.1 Windows by default!" #-severity WARNING
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
        # CHECK SCRIPT DEPENDENCIES FOR INSTALLATION AND UPDATE
        #-----------------------------------------------


        If ( $psScripts.count -gt 0 ) {

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
                            $pkg = Find-Package $psPackage.name -IncludeDependencies -Verbose -RequiredVersion $psPackage.version
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


        #-----------------------------------------------
        # CHECK PACKAGES DEPENDENCIES FOR INSTALLATION AND UPDATE
        #-----------------------------------------------

        If ( $PackagesOnly -eq $false -and $ScriptsOnly -eq $false -and $ModulesOnly -eq $false) {

            # TODO replace the integration parameters

            #try {

            Write-Verbose "This script is copying the boilerplate (needed for installation ) to your current directory" -Verbose

            Copy-Item -Path "$( $Script:moduleRoot )\boilerplate\*" -Destination "." -Confirm

            $currentPath = ( resolve-path -Path "." ).Path
            Write-Verbose "Please have a look at your PeopleStage channels and create a new email channel:" -Verbose
            Write-Verbose "  GENERAL" -Verbose
            Write-Verbose "    Broadcaster: PowerShell" -Verbose
            Write-Verbose "    Username: dummy" -Verbose
            Write-Verbose "    Password: dummy" -Verbose
            Write-Verbose "    Email Variable: Please choose your email variable" -Verbose
            Write-Verbose "    Email Variable Description Override: email" -Verbose
            Write-Verbose "  PARAMETER" -Verbose
            Write-Verbose "    URL: https://rest.cleverreach.com/v3/" -Verbose
            Write-Verbose "    GetMessagesScript: $( $currentPath )\getmessages.ps1" -Verbose
            Write-Verbose "    GetListsScript: $( $currentPath )\getmessagelists.ps1" -Verbose
            Write-Verbose "    UploadScript: $( $currentPath )\upload.ps1" -Verbose
            Write-Verbose "    BroadcastScript: $( $currentPath )\broadcast.ps1" -Verbose
            Write-Verbose "    PreviewMessageScript: $( $currentPath )\preview.ps1" -Verbose
            Write-Verbose "    TestScript: $( $currentPath )\test.ps1" -Verbose
            Write-Verbose "    SendTestEmailScript: $( $currentPath )\testsend.ps1" -Verbose
            Write-Verbose "    IntegrationParameters: settingsFile=D:\Scripts\CleverReach\PSCleverReachModule\settings.json;mode=taggingOnly" -Verbose
            Write-Verbose "    Encoding: UTF8" -Verbose
            Write-Verbose "  OUTPUT SETTINGS" -Verbose
            Write-Verbose "    Append To List: false" -Verbose
            Write-Verbose "    Number of retries: 1" -Verbose
            Write-Verbose "    Response File Key Type: Email with Broadcast Id" -Verbose
            Write-Verbose "    Message Content Type: Broadcaster Template" -Verbose
            Write-Verbose "    Retrieve Existing List Names: true" -Verbose
            Write-Verbose "  FILE SETTINGS" -Verbose
            Write-Verbose "    Encoding: UTF-8" -Verbose
            Write-Verbose "  ADDITIONAL VARIABLES" -Verbose
            Write-Verbose "    Add all variables that you would like to always upload" -Verbose
            Write-Verbose "Please consider to ask Apteco to look at your settings when you have done your first setup" -Verbose



            # } catch {
            #     Write-Verbose -Message "Cannot copy boilerplate!" -Severity WARNING
            #     $success = $false
            # }

            # TODO Add hints on how to create the channel in PeopleStage


            <#
            Write-Verbose "Please create the function [Custom].[vModelElementLatest] on the PeopleStage Database by executing this command"

            $sql = Get-Content -Path "$( $moduleRoot )\sql\99_create_vModelElementLatest.sql" -Encoding UTF8 -raw
            # $sqlReplacement = [Hashtable]@{
            #     "#CAMPAIGN#"=$campaignID
            # }
            # $sql = Replace-Tokens -InputString $sql -Replacements $sqlReplacement
            #$customersSql | Set-Content ".\$( $Script:processId ).sql" -Encoding UTF8

            Write-Verbose -Message $sql -Verbose
            #>

        }


    }

    End {

        #-----------------------------------------------
        # FINISH
        #-----------------------------------------------

        If ( $success -eq $true ) {
            Write-Verbose -Message "All good. Installation finished!" #-Severity INFO
        } else {
            Write-Error -Message "There was a problem. Please check the output in this window and retry again." #-Severity ERROR
        }

    }
}

