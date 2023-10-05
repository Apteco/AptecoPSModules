function Get-CurrentPluginInfo {
    [PSCustomObject]@{

        # identifier for this plugin - please do not change or use this twice
        "guid" = "3adb8696-c219-49c7-906b-92680727a1c1"

        # general information about this plugin
        "name" = "CleverReach"
        "version" = "0.1.1"
        "lastUpdate" = "2023-10-05"
        "category" = "channel"
        "type" = "email"
        "stage" = "test"

        # have a look at ./bin/dependencies if you need more information about how to define this
        "dependencies" = [PSCustomObject]@{
            "psScripts" = @()
            "psModules" = @(
                "PSOAuth"       # TODO make sure this module is loaded
                "ConvertStrings"
                "TestCredential"
            )
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
