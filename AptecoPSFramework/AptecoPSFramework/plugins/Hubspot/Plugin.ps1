function Get-CurrentPluginInfo {
    [PSCustomObject]@{

        # identifier for this plugin - please do not change or use this twice
        "guid" = "a0eadcb8-0eb3-4b19-88c3-9b64b1c18e88"

        # general information about this plugin
        "name" = "Hubspot"
        "version" = "0.0.1"
        "lastUpdate" = "2023-10-19"
        "category" = "channel"
        "type" = "email"
        "stage" = "dev"

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
