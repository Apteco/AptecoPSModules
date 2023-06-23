function Get-CurrentPluginInfos {
    [PSCustomObject]@{

        # identifier for this plugin - please do not change or use this twice
        "guid" = "3adb8696-c219-49c7-906b-92680727a1c1"
        
        # general information about this plugin
        "name" = "CleverReach"
        "version" = "0.0.1"
        "lastUpdate" = "2023-06-23"
        "category" = "channel"
        "type" = "email"

        # have a look at ./bin/dependencies if you need more information about how to define this
        "dependencies" = [PSCustomObject]@{
            "psScripts" = @()
            "psModules" = @()
            "psPackages" = @()
        }
        "functions" = [PSCustomObject]@{
            "mailings" = $true
            "lists" = $true
            "preview" = $true
            "upload" = $true
            "broadcast" = $true    
        }
    }
}
