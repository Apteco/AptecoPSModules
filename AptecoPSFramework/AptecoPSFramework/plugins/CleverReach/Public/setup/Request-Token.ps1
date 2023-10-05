function Request-Token {
    [CmdletBinding()]
    param (
         [Parameter(Mandatory=$false)][String]$SettingsFile = "./cleverreach_token_settings.json"
        ,[Parameter(Mandatory=$false)][String]$TokenFile = "./cleverreach.token"
    )

    begin {

    }

    process {

        #-----------------------------------------------
        # ASK FOR SETTINGSFILE
        #-----------------------------------------------

        #Import-Module PSOAuth


        #-----------------------------------------------
        # SET THE PARAMETERS
        #-----------------------------------------------

        $oauthParam = [Hashtable]@{
            "ClientId" = "ssCNo32SNf"
            "ClientSecret" = ""     # ask for this at Apteco, if you don't have your own app
            "AuthUrl" = "https://rest.cleverreach.com/oauth/authorize.php"
            "TokenUrl" = "https://rest.cleverreach.com/oauth/token.php"
            "SaveSeparateTokenFile" = $Script:settings.token.exportTokenToFile
            "RedirectUrl" = "http://localhost:$( Get-Random -Minimum 49152 -Maximum 65535 )/"
            "SettingsFile" = $SettingsFile
            "TokenFile" = $TokenFile
        }


        #-----------------------------------------------
        # ASK APTECO FOR CLIENT SECRET
        #-----------------------------------------------
        
        # Ask APTECO to enter the client secret
        Write-Log -message "Asking Apteco about the CleverReach App client secret"
        $clientSecret = Read-Host -AsSecureString "Please ask Apteco to enter the client secret"
        $clientCred = [pscredential]::new("dummy",$clientSecret)
        $oauthParam.ClientSecret = $clientCred.GetNetworkCredential().password
        $clientSecret = ""

        
        #-----------------------------------------------
        # REQUEST THAT TOKEN
        #-----------------------------------------------

        Request-OAuthLocalhost @oauthParam #-Verbose
        #Request-OAuthApp @oauthParam -Verbose

        #-----------------------------------------------
        # WRITE LOG
        #-----------------------------------------------

        Write-Log "Created a new token" -Severity INFO


    }

    end {

    }
}