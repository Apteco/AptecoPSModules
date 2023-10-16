function Get-CurrentPluginInfo {
    [PSCustomObject]@{

        # identifier for this plugin - please do not change or use this twice
        "guid" = "d2afdcfe-9e59-4b13-9819-c04b50f5f36e"
        
        # general information about this plugin
        "name" = "Salesforce SalesCloud CampaignMembers"
        "version" = "0.0.3"
        "lastUpdate" = "2023-10-16"
        "category" = "channel"
        "type" = "crm"
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
        "functions" = [PSCustomObject]@{
            "mailings" = $true
            "lists" = $true
            "preview" = $true
            "upload" = $true
            "broadcast" = $false    
        }
    }
}
