function Request-Token {
    [CmdletBinding()]
    param (
         [Parameter(Mandatory=$true)][String]$ClientId
        ,[Parameter(Mandatory=$true)][Uri]$RedirectUrl
        #,[Parameter(Mandatory=$true)][String]$Scope
        ,[Parameter(Mandatory=$true)][Uri]$CrmUrl
        ,[Parameter(Mandatory=$true)][String]$OrgId   # your organisation ID, a GUID
        ,[Parameter(Mandatory=$false)][String]$SettingsFile = "./dataverse_token_settings.json"
        ,[Parameter(Mandatory=$false)][String]$TokenFile = "./dataverse.token"
        ,[Parameter(Mandatory=$false)][Switch]$UseStateToPreventCSRFAttacks = $false
    )

    begin {

    }

    process {

        #-----------------------------------------------
        # ASK FOR SETTINGSFILE
        #-----------------------------------------------

        #Import-Module PSOAuth

        #$crmUriParts = $CrmUrl.Host.split(".")
        #$orgId = $crmUriParts[0]


        #-----------------------------------------------
        # SET THE PARAMETERS
        #-----------------------------------------------
        
        $oauthParam = [Hashtable]@{
            "ClientId" = $ClientId
            "ClientSecret" = ""     # this will be asked for in the next step
            "AuthUrl" = "https://login.microsoftonline.com/$( $orgId )/oauth2/v2.0/authorize"
            "TokenUrl" = "https://login.microsoftonline.com/$( $orgId )/oauth2/v2.0/token"
            "SaveSeparateTokenFile" = $true
            "RedirectUrl" = $RedirectUrl
            "SettingsFile" = $SettingsFile
            "Scope" = "https://$( $CrmUrl.Host )/user_impersonation offline_access"
            "TokenFile" = $TokenFile
            "SaveExchangedPayload" = $true
        }

        # Add state to prevent CSRF attacks
        If ( $UseStateToPreventCSRFAttacks -eq $true ) {
            $oauthParam.Add("State",( Get-RandomString -Length 24 -ExcludeUpperCase -ExcludeSpecialChars ))
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