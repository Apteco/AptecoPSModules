

function Register-NewTokenViaOauth {

    [CmdletBinding()]
    param (
        #[Parameter(Mandatory=$false)][Hashtable] $InputHashtable
        #[Parameter(Mandatory=$false)][String] $GroupId
    )

    begin {

        #-----------------------------------------------
        # NOTES
        #-----------------------------------------------

        <#

        #>


        #-----------------------------------------------
        # SOME SETTINGS
        #-----------------------------------------------

        $oauthSettingsFile = $Script:settings.token.tokenSettingsFile
        

    }

    process {

        #-----------------------------------------------
        # READ THE OAUTH SETTTINGS
        #-----------------------------------------------

        If (( Test-Path -Path $oauthSettingsFile -IsValid )) {
            If (( Test-Path -Path $oauthSettingsFile )) {
                
                $tokenSettings = Get-Content -Path $oauthSettingsFile -Encoding UTF8 -raw | Convertfrom-json

            } else {

                $msg = "Token settings file does not exist"
                Write-Log $msg -severity ERROR
                throw $msg

            }
        } else {

            $msg = "Path to token settings file is not valid"
            Write-Log $msg -severity ERROR
            throw $msg

        }

        $lastUpdate = ConvertFrom-UnixTime -Unixtime $tokenSettings.unixtime -ConvertToLocalTimezone
        Write-Log "Last token settings file update was made on: $( $lastUpdate.toString() )"


        #-----------------------------------------------
        # BUILD THE NEEDED PARAMETERS
        #-----------------------------------------------

        $body = @{
            "client_id" = $tokenSettings.payload.clientid
            "client_secret" = $tokenSettings.payload.secret
            "grant_type" = "refresh_token"
            "refresh_token" = $tokenSettings.refreshtoken
            #"resource"
        }

        #-----------------------------------------------
        # REFRESH THE TOKEN
        #-----------------------------------------------

        $refreshUrl = [uri]"https://login.salesforce.com/services/oauth2/token"
        $newToken = Invoke-RestMethod -Uri $refreshUrl -ContentType "application/x-www-form-urlencoded" -Method POST -Body $body


        #-----------------------------------------------
        # RETURN
        #-----------------------------------------------

        $newToken


    }

    end {

    }

}



