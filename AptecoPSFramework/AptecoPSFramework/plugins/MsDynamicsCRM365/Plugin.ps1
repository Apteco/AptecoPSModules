function Get-CurrentPluginInfo {
    [PSCustomObject]@{

        # identifier for this plugin - please do not change or use this twice
        "guid" = "8914f5ef-509f-4f0d-b285-ec9e38cd44e5"

        # general information about this plugin
        "name" = "Microsoft Dynamics CRM 365"
        "version" = "0.1.0"
        "lastUpdate" = "2023-10-23"
        "category" = "data"
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
