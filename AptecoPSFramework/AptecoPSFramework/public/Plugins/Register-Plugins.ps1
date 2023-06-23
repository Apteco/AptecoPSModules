function Register-Plugins {
    [CmdletBinding()]
    param (
        
    )
    
    begin {
        
    }
    
    process {

        # TODO Load also a separate external folder for another plugin

        # Initiate the variable if needed
        #If ( $Script:plugins -eq $null ) {
            $Script:plugins = [System.Collections.ArrayList]::new()
            #}

        $Script:pluginFolders | ForEach-Object {
            $pluginFolder = $_
            Get-ChildItem -Path $pluginFolder -Filter "Plugin.ps1" -Recurse | ForEach {
                
                $pluginItem = $_
                $plugin = $_.FullName

                #Write-Host $plugin

                # dot source the plugin file / overwrite the existing functions
                . $plugin
                
                # Load the plugin info
                $pluginInfo = ( Get-CurrentPluginInfos ).psobject.copy()
                #Write-Host $pluginInfo

                # Add the path to the pluginInfo
                $pluginInfo | Add-Member -MemberType NoteProperty -Name "path" -Value ( $pluginItem.Directory.Fullname )

                # Add information about this plugin
                [void]$Script:plugins.add($pluginInfo)

            }
        }
        
        # Checks - If there is more than one plugin with the same guid
        $groupPlugins = $Script:plugins.guid | Group-Object
        If ( ( $groupPlugins | Where-Object { $_.Count -gt 1 } ).Count -gt 0 ) {
            Write-Error "There are more than 1 plugins with the same guid. Please check this!"
            throw "There are more than 1 plugins with the same guid. Please check this!"
        }

        # return 
        #$script:debug = $Script:plugins
        $Script:plugins

    }
    
    end {
        
    }
}