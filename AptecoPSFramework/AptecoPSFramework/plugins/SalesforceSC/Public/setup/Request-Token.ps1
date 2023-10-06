function Request-Token {
    [CmdletBinding()]
    param (
         [Parameter(Mandatory=$true)][String]$ClientId
        ,[Parameter(Mandatory=$true)][Uri]$RedirectUrl
        ,[Parameter(Mandatory=$false)][String]$SettingsFile = "./salesforce_token_settings.json"
        ,[Parameter(Mandatory=$false)][String]$TokenFile = "./salesforce.token"
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
            "ClientId" = $ClientId
            "ClientSecret" = ""     # this will be asked for in the next step
            "AuthUrl" = "https://login.salesforce.com/services/oauth2/authorize"
            "TokenUrl" = "https://login.salesforce.com/services/oauth2/token"
            "SaveSeparateTokenFile" = $true
            "RedirectUrl" = $RedirectUrl
            "SettingsFile" = $SettingsFile
            "TokenFile" = $TokenFile
        }


        #-----------------------------------------------
        # ASK FOR CLIENT SECRET
        #-----------------------------------------------
        
        # Ask to enter the client secret
        $clientSecret = Read-Host -AsSecureString "Please enter the client secret"
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