

function Save-NewToken {

    [CmdletBinding()]
    param (
        #[Parameter(Mandatory=$false)][String] $TokenSettingsFile
        #[Parameter(Mandatory=$false)][String] $GroupId
    )

    begin {

    }
    process {

        $newToken = Register-NewTokenViaOauth
        Write-Log -message "Got new token valid until $( $newToken.expires_in )" #-Verbose

        [void]( Request-TokenRefresh -SettingsFile $Script:settings.token.tokenSettingsFile -NewAccessToken $newToken.access_token -NewRefreshToken $newToken.refresh_token  )

        # Return
        $newToken.access_token

    }

    end {

    }

}