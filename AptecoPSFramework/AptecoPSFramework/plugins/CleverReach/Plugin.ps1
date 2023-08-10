function Get-CurrentPluginInfo {
    [PSCustomObject]@{

        # identifier for this plugin - please do not change or use this twice
        "guid" = "3adb8696-c219-49c7-906b-92680727a1c1"

        # general information about this plugin
        "name" = "CleverReach"
        "version" = "0.0.8"
        "lastUpdate" = "2023-08-10"
        "category" = "channel"
        "type" = "email"

        # have a look at ./bin/dependencies if you need more information about how to define this
        "dependencies" = [PSCustomObject]@{
            "psScripts" = @()
            "psModules" = @()
            "psPackages" = @()
        }

        # Supported functions
        "functions" = [PSCustomObject]@{
            "mailings" = $true
            "lists" = $true
            "preview" = $true
            "upload" = $true
            "broadcast" = $true
            "responses" = $true
        }

    }
}
