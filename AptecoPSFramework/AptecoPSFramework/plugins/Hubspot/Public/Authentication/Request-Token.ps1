function Request-Token {
    [CmdletBinding()]
    param (
         [Parameter(Mandatory=$false)][String]$SettingsFile = "./hubspot_token_settings.json"
        ,[Parameter(Mandatory=$false)][String]$TokenFile = "./hubspot.token"
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
        $clientId = "9c81c39f-97d9-46a9-b6c2-05a3c6211c21"
        $clientSecret = Read-Host -AsSecureString "Please ask Apteco to enter the client secret"
        $clientCred = [pscredential]::new("dummy",$clientSecret)


        #-----------------------------------------------
        # ASK FOR ANOTHER USER TO ENCRYPT
        #-----------------------------------------------

        $encryptScriptBlock = {
            param($str)
            Import-Module EncryptCredential
            $ret = Convert-PlaintextToSecure $str
            return $ret
        }

        Write-Log "It is important to encrypt the client secret." -Severity INFO
        Write-Log "This module will be called from the Apteco service user and encryption is tied to that." -Severity INFO
        $registerPsRepoDecision = $Host.UI.PromptForChoice("", "Do you want to use another user than '$( $env:Username )' for encryption?", @('&Yes'; '&No'), 1)
        If ( $registerPsRepoDecision -eq "0" ) {

            # Means yes and proceed
            $credCounter = 0
            $taskCredTest = $false
            Do {
                $taskCred = Get-Credential -Message "Credentials for executing the task"
                $taskCredTest = Test-Credential -Credentials $taskCred
                $credCounter += 1
            } Until ( $taskCredTest -eq $true -or $credCounter -ge 3) # max 3 tries

            If ( $taskCredTest -eq $false ) {
                $msg = "There is a problem with your entered credentials. Please try again later."
                Write-Log -Message $msg -Severity ERROR
                throw $msg
            }

            # Create a job to encrypt the secret
            $secretJob = Start-Job -ScriptBlock $encryptScriptBlock -ArgumentList $clientCred.GetNetworkCredential().password -Credential $taskCred

            # Wait until job is not running anymore
            While ( $secretJob.State -eq "Running" ) {
                Start-Sleep -Milliseconds 100
            }

            # Check the result of the job
            Switch ( $secretJob.State ) {

                "Completed" {
                    $encryptedSecret = ( Receive-Job -Job $secretJob ).toString()
                }

                "Failed" {
                    $msg = "Job state: Failed! There is a problem with encrypting the secret"
                    Write-Log -Severity ERROR -Message $msg
                    throw $msg
                }

                "Stopped" {
                    $msg = "Job state: Stopped! There is a problem with encrypting the secret"
                    Write-Log -Severity ERROR -Message $msg
                    throw $msg
                }

                Default {
                    $msg = "Unknown job state $( $secretJob.State )! There is a problem with encrypting the secret"
                    Write-Log -Severity ERROR -Message $msg
                    throw $msg
                }

            }


        } else {

            # Means no and just encrypt with current user
            $encryptedSecret = Invoke-Command -ScriptBlock $encryptScriptBlock -ArgumentList $clientCred.GetNetworkCredential().password

        }


        #-----------------------------------------------
        # BUILD THE SCOPE
        #-----------------------------------------------

        $scope = @(
            #"oauth"
            "crm.lists.read"
            "crm.lists.write"
            "crm.objects.contacts.read"
            "crm.objects.contacts.write"
            "crm.objects.companies.read"
            "crm.objects.companies.write"
            "crm.objects.deals.read"
            "crm.objects.deals.write"
            "crm.objects.custom.read"
            "crm.objects.custom.write"
            #"crm.objects.feedback_submissions.read" # TODO this is currently under work in Hubspot
            #"crm.schemas.custom.read"
            #"crm.schemas.contacts.read"
            #"crm.schemas.companies.read"
            #"crm.schemas.deals.read"
        )
        

        #-----------------------------------------------
        # SET THE PARAMETERS
        #-----------------------------------------------

        $redirectUri = "http://localhost:54321/"

        $oauthParam = [Hashtable]@{
            "ClientId" = $clientId
            "ClientSecret" = $clientCred.GetNetworkCredential().password     # this will be asked for in the next step
            "AuthUrl" = "https://app.hubspot.com/oauth/authorize"
            "TokenUrl" = "https://api.hubapi.com/oauth/v1/token"
            "SaveSeparateTokenFile" = $Script:settings.token.exportTokenToFile
            "RedirectUrl" = $redirectUri
            "SettingsFile" = $SettingsFile
            "Scope" = ( $scope -join " " )
            "SaveExchangedPayload" = $true
            "PayloadToSave" = [PSCustomObject]@{
                "clientid" = $clientId
                "secret" = $encryptedSecret #$clientCred.GetNetworkCredential().password  # TODO maybe encrypt this?
                "redirectUri" = $redirectUri
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

        $Script:settings.token.tokenFilePath = ( get-item -Path $TokenFile ).fullname
        $Script:settings.token.tokenSettingsFile = ( get-item -Path $SettingsFile ).fullname

    }

    end {

    }
}