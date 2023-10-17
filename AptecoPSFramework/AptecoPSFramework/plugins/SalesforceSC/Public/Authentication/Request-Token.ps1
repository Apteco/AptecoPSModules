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
                "secret" = $encryptedSecret #$clientCred.GetNetworkCredential().password  # TODO maybe encrypt this?
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