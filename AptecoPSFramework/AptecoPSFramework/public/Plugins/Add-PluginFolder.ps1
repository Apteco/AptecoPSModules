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
        If ( $Script:pluginFolders -eq $null ) {
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

        # Switch return value
        $return = $true

        # Return
        $return

    }
    
    end {
        
    }
}