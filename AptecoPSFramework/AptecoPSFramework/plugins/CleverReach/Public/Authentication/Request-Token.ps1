function Request-Token {
    [CmdletBinding()]
    param (
         [Parameter(Mandatory=$false)][String]$SettingsFile = "./cleverreach_token_settings.json"
        ,[Parameter(Mandatory=$false)][String]$TokenFile = "./cleverreach.token"
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
        $clientId = "ssCNo32SNf"
        $clientSecret = Read-Host -AsSecureString "Please enter the client secret"
        $clientCred = [pscredential]::new("dummy",$clientSecret)
        

        #-----------------------------------------------
        # SET THE PARAMETERS
        #-----------------------------------------------

        $oauthParam = [Hashtable]@{
            "ClientId" = $clientId
            "ClientSecret" = $clientCred.GetNetworkCredential().password     # this will be asked for in the next step
            "AuthUrl" = "https://rest.cleverreach.com/oauth/authorize.php"
            "TokenUrl" = "https://rest.cleverreach.com/oauth/token.php"
            "SaveSeparateTokenFile" = $Script:settings.token.exportTokenToFile
            "RedirectUrl" = "http://localhost:$( Get-Random -Minimum 49152 -Maximum 65535 )/"
            "SettingsFile" = $SettingsFile
            "PayloadToSave" = [PSCustomObject]@{
                "clientid" = $clientId
                "secret" = $clientCred.GetNetworkCredential().password  # TODO maybe encrypt this?
            }
            "TokenFile" = $TokenFile
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
        # WRITE LOG
        #-----------------------------------------------

        Write-Log "Created a new token" -Severity INFO


        #-----------------------------------------------
        # PUT THIS AUTOMATICALLY INTO SETTINGS
        #-----------------------------------------------

        $Script:settings.token.tokenFilePath = ( get-item -Path $tokenFile ).fullname
        $Script:settings.token.tokenSettingsFile = ( get-item -Path $tokenSettings ).fullname


    }

    end {

    }
}