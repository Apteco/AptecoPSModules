# TODO documentation of parameters

function Request-OAuthApp {
    [CmdletBinding()]
    param (
         [Parameter(Mandatory=$true)][String]$ClientId
        ,[Parameter(Mandatory=$true)][String]$ClientSecret
        ,[Parameter(Mandatory=$true)][Uri]$AuthUrl
        ,[Parameter(Mandatory=$true)][Uri]$TokenUrl
        ,[Parameter(Mandatory=$false)][String]$Scope = "" # TODO not yet implemented
        #,[Parameter(Mandatory=$false)][String]$State = "" # TODO not yet implemented
        ,[Parameter(Mandatory=$false)][String]$Protocol = "apttoken$( Get-RandomString -length 6 -ExcludeSpecialChars )"
        ,[Parameter(Mandatory=$false)][String]$SettingsFile = "./settings.json"
        ,[Parameter(Mandatory=$false)][String]$TokenFile = "./oauth.token"
        #,[Parameter(Mandatory=$false)][String]$CallbackFile = "$( $env:TEMP )\crcallback.txt"
        ,[Parameter(Mandatory=$false)][Switch]$SaveSeparateTokenFile = $false
        ,[Parameter(Mandatory=$false)][Switch]$EncryptToken = $false
    )

    begin {

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

        try {

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
            $CallbackFile = "$( $env:TEMP )\callback.txt"


            #-----------------------------------------------
            # PREPARE REGISTRY
            #-----------------------------------------------

            # current path - will get back to this at the end
            $currentLocation = Get-Location

            # Switch to registry - choose the current user to not need admin rights
            $root = "Registry::HKEY_CURRENT_USER\Software\Classes" # User registry - needs no elevated rights
            # $root = "Registry::HKEY_CLASSES_ROOT" # Global registry - needs admin rights
            Write-Log -message "Putting new registry entries into '$( $root )' with custom protocol '$( $Protocol )'"
            Set-Location -Path $root

            # Remove the registry entries, if already existing
            If ( Test-Path -path $Protocol ) {
                Write-Log -message "Custom protocol folder was already existing. Removing it now."
                Remove-Item -Path $Protocol -Force
            }

            # Create the base entries now
            New-Item -Path $Protocol
            New-ItemProperty -Path $Protocol -Name "(Default)" -PropertyType String -Value "URL:$( $Protocol )"
            New-ItemProperty -Path $Protocol -Name "URL Protocol" -PropertyType String -Value ""

            # Create more keys and properties for sub items
            Set-Location -Path ".\$( $Protocol )"
            New-Item -Path ".\DefaultIcon"
            New-Item -Path ".\shell\open\command" -force # Creates the items recursively
            New-ItemProperty -Path ".\shell\open\command" -Name "(Default)" -PropertyType String -Value """powershell.exe"" -File ""$( $Script:moduleRoot )\bin\callback.ps1"" ""%1"""

            # Go back to original path
            Set-Location -path $currentLocation.Path

            Write-Log -message "Created the registry entries"


            #-----------------------------------------------
            # OAUTHv2 PROCESS - STEP 1
            #-----------------------------------------------

            # Prepare redirect URI
            $redirectUri = "$( $Protocol )://localhost"

            # STEP 1: Prepare the first call to let the user log into the service
            # SOURCE: https://powershellmagazine.com/2019/06/14/pstip-a-better-way-to-generate-http-query-strings-in-powershell/
            $nvCollection  = [System.Web.HttpUtility]::ParseQueryString([String]::Empty)
            $nvCollection.Add('response_type','code')
            $nvCollection.Add('client_id',$ClientId)
            $nvCollection.Add('grant',"basic")
            $nvCollection.Add('redirect_uri', $redirectUri) # a dummy url like apteco.de is needed

            # Create the url
            $uriRequest = [System.UriBuilder]$authUrl
            $uriRequest.Query = $nvCollection.ToString()

            # Remove callback file if it exists
            If ( Test-Path -Path $CallbackFile ) {
                "Removing callback file '$( $CallbackFile )'"
                Remove-Item $CallbackFile -Force
            }

            # Open the default browser with the generated url
            Write-Log -message "Opening the browser now to allow the access to the account"
            Write-Log -message "Please finish the process in your browser now"
            Write-Log -message "NOTE:"
            Write-Log -message "  APTECO WILL NOT GET ACCESS TO YOUR DATA THROUGH THE APP!"
            Write-Log -message "  ONLY THIS LOCAL GENERATED TOKEN CAN BE USED FOR ACCESS!"
            Start-Process $uriRequest.Uri.OriginalString

            # Wait
            Write-Log -message "Waiting for the callback file '$( $CallbackFile )'"
            Do {
                Write-Host "." -NoNewline
                Start-Sleep -Milliseconds 500
            } Until ( Test-Path -Path $callbackFile )

            Write-Log -message "Callback file found '$( $CallbackFile )'"

            # Read and parse callback file
            $callback = Get-Content -Path $callbackFile -Encoding utf8
            $callbackUri = [uri]$callback
            $callbackUriSegments = [System.Web.HttpUtility]::ParseQueryString($callbackUri.Query)
            $code = $callbackUriSegments["code"]


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
                    "redirect_uri" = $redirectUri
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
                throw $_.Exception

            }
            #>

            # Clear the variables straight away
            #$clientCred = $null


            #-----------------------------------------------
            # SAVE THE TOKENS
            #-----------------------------------------------

            # TODO the saving could be put into a separate function

            # Encrypt tokens, if wished
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

        } catch {

            Write-Log "ERROR: $( $_.Exception.Message )" -Severity ERROR
            throw $_.Exception

        } finally {

            #-----------------------------------------------
            # HOUSEKEEPING OF REGISTRY
            #-----------------------------------------------

            Write-Log -message "Removing temporary registry entries"

            # current path - will get back to this at the end
            $currentLocation = Get-Location

            # Switch to registry - choose the current user to not need admin rights
            $root = "Registry::HKEY_CURRENT_USER\Software\Classes" # User registry - needs no elevated rights
            # $root = "Registry::HKEY_CLASSES_ROOT" # Global registry - needs admin rights

            # Switch to root path of registry
            Set-Location -Path $root

            # Remove item now
            Remove-Item $Protocol -Recurse

            # Go back to original path
            Set-Location -path $currentLocation.Path


            #-----------------------------------------------
            # HOUSEKEEPING OF FILES
            #-----------------------------------------------

            Write-Log -message "Removing callback file now"

            # Remove callback file
            Remove-Item $CallbackFile -Force


            #-----------------------------------------------
            # LOG
            #-----------------------------------------------

            Write-Log -Severity INFO -Message "You can close your browser window now!"

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
