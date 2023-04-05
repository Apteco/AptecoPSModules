Function Create-AptecoSession {

    #-----------------------------------------------
    # LOAD ENDPOINTS
    #-----------------------------------------------

    If ( $Script:endpoints -eq $null ) {
        Get-Endpoints
    }

    #-----------------------------------------------
    # LOAD CREDENTIALS
    #-----------------------------------------------

    #$credentials = new-object -typename System.Management.Automation.PSCredential -argumentlist $settings.user,($settings.password | ConvertTo-SecureString)
    $user = $settings.login.user #$credentials.GetNetworkCredential().Username
    #$pw = $credentials.GetNetworkCredential().password
    #$pw = Get-SecureToPlaintext -String $settings.login.pass

    #-----------------------------------------------
    # PREPARE LOGIN
    #-----------------------------------------------

    $headers = @{
        "accept"="application/json"
    }

    switch ( $settings.loginType ) {


        #-----------------------------------------------
        # SIMPLE LOGIN PREPARATION
        #-----------------------------------------------

        "SIMPLE" {

            $endpointKey = "CreateSessionSimple"

            $body = @{
                "UserLogin" = $user
                "Password" = Get-SecureToPlaintext -String $settings.login.pass
            }

        }



        #-----------------------------------------------
        # SALTED LOGIN PREPARATION
        #-----------------------------------------------

        "SALTED" {

            # GET LOGIN DETAILS FIRST

            #$endpoint = Get-Endpoint -key "CreateLoginParameters"
            
            $body = @{
                "userName"=$user
            }

            #$uri = Resolve-Url -endpoint $endpoint
            $loginDetails = Invoke-Apteco -key "CreateLoginParameters" -body $body -contentType "application/x-www-form-urlencoded" -verboseCall
            #$loginDetails = Invoke-RestMethod -Uri $uri -Method $endpoint.method -ContentType "application/x-www-form-urlencoded" -Headers $headers -Body $body -Verbose


            # GET ALL INFORMATION TOGETHER

            $endpointKey = "CreateSessionSalted"

            <#
            1. "Encrypt" password + optionally add salt
            2. Hash that string
            3. Add LoginSalt and hash again
            #>

            $pwStepOne = Crypt-Password -password ( Get-SecureToPlaintext -String $settings.login.pass )

            if ($loginDetails.saltPassword -eq $true -and $loginDetails.userSalt -ne "") {

                # TODO [ ] test password salting (and if userSalt from API is the correct value for that)
                # TODO [ ] put salt in settings
                $pwStepOne += $loginDetails.userSalt

            }

            $pwStepTwo = Get-StringHash -inputString $pwStepOne -hashName $loginDetails.hashAlgorithm -uppercase $false
            $pwStepThree = Get-StringHash -inputString $pwStepTwo -hashName $loginDetails.hashAlgorithm -salt $loginDetails.loginSalt -uppercase $false

            $body = @{
                "Username"=$user
                "LoginSalt"=$loginDetails.loginSalt
                "PasswordHash"=$pwStepThree
            }
                
        }

    }

    #-----------------------------------------------
    # LOGIN + GET SESSION
    #-----------------------------------------------

    #$uri = Resolve-Url -endpoint $endpoint
    $login = Invoke-Apteco -key $endpointKey -body $body -contentType "application/x-www-form-urlencoded" -verboseCall
    #$login = Invoke-RestMethod -Uri $uri -Method $endpoint.method -ContentType "application/x-www-form-urlencoded" -Headers $headers -Body $body -Verbose


    #-----------------------------------------------
    # SAVE SESSION
    #-----------------------------------------------
    
    # Encrypt token?
    if ( $settings.encryptToken ) {
        $Script:sessionId = Get-PlaintextToSecure -String $login.sessionId
        $Script:accessToken = Get-PlaintextToSecure -String $login.accessToken
    } else {
        $Script:sessionId = $login.sessionId
        $Script:accessToken = $login.accessToken
    }

    # Calculate expiration date
    $expire = [datetime]::now.AddMinutes($settings.ttl).ToString("yyyyMMddHHmmss")

    # Create session file and save it
    $session = @{
        sessionId=$Script:sessionId
        accessToken=$Script:accessToken
        expire=$expire
    }
    $session | ConvertTo-Json | Set-Content -Encoding UTF8 -Path $settings.sessionFile


    #-----------------------------------------------
    # RETURN SUCCESS OR FAILURE
    #-----------------------------------------------

    # true, if the functions is coming to the end?
    return $true

}

