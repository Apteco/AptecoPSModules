Function Install-AptecoPSFramework {

<#

Calling the function without parameters does the whole part

Calling with one of the Flags, just does this part

#>

    [cmdletbinding()]
    param(
        # [Parameter(Mandatory=$false)][Switch]$ScriptsOnly
        #,[Parameter(Mandatory=$false)][Switch]$ModulesOnly
        #,[Parameter(Mandatory=$false)][Switch]$PackagesOnly
    )

    Begin {

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

        #-----------------------------------------------
        # CHECK AND INSTALL DEPENDENCIES
        #-----------------------------------------------

        # Check if Install-Dependenies is present
        If ( @( Get-InstalledScript | Where-Object { $_.Name -eq "Install-Dependencies" } ).Count -lt 1 ) {
            throw "Missing dependency, execute: 'Install-Script Install-Dependencies'"
        }

        # Load dependencies as variables
        . ( Join-Path -Path $Script:moduleRoot -ChildPath "/bin/dependencies.ps1" )

        # Call the script to install dependencies
        Install-Dependencies -Script $psScripts -Module $psModules -LocalPackage $psPackages


        #-----------------------------------------------
        # GIVE SOME HELPFUL OUTPUT
        #-----------------------------------------------

        #If ( $PackagesOnly -eq $false -and $ScriptsOnly -eq $false -and $ModulesOnly -eq $false) {

            # TODO replace the integration parameters

            #try {

        Write-Verbose "This script is copying the boilerplate (needed for installation ) to your current directory." -Verbose
        Write-Warning "This is only needed for the first installation"

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

        #}


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

