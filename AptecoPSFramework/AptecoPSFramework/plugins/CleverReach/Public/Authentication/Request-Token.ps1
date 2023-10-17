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
            "ClientId" = $clientId
            "ClientSecret" = $clientCred.GetNetworkCredential().password     # this will be asked for in the next step
            "AuthUrl" = "https://rest.cleverreach.com/oauth/authorize.php"
            "TokenUrl" = "https://rest.cleverreach.com/oauth/token.php"
            "SaveSeparateTokenFile" = $Script:settings.token.exportTokenToFile
            "RedirectUrl" = "http://localhost:$( Get-Random -Minimum 49152 -Maximum 65535 )/"
            "SettingsFile" = $SettingsFile
            "PayloadToSave" = [PSCustomObject]@{
                "clientid" = $clientId
                "secret" = $encryptedSecret #$clientCred.GetNetworkCredential().password  # TODO maybe encrypt this?
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