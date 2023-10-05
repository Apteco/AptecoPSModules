

Function Install-Plugin {
    [cmdletbinding()]

    param(
        [Parameter(Mandatory=$true)][String] $Guid
    )

    Begin {

        $success = $false


        #-----------------------------------------------
        # CHECK THE PLUGIN
        #-----------------------------------------------

        # Pick the plugin
        $plugin = @(, ($Script:plugins | Where-Object { $_.guid -eq $Guid }))

        # Check the plugin
        If ( $plugin.count -eq 0 ) {
            Write-Error "Plugin couldn't be found. Please check your guid"
            throw "Plugin couldn't be found. Please check your guid"
            Exit 1
        } elseif ( $plugin.count -gt 1 ) {
            Write-Error "There are more than 1 plugins with the guid, please check your guids!"
            throw "There are more than 1 plugins with the guid, please check your guids!"
            Exit 1
        }


        #-----------------------------------------------
        # LOG
        #-----------------------------------------------

        $moduleName = "INSTALLATION PLUGIN"

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
        #. ( Join-Path -Path $Script:moduleRoot -ChildPath "/bin/dependencies.ps1" )

        # Call the script to install dependencies
        Install-Dependencies -Script $plugin.dependencies.psScripts -Module $plugin.dependencies.psModules -LocalPackage $plugin.dependencies.psPackages



    }

    End {

    }
}