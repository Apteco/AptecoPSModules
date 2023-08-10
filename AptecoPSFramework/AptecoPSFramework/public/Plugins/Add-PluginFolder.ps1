function Add-PluginFolder {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)][String] $Folder
    )

    begin {

    }

    process {

        $return = $false

        # Check if this needs to be declared first
        If ( $null -eq $Script:pluginFolders ) {
            $Script:pluginFolders = [System.Collections.ArrayList]::new()
        }

        # Resolve the path to an absolute path
        #Write-Host "$( $Folder )"
        $resolvedPath = Resolve-Path -Path $Folder
        #Write-Host "$( $resolvedPath )"

        # Check the path
        If ( ( Test-Path -Path $resolvedPath ) -eq $false ) {
            Write-Error -Message "There is a problem with '$( $resolvedPath.Path )'"
            throw "There is a problem with '$( $resolvedPath.Path )'"
        }

        # Add this folder
        [void]$Script:pluginFolders.add($resolvedPath.Path)

        # Register all plugins automatically
        $plugins = Register-Plugins

        # Switch return value
        $return = $true

        # Return
        $return

    }

    end {

    }
}