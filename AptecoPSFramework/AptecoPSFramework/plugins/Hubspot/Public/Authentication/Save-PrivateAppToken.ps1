Function Save-PrivateAppToken {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$false)][String]$TokenFile = "./hubspot.token"
    )

    begin {

    }

    process {

        #-----------------------------------------------
        # ENTER THE TOKEN
        #-----------------------------------------------

        $token = Read-Host -AsSecureString "Please enter your access token from your private app"
        $tokenCred = [pscredential]::new("dummy",$token)


        #-----------------------------------------------
        # SAVE THE TOKEN
        #-----------------------------------------------

        Write-Log -message "Saving token to '$( $TokenFile )'"
        $tokenCred.GetNetworkCredential().password | Set-Content -path "$( $TokenFile )" -Encoding UTF8 -Force


        #-----------------------------------------------
        # WRITE LOG
        #-----------------------------------------------

        Write-Log "Saved a new token" -Severity INFO


        #-----------------------------------------------
        # PUT THIS AUTOMATICALLY INTO SETTINGS
        #-----------------------------------------------

        $Script:settings.token.tokenFilePath = ( get-item -Path $TokenFile ).fullname


    }

    end {

    }

}