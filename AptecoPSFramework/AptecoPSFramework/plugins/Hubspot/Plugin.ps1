function Get-CurrentPluginInfo {
    [PSCustomObject]@{

        # identifier for this plugin - please do not change or use this twice
        "guid" = "a99cccda-a2e4-4ba6-b554-00f106e8b150"

        # general information about this plugin
        "name" = "Hubspot"
        "version" = "0.1.0"
        "lastUpdate" = "2023-10-27"
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
            "lists" = $false
            "preview" = $false
            "upload" = $true
            "broadcast" = $true
            "responses" = $false
        }

    }
}
