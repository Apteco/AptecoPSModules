
Function Import-Settings {

    [cmdletbinding()]
    param(
        [Parameter(Mandatory=$true)][string]$Path
    )

    Process {

        try {
            
            If ( ( Test-Path -Path $Path -IsValid ) -eq $true ) {

                If (( Test-Path -Path $Path ) -eq $true) {

                    # Load the new settings file
                    $settings = Get-Content -Path $Path -Encoding utf8 -Raw | ConvertFrom-Json
                    #Write-verbose ( Convertto-json $settings ) -verbose
                    
                    # First extend the default settings with the settings file
                    $defaultSettings = $Script:defaultSettings.psobject.copy()
                    $extendedSettings = Add-PropertyRecurse -source $settings -toExtend $defaultSettings
                    #Write-verbose ( Convertto-json $extendedSettings ) -verbose

                    # Then make sure to overwrite existing values that are matching
                    $joinedSettings = Join-Objects -source $extendedSettings -extend $settings
                    #$script:debug = $joinedSettings

                    # Set the settings into the module (modules defaultsettings + imported settings)
                    Set-Settings -PSCustom $joinedSettings

                    # TODO [x] load the plugins from the settings file, if present
                    Import-Plugin -guid $settings.plugin.guid
                    
                    # Set the settings into the module (settings + plugin settings)
                    Set-Settings -PSCustom $joinedSettings

                }
    
            } else {

                Write-Error -Message "The path '$( $Path )' is invalid."

            }

        } catch {

            Write-Error -Message "The path '$( $Path )' is invalid."

        }

        # Return
        #Get-Settings

    }


}

<#

Inspired by

https://gist.github.com/ksumrall/3b7010a9fbc9c5cb19e9dc8b9ee32fb1


#>