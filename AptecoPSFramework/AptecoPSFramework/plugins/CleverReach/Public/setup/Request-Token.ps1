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
        # SET THE PARAMETERS
        #-----------------------------------------------

        $oauthParam = [Hashtable]@{
            "ClientId" = "ssCNo32SNf"
            "ClientSecret" = ""     # This will be asked in a moment for
            "AuthUrl" = "https://rest.cleverreach.com/oauth/authorize.php"
            "TokenUrl" = "https://rest.cleverreach.com/oauth/token.php"
            "SaveSeparateTokenFile" = $Script:settings.token.exportTokenToFile
            "RedirectUrl" = "http://localhost:$( Get-Random -Minimum 49152 -Maximum 65535 )/"
            "SettingsFile" = $SettingsFile
            "TokenFile" = $TokenFile
        }

        # Add state to prevent CSRF attacks
        If ( $UseStateToPreventCSRFAttacks -eq $true ) {
            $oauthParam.Add("State",( Get-RandomString -Length 24 -ExcludeUpperCase -ExcludeSpecialChars ))
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