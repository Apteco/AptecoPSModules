
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

                    # Join settings
                    $joinedSettings = Join-Objects $Script:defaultSettings $settings
                    #$extendedSettings = AddPropertyRecurse $source $joinedSettings
                    
                    # Set the settings into the module
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