

function Invoke-Telegram {

    [CmdletBinding()]
    param (
         [Parameter(Mandatory=$true)][String]$Name                                # The telegram channel to use
        ,[Parameter(Mandatory=$false)][String]$Path = ""                            # The path in the url after the object
        ,[Parameter(Mandatory=$false)][PSCustomObject]$Query = [PSCustomObject]@{}  # Query parameters for the url
        #,[Parameter(Mandatory=$false)][Switch]$Paging = $false                      # Automatic paging through the result, only needed for a few calls
        #,[Parameter(Mandatory=$false)][Int]$Pagesize = 0                          # Pagesize, if not defined in settings. For reports the max is 100.
        ,[Parameter(Mandatory=$false)][ValidateScript({
            If ($_ -is [PSCustomObject]) {
                [PSCustomObject]$_
            # } elseif ($_ -is [System.Collections.Specialized.OrderedDictionary]) {
            #     [System.Collections.Specialized.OrderedDictionary]$_
            # }
            #} ElseIf ($_ -is [System.Collections.ArrayList] -or $_ -is [Array]) {
            #    [System.Collections.ArrayList]$_
            }
        })]$Body = [PSCustomObject]@{}   # Body to upload, e.g. for POST and PUT requests, will automatically transformed into JSON
    )
    DynamicParam {
        # All parameters, except Uri and body (needed as an object)
        $p = Get-BaseParameters "Invoke-RestMethod"
        [void]$p.remove("Uri")
        [void]$p.remove("Body")
        $p
    }

    Begin {

        $base = "https://api.telegram.org/"

        # Check if the telegram channel exists
        $channel = Get-TelegramChannel -Name $Name

        # Decrypt token
        $token = Convert-SecureToPlaintext -String $channel.definition.token

        # check type of body, if present
        <#
        If ($Body -is [PSCustomObject]) {
            Write-Host "PSCustomObject"
        } ElseIf ($Body -is [System.Collections.ArrayList]) {
            Write-Host "ArrayList"
        } else {
            Throw 'Body datatype not valid'
        }
        #>

        # check url, if it ends with a slash
        If ( $base.endswith("/") -eq $true ) {
            #$base = $Script:settings.base
        } else {
            $base = "$( $base )/"
        }

        # Reduce input parameters to only allowed ones
        $updatedParameters = Skip-UnallowedBaseParameters -Base "Invoke-RestMethod" -Parameters $PSBoundParameters

        # Add additional headers from the settings, e.g. for api gateways or proxies
        $Script:store.additionalHeaders.PSObject.Properties | ForEach-Object {
            $updatedParameters.add($_.Name, $_.Value)
        }

        # normalize the path, remove leading and trailing slashes
        If ( $Path -ne "") {
            If ( $Path.StartsWith("/") -eq $true ) {
                $Path = $Path.Substring(1)
            }
            If ( $Path.EndsWith("/") -eq $true ) {
                $Path = $Path -replace ".$"
            }
        }

        # Add the contenttype
        $updatedParameters.ContentType = "application/json"

    }

    Process {

        #$finished = $false
        #$return = $null

        # Prepare query
        $nvCollection = [System.Web.HttpUtility]::ParseQueryString([String]::Empty)
        $Query.PSObject.Properties | ForEach-Object {
            $nvCollection.Add( $_.Name, $_.Value )
        }

        # Prepare URL
        #Write-Verbose $Path -verbose
        $uriRequest = [System.UriBuilder]::new("$( $base )bot$( $token )/$( $Path )")
        $uriRequest.Query = $nvCollection.ToString()
        $updatedParameters.Uri = $uriRequest.Uri.OriginalString

        # Prepare Body
        If ( $updatedParameters.ContainsKey("Body") -eq $true ) {
            $bodyJson = ConvertTo-Json -InputObject $Body -Depth 99
            $updatedParameters.Body = $bodyJson
        }

        # Execute the request
        try {

            # Output parameters in debug mode
            # If ( $Script:debugMode -eq $true ) {
            #     Write-Host "REST: $( Convertto-json -InputObject $updatedParameters -Depth 99 )"
            # }

            # If ( $Script:logAPIrequests -eq $true ) {

                 #Write-Verbose -Message "$( $updatedParameters.Method.ToString().ToUpper() ) $( $updatedParameters.Uri )" -verbose
                 #Write-verbose -message "$( $updatedParameters.Body )" -verbose
            # }
            $wr = Invoke-RestMethod @updatedParameters
            
            If ( $wr.ok -eq $true ) {
                $return = $wr.result
            } else {
                throw "Error at telegram request"
            }
            
            #$finished = $true

        } catch {
            #Write-Log -Message $_.Exception.Message -Severity ERROR
            throw $_.Exception
        }

        $return


    }

    End {

    }

 }

