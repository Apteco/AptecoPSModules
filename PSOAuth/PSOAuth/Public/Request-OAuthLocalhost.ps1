﻿# TODO documentation of parameters
function Request-OAuthLocalhost {
    [CmdletBinding()]

    <#
    .SYNOPSIS
        Requesting oAuth v2 flow for an app via localhost

    .DESCRIPTION
        Apteco PS Modules - PowerShell OAuthV2 flow

    .PARAMETER ClientID
        The client id that will be sent in this flow

    .PARAMETER ClientSecret
        The client secret that will be sent in this flow - this should be kept secret!!!

    .PARAMETER Scope
        Optionally used parameter to request specific rights. The scope that will be sent in the first step of the oauth flow

    .PARAMETER State
        The state is optionally used and normally uses a random string in multiple steps of this flow to prevent CSRF attacks

    .PARAMETER AuthUrl
        The auth url that will be used to initiate this flow

    .PARAMETER TokenUrl
        The token url that will be used to exchange the code into a token

    .PARAMETER RedirectUrl
        The redirect url that will be used after the first login, sth. like http://localhost:54321/
        Please be sure to use the exact url with or without the slash in your app configuration

    .PARAMETER TimeoutForCode
        The timeout that you have time to complete the first step with logging in

    .PARAMETER SettingsFile
        The path to the json file where all settings from this flow are saved into

    .PARAMETER EncryptToken
        Should the token be saved encrypted in the resulting json file

    .PARAMETER SaveSeparateTokenFile
        Should the access token be saved in a separate file and not only in the json file?

    .PARAMETER TokenFile
        The path to the access token file, when the switch SaveSeparateTokenFile is set

    .PARAMETER SaveExchangedPayload
        Do you want to save the payload of the second call, which could contain important information

    .PARAMETER PayloadToSave
        If you want to save more information in the settingsfile, e.g. for refreshing the token, put it in here

    .EXAMPLE
        import-module PSOAuth -Verbose
        $oauthParam = [Hashtable]@{
            "ClientId" = "ssCNo32SNf"
            "ClientSecret" = ""     # ask for this at Apteco, if you don't have your own app
            "AuthUrl" = "https://rest.cleverreach.com/oauth/authorize.php"
            "TokenUrl" = "https://rest.cleverreach.com/oauth/token.php"
            "SaveSeparateTokenFile" = $true
        }
        Request-OAuthLocalhost @oauthParam

    .EXAMPLE
        TODO SALESFORCE EXAMPLE

    .INPUTS
        String

    .OUTPUTS
        $null

    .NOTES
        Author:  florian.von.bracht@apteco.de

    #>

    param (
         [Parameter(Mandatory=$true)][String]$ClientId
        ,[Parameter(Mandatory=$true)][String]$ClientSecret
        ,[Parameter(Mandatory=$true)][Uri]$AuthUrl
        ,[Parameter(Mandatory=$true)][Uri]$TokenUrl
        ,[Parameter(Mandatory=$false)][String]$Scope = "" # Supported since 0.0.6
        ,[Parameter(Mandatory=$false)][String]$State = "" # Supported since 0.0.6
        ,[Parameter(Mandatory=$false)][Uri]$RedirectUrl = "http://localhost:$( Get-Random -Minimum 49152 -Maximum 65535 )/"
        ,[Parameter(Mandatory=$false)][String]$SettingsFile = "./settings.json"
        ,[Parameter(Mandatory=$false)][String]$TokenFile = "./oauth.token"
        #,[Parameter(Mandatory=$false)][String]$CallbackFile = "$( $env:TEMP )\crcallback.txt"
        ,[Parameter(Mandatory=$false)][Switch]$SaveSeparateTokenFile = $false
        ,[Parameter(Mandatory=$false)][int]$TimeoutForCode = 360
        ,[Parameter(Mandatory=$false)][Switch]$EncryptToken = $false
        ,[Parameter(Mandatory=$false)][PSCustomObject]$PayloadToSave = [PSCustomObject]@{}
        ,[Parameter(Mandatory=$false)][Switch]$SaveExchangedPayload = $false
    )

    begin {

        #-----------------------------------------------
        # SET LOGFILE
        #-----------------------------------------------

        # Set log file here, otherwise it could interrupt the process when launched headless from .net in System32
        If ( ( Get-LogfileOverride ) -eq $false ) {
            Set-Logfile -Path "./psoauth.log"
            Write-Log -message "----------------------------------------------------" -Severity VERBOSE
        }


        #-----------------------------------------------
        # ASK FOR SETTINGSFILE
        #-----------------------------------------------
        <#
        # Default file
        $settingsFileDefault = "./settings.json"

        # Ask for another path
        $settingsFile = Read-Host -Prompt "Where do you want the settings file to be saved? Just press Enter for this default [$( $settingsFileDefault )]"

        # ALTERNATIVE: The file dialog is not working from Visual Studio Code, but is working from PowerShell ISE or "normal" PowerShell Console
        #$settingsFile = Set-FileName -initialDirectory "$( $scriptPath )" -filter "JSON files (*.json)|*.json"

        # If prompt is empty, just use default path
        if ( $settingsFile -eq "" -or $null -eq $settingsFile) {
            $settingsFile = $settingsFileDefault
        }
        #>

        # Check if filename is valid
        if(Test-Path -LiteralPath $SettingsFile -IsValid ) {
            Write-Log "SettingsFile '$( $SettingsFile )' is valid"
        } else {
            Write-Log "SettingsFile '$( $SettingsFile )' contains invalid characters"
        }


        #-----------------------------------------------
        # ASK FOR TOKENFILE
        #-----------------------------------------------
        <#
        # Default file
        $tokenFileDefault = "./oauth.token"

        # Ask for another path
        $tokenFile = Read-Host -Prompt "Where do you want the token file to be saved? Just press Enter for this default [$( $tokenFileDefault )]"

        # ALTERNATIVE: The file dialog is not working from Visual Studio Code, but is working from PowerShell ISE or "normal" PowerShell Console
        #$settingsFile = Set-FileName -initialDirectory "$( $scriptPath )" -filter "JSON files (*.json)|*.json"

        # If prompt is empty, just use default path
        if ( $tokenFile -eq "" -or $null -eq $tokenFile) {
            $tokenFile = $tokenFileDefault
        }
        #>

        # Check if filename is valid
        if(Test-Path -LiteralPath $tokenFile -IsValid ) {
            Write-Log "SettingsFile '$( $tokenFile )' is valid"
        } else {
            Write-Log "SettingsFile '$( $tokenFile )' contains invalid characters"
        }


    }

    process {

        #-----------------------------------------------
        # CONFIRM FOR NEXT STEPS
        #-----------------------------------------------

        # Confirm you want to proceed
        $proceed = $Host.UI.PromptForChoice("New Token", "This will create a NEW token. Previous tokens will be invalid immediatly. Please confirm you are sure to proceed?", @('&Yes'; '&No'), 1)

        # Leave if answer is not yes
        If ( $proceed -eq 0 ) {
            Write-Log -message "Asked for confirmation of new token creation. Answer was 'yes'"
        } else {
            Write-Log -message "Asked for confirmation of new token creation. Answer was 'No'"
            Write-Log -message "Leaving the script now"
            exit 0
        }


        #-----------------------------------------------
        # SETTINGS FOR THE TOKEN CREATION
        #-----------------------------------------------

        #$clientCred = New-Object PSCredential $ClientId,$ClientSecret


        #-----------------------------------------------
        # OAUTHv2 PROCESS - STEP 1
        #-----------------------------------------------

        # STEP 1: Prepare the first call to let the user log into the service
        # SOURCE: https://powershellmagazine.com/2019/06/14/pstip-a-better-way-to-generate-http-query-strings-in-powershell/
        $nvCollection  = [System.Web.HttpUtility]::ParseQueryString([String]::Empty)
        $nvCollection.Add('response_type','code')
        $nvCollection.Add('client_id',$ClientId)
        $nvCollection.Add('grant',"basic")
        $nvCollection.Add('redirect_uri', $RedirectUrl) # a dummy url like apteco.de is needed
        If ( $Scope.length -gt 0 ) {
            $nvCollection.Add('scope', $Scope) # Set only the scope, if it is filled
        }
        If ( $State.length -gt 0 ) {
            $nvCollection.Add('state', $State) # Set only the state, if it is filled
        }

        # Create the url
        $uriRequest = [System.UriBuilder]$AuthUrl
        $uriRequest.Query = $nvCollection.ToString()

        # Open the default browser with the generated url
        Write-Log -message "Opening the browser now to allow the access to the account"
        Write-Log -message "$( $uriRequest.Uri.OriginalString )"
        Write-Log -message "Please finish the process in your browser now"
        Write-Log -message "NOTE:"
        Write-Log -message "  APTECO WILL NOT GET ACCESS TO YOUR DATA THROUGH THE APP!"
        Write-Log -message "  ONLY THIS LOCAL GENERATED TOKEN CAN BE USED FOR ACCESS!"
        Start-Process $uriRequest.Uri.OriginalString


        #-----------------------------------------------
        # PREPARE WEBSERVER LISTENER FOR CALLBACK
        #-----------------------------------------------

        $webserverProcess = [scriptblock]{

            param(
                [uri]$redirect
            )

            Add-Type -AssemblyName System.Web

            $http = [System.Net.HttpListener]::new()

            # Hostname and port to listen on
            $http.Prefixes.Add($redirect)

            # Start the Http Server
            $http.Start()

            # Log ready message to terminal
            if ($http.IsListening) {
                #Write-Information -MessageData " HTTP Server Ready on '$( $http.Prefixes )'"
            } else {
                throw "There was an error starting the HTTP server, pleasy retry or choose another port"
            }

            # Let the webserver listen, this loop gets only executed when a request takes place
            #$r = $null
            $closeHttpListener = $false
            $code = ""
            do {

                # Get Request Url
                # When a request is made in a web browser the GetContext() method will return a request object
                $context = $http.GetContext()

                # Raw url
                if ($context.Request.HttpMethod -eq 'GET' -and $context.Request.RawUrl -eq '/') {

                    # We can log the request to the terminal
                    #write-host "$($context.Request.UserHostAddress)  =>  $($context.Request.Url)" -f 'mag'

                    # the html/data you want to send to the browser
                    # you could replace this with: [string]$html = Get-Content "C:\some\path\index.html" -Raw
                    [string]$html = "Waiting for Code."

                    #resposed to the request
                    $buffer = [System.Text.Encoding]::UTF8.GetBytes($html) # convert htmtl to bytes
                    $context.Response.ContentLength64 = $buffer.Length
                    $context.Response.OutputStream.Write($buffer, 0, $buffer.Length) #stream to broswer
                    $context.Response.OutputStream.Close() # close the response

                }

                # If the url contains the code
                if ( $context.request.RawUrl -like "*code=*" ) {

                    #Write-Verbose "Got a code" -verbose

                    # Looking for code in query
                    $callbackUri = [uri]$context.Request.Url
                    $callbackUriSegments = [System.Web.HttpUtility]::ParseQueryString($callbackUri.Query)
                    $code = $callbackUriSegments["code"]
                    $state = $callbackUriSegments["state"]

                    #$r = $context
                    $closeHttpListener = $true

                    # We can log the request to the terminal
                    #write-host "$($context.Request.UserHostAddress)  =>  $($context.Request.Url)" -f 'mag'

                    # the html/data you want to send to the browser
                    # you could replace this with: [string]$html = Get-Content "C:\some\path\index.html" -Raw
                    [string]$html = "<h1>Received code: $( $code )</h1>"

                    #resposed to the request
                    $buffer = [System.Text.Encoding]::UTF8.GetBytes($html) # convert htmtl to bytes
                    $context.Response.ContentLength64 = $buffer.Length
                    $context.Response.OutputStream.Write($buffer, 0, $buffer.Length) #stream to broswer
                    $context.Response.OutputStream.Close() # close the response

                }

                <#
                a few examples
                $context.Request.HttpMethod gives you the method like GET
                $context.Request.RawUrl
                $context.Request.UserHostAddress
                $context.Request.Url
                #>

                # powershell will continue looping and listen for new requests...

            } until ( $closeHttpListener -eq $true ) #$http.IsListening

            # return
            [Hashtable]@{
                "code" = $code
                "state" = $state
            }

        }

        # Start the webserver in the background
        $u = $RedirectUrl #"http://localhost:$( Get-Random -Minimum 49152 -Maximum 65535 )/"
        Write-Log -Message "Listening on: '$( $u )'" #-InformationAction Continue
        $job = Start-Job -Name "ReceiveCodeViaHTTP" -ArgumentList $u -ScriptBlock $webserverProcess #| Wait-Job

        # Work out the maximum waiting time
        If ( $TimeoutForCode -le 0 ) {
            $maxSeconds = 360 # 5 minutes
            Write-Log "Using default waiting time of $( $maxSeconds ) seconds"
        } else {
            $maxSeconds = $TimeoutForCode
        }

        # Show a progress bar and wait for a result
        $waitingStart = [datetime]::Now
        Do {

            # Show the progress
            $ts = New-TimeSpan -Start $waitingStart -End ( [datetime]::now )
            $secondsRemaining = [math]::Ceiling($maxSeconds - $ts.TotalSeconds)
            Write-Progress -Activity "Waiting for callback/redirect" -Status "$( $secondsRemaining ) seconds left" -SecondsRemaining $secondsRemaining -PercentComplete ([math]::Round($secondsRemaining/$maxSeconds*100))

            # Wait
            Start-Sleep -Milliseconds 500

        } While ( $ts.TotalSeconds -lt $maxSeconds -and $job.State -eq "Running")

        # Kill the job in case of error or timeout, if it not completed yet
        If ( $job.State -ne "Completed" ) {
            try {
                $job.StopJob()
            } catch {

            }
        }

        # Look for a result
        $webjob = Receive-Job -Job $job
        $code = $webjob.code

        # Check the code
        If ( $code.Length -gt 0 ) {
            #Write-Host $code
        } else {
            throw "Timeout reached or no usable code received"
            Exit 0
        }

        # Check the state
        If ( $State.length -gt 0 ) {
            If ( $webjob.state -ne $State ) {
                throw "State of initial call does not match the returned state! Exit!"
                Exit 0
            } else {
                Write-Log "State was accepted!"
            }
        }


        #-----------------------------------------------
        # OAUTHv2 PROCESS - STEP 2
        #-----------------------------------------------

        # Prepare the second call to exchange the code quickly for a token
        $postParams = [Hashtable]@{
            Method = "Post"
            Uri = $tokenUrl
            Body = [Hashtable]@{
                "client_id" = $ClientId
                "client_secret" = $ClientSecret
                "redirect_uri" = $RedirectUrl #$redirectUri
                "grant_type" = "authorization_code"
                "code" = $code
            }
            Verbose = $true
        }
        $response = Invoke-RestMethod @postParams

        Write-Log -message "Got a token with scope '$( $response.scope )'"

        # Trying an API call
        <#
        try {

            $headers = @{
                "Authorization" = "Bearer $( $response.access_token )"
            }
            $ttl = Invoke-RestMethod -Uri "https://rest.cleverreach.com/v3/debug/ttl.json" -Method Get -ContentType "application/json; charset=utf-8" -Headers $headers

            Write-Log -message "Used token for API call successfully. Token expires at '$( $ttl.date.toString() )'"

        } catch {

            Write-Log -message "API call was not successful. Aborting the whole script now!" -severity ( [Logseverity]::WARNING )
            throw $_

        }
        #>

        # Clear the variables straight away
        #$clientCred = $null

        If ( $SaveExchangedPayload -eq $true ) {
            ConvertTo-Json -InputObject $response -Depth 99 | Set-Content -path ".\exchange.json" -Encoding UTF8 -Force
        }


        #-----------------------------------------------
        # SAVE THE TOKENS
        #-----------------------------------------------

        # TODO the saving could be put into a separate function

        # Encrypt tokens, if wished
        $refreshToken = ""
        If ( $EncryptToken -eq $true) {
            $accessToken = Get-PlaintextToSecure $response.access_token
            If ( $null -ne $response.refresh_token ) {
                $refreshToken = Get-PlaintextToSecure $response.refresh_token
            }
        } else {
            $accessToken = $response.access_token
            If ( $null -ne $response.refresh_token ) {
                $refreshToken = $response.refresh_token
            }
        }

        # Parse the switch
        $separateTokenFile = $false
        If ( $SaveSeparateTokenFile -eq $true ) {
            $separateTokenFile = $true
        }

        # The settings to save for refreshing
        $set = @{
            "accesstoken" = $accessToken
            "refreshtoken" = $refreshToken
            "tokenFile" = [IO.Path]::GetFullPath([IO.Path]::Combine((Get-Location -PSProvider "FileSystem").ProviderPath, $TokenFile))
            "unixtime" = Get-Unixtime
            "saveSeparateTokenFile" = $separateTokenFile
            "payload" = $PayloadToSave
            #"refreshTokenAutomatically" = $true
            #"refreshTtl" = 604800 # seconds; refresh one week before expiration
        }

        # create json object
        $json = ConvertTo-Json -InputObject $set -Depth 99 # -compress

        # TODO implement PSNotify here for email notifications

        # rename settings file if it already exists
        If ( Test-Path -Path $SettingsFile ) {
            $backupPath = "$( $SettingsFile ).$( $timestamp.ToString("yyyyMMddHHmmss") )"
            Write-Log -message "Moving previous settings file to $( $backupPath )" -severity ( [Logseverity]::WARNING )
            Move-Item -Path $SettingsFile -Destination $backupPath
        } else {
            Write-Log -message "There was no settings file existing yet"
        }

        # print settings to console
        #$json

        # save settings to file
        $json | Set-Content -path $SettingsFile -Encoding UTF8


        #-----------------------------------------------
        # SAVE THE TOKENS AS SEPARATE FILE UNENCRYPTED
        #-----------------------------------------------

        If ( $SaveSeparateTokenFile -eq $true ) {
            Write-Log -message "Saving token to '$( $TokenFile )'"
            $response.access_token | Set-Content -path "$( $TokenFile )" -Encoding UTF8 -Force
        }


    }

    end {

    }

}


#-----------------------------------------------
# TESTING HASHTABLES
#-----------------------------------------------
<#
$leftHt = [hashtable]@{
    "firstname" = "Florian"
    "lastname" = "Friedrichs"
}

$rightHt = [hashtable]@{
    "lastname" = "von Bracht"
    "Street" = "Schaumainkai 87"
}

Join-Hashtable -Left $leftHt -right $rightHt -verbose -AddKeysFromRight
#>
