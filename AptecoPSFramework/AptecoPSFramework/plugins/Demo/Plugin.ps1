function Get-CurrentPluginInfo {
    [PSCustomObject]@{

        # identifier for this plugin - please do not change or use this twice
        "guid" = "07f5de5b-1c83-4300-8f17-063a5fdec901"

        # general information about this plugin
        "name" = "Demo"
        "version" = "0.0.1"
        "lastUpdate" = "2023-06-23"
        "category" = "channel"
        "type" = "email"
        "stage" = "test"

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
        }

    }
}
