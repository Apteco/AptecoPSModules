function Install-PSOAuth {
    [CmdletBinding()]
    param (

    )
    
    begin {

    }

    process {

        # Check if Install-Dependenies is present
        If ( @( Get-InstalledScript | Where-Object { $_.Name -eq "Import-Dependencies" } ).Count -lt 1 ) {
            throw "Missing dependency, execute: 'Install-Script Import-Dependencies'"
        }

        # Load dependencies as variables
        . ( Join-Path -Path $Script:moduleRoot -ChildPath "/bin/dependencies.ps1" )

        # Call the script to install dependencies
        Install-Dependencies -Module $psModules #-LocalPackage $psModules -Script $psScripts 

    }

    end {

    }

}