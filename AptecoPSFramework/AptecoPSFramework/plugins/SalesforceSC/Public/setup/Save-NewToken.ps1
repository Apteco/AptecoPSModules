

function Save-NewToken {

    [CmdletBinding()]
    param (
        #[Parameter(Mandatory=$false)][String] $TokenSettingsFile
        #[Parameter(Mandatory=$false)][String] $GroupId
    )

    begin {

    }
    process {

        $newToken = Register-NewToken
        Write-Log -message "Got new token valid for $( $newToken.expires_in ) seconds and scope '$( $newToken.scope )'" #-Verbose

        Request-TokenRefresh -SettingsFile $Script:settings.token.tokenSettingsFile -NewAccessToken $newToken.access_token -NewRefreshToken $newToken.refresh_token

    }

    end {

    }

}