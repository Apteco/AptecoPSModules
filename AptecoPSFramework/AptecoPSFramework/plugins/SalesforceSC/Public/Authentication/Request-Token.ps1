function Request-Token {
    [CmdletBinding()]
    param (
         [Parameter(Mandatory=$true)][String]$ClientId
        ,[Parameter(Mandatory=$true)][Uri]$RedirectUrl
        ,[Parameter(Mandatory=$false)][String]$SettingsFile = "./salesforce_token_settings.json"
        ,[Parameter(Mandatory=$false)][String]$TokenFile = "./salesforce.token"
        ,[Parameter(Mandatory=$false)][Switch]$UseStateToPreventCSRFAttacks = $false
    )

    begin {

    }

    process {

        #-----------------------------------------------
        # ASK FOR SETTINGSFILE
        #-----------------------------------------------

        #Import-Module PSOAuth


        #-----------------------------------------------
        # ASK FOR CLIENT SECRET
        #-----------------------------------------------
        
        # Ask to enter the client secret
        $clientSecret = Read-Host -AsSecureString "Please enter the client secret"
        $clientCred = [pscredential]::new("dummy",$clientSecret)
        

        #-----------------------------------------------
        # SET THE PARAMETERS
        #-----------------------------------------------
        
        $oauthParam = [Hashtable]@{
            "ClientId" = $ClientId
            "ClientSecret" = $clientCred.GetNetworkCredential().password     # this will be asked for in the next step
            "AuthUrl" = "https://login.salesforce.com/services/oauth2/authorize"
            "TokenUrl" = "https://login.salesforce.com/services/oauth2/token"
            "SaveSeparateTokenFile" = $true
            "RedirectUrl" = $RedirectUrl
            "SettingsFile" = $SettingsFile
            "PayloadToSave" = [PSCustomObject]@{
                "clientid" = $ClientId
                "secret" = $clientCred.GetNetworkCredential().password  # TODO maybe encrypt this?
            }
            "TokenFile" = $TokenFile
            "SaveExchangedPayload" = $true
        }

        # Add state to prevent CSRF attacks
        If ( $UseStateToPreventCSRFAttacks -eq $true ) {
            $oauthParam.Add("State",( Get-RandomString -Length 24 -ExcludeUpperCase -ExcludeSpecialChars ))
        }

        # Empty that variable
        $clientSecret = ""


        #-----------------------------------------------
        # REQUEST THAT TOKEN
        #-----------------------------------------------

        Request-OAuthLocalhost @oauthParam #-Verbose
        #Request-OAuthApp @oauthParam -Verbose

        
        #-----------------------------------------------
        # PUT THIS AUTOMATICALLY INTO SETTINGS
        #-----------------------------------------------

        $Script:settings.token.tokenFilePath = ( get-item -Path $tokenFile ).fullname
        $Script:settings.token.tokenSettingsFile = ( get-item -Path $tokenSettings ).fullname
        
        
        #-----------------------------------------------
        # WRITE LOG
        #-----------------------------------------------

        Write-Log "Created a new token" -Severity INFO


    }

    end {

    }
}