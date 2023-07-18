function Get-CurrentPluginInfos {
    [PSCustomObject]@{

        # identifier for this plugin - please do not change or use this twice
        "guid" = "83be4a7b-9ab9-4bb7-be20-80a78d691609"
        
        # general information about this plugin
        "name" = "Inxmail Professional"
        "version" = "0.0.1"
        "lastUpdate" = "2023-07-13"
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
