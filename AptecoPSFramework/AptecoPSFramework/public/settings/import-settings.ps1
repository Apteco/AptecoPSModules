Function Import-Settings {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)][string]$Path = "./settings.json"
    )

    Process {

        # Try to resolve the path
        $absolutePath = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($Path)

        try {

            If ( ( Test-Path -Path $absolutePath -IsValid ) -eq $true ) {

                If (( Test-Path -Path $absolutePath ) -eq $true) {

                    # Load the new settings file
                    try {
                        $settings = Get-Content -Path $absolutePath -Encoding utf8 -Raw | ConvertFrom-Json
                    } catch {
                        Write-Error "There is a problem loading the settings file"
                    }
                    #Write-verbose ( Convertto-json $settings ) -verbose

                    # Register all plugins
                    try {
                        $settings.pluginFolders | ForEach-Object {
                            Add-PluginFolder $_
                        }
                    } catch {
                        Write-Error "There is a problem registering plugins"
                    }

                    # First extend the default settings with the settings file
                    <#
                    try {
                        $defaultSettings = $Script:defaultSettings.psobject.copy()
                        $extendedSettings = Add-PropertyRecurse -source $settings -toExtend $defaultSettings
                        #Write-verbose ( Convertto-json $extendedSettings ) -verbose
                    } catch {
                        Write-Error -Message "Settings cannot be added"

                    }
                    #>

                    # Then make sure to overwrite existing values that are matching
                    <#
                    try {
                        $joinedSettings = Join-Objects -source $extendedSettings -extend $settings
                    } catch {
                        Write-Error -Message "Settings cannot be joined"
                    }
                    #>
                    #$script:debug = $joinedSettings

                    try {
                        $joinedSettings = Join-PSCustomObject -Left $Script:defaultSettings -Right $settings -AddPropertiesFromRight -MergePSCustomObjects -MergeHashtables #-MergeArrays
                    } catch {
                        Write-Error -Message "Settings cannot be joined"
                    }

                    # Set the settings into the module (modules defaultsettings + imported settings)
                    try {
                        Set-Settings -PSCustom $joinedSettings
                    } catch {
                        Write-Error -Message "Settings cannot be loaded - Round 1"
                    }

                    # TODO [x] load the plugins from the settings file, if present
                    try {
                        Import-Plugin -guid $settings.plugin.guid
                    } catch {
                        Write-Error -Message "Plugin cannot be imported"
                    }

                    # Set the settings into the module (settings + plugin settings)
                    # try {
                    #     Set-Settings -PSCustom $joinedSettings
                    # } catch {
                    #     Write-Error -Message "Settings cannot be loaded - Round 2"
                    # }

                }

            } else {

                Write-Error -Message "The settings file '$( $absolutePath )' cannot be loaded."

            }

        } catch {

            Write-Error -Message "The path '$( $absolutePath )' is invalid."

        }

        # Return
        #Get-Settings

    }


}

<#

Inspired by

https://gist.github.com/ksumrall/3b7010a9fbc9c5cb19e9dc8b9ee32fb1


#>