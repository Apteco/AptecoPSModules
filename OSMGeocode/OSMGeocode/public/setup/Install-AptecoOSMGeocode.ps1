Function Install-AptecoOSMGeocode {

<#

Calling the function without parameters does the whole part

Calling with one of the Flags, just does this part

#>

    [cmdletbinding()]
    param(
    )

    Begin {

        #-----------------------------------------------
        # LOAD DEPENDENCY VARIABLES
        #-----------------------------------------------

        . $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath("$( $Script:moduleRoot )/bin/dependencies.ps1")


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

        #Write-Verbose "This script is copying the boilerplate (needed for installation ) to your current directory." -Verbose
        #Write-Warning "This is only needed for the first installation"

    }

    End {

        #-----------------------------------------------
        # FINISH
        #-----------------------------------------------

        #If ( $success -eq $true ) {
            Write-Verbose -Message "All good. Installation finished!" #-Severity INFO
        #} else {
        #    Write-Error -Message "There was a problem. Please check the output in this window and retry again." #-Severity ERROR
        #}

    }
}

