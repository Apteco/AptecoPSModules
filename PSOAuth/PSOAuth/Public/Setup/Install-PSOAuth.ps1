function Install-PSOAuth {
    [CmdletBinding()]
    param (

    )
    
    begin {

    }

    process {

        # Check if Install-Dependenies is present
        If ( @( Get-InstalledScript | Where-Object { $_.Name -eq "Install-Dependencies" } ).Count -lt 1 ) {
            throw "Missing dependency, execute: 'Install-Script Install-Dependencies'"
        }

        # Load dependencies as variables
        . ( Join-Path -Path $Script:moduleRoot -ChildPath "/bin/dependencies.ps1" )

        # Call the script to install dependencies
        Install-Dependencies -Script $psScripts -Module $psModules -LocalPackage $psPackages

    }

    end {

    }

}