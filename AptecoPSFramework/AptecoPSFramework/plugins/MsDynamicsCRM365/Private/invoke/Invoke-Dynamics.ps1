
Function Invoke-Dynamics {

    [CmdletBinding()]
    param (
         #[Parameter(Mandatory=$true)][String]$Object                                # The cleverreach object like groups or mailings (first part after the main url)
         [Parameter(Mandatory=$false)][String]$Service = "data"
        ,[Parameter(Mandatory=$false)][String]$ContentType = "application/json; charset=utf-8"
        ,[Parameter(Mandatory=$false)][String]$Path = ""                            # The path in the url after the object
        ,[Parameter(Mandatory=$false)][PSCustomObject]$Query = [PSCustomObject]@{}  # Query parameters for the url
        ,[Parameter(Mandatory=$false)][Switch]$Paging = $false                      # Automatic paging through the result, only needed for a few calls
        #,[Parameter(Mandatory=$false)][Int]$Pagesize = 0                          # Pagesize, if not defined in settings. For reports the max is 5000.
        ,[Parameter(Mandatory=$false)][ValidateScript({
             If ($_ -is [PSCustomObject]) {
                 [PSCustomObject]$_
              # } elseif ($_ -is [System.Collections.Specialized.OrderedDictionary]) {
              #     [System.Collections.Specialized.OrderedDictionary]$_
              # }
        #      } ElseIf ($_ -is [System.Collections.ArrayList] -or $_ -is [Array]) {
        #         [System.Collections.ArrayList]$_
             }
         })]$Body = [PSCustomObject]@{}   # Body to upload, e.g. for POST and PUT requests, will automatically transformed into JSON
    )
    DynamicParam {
        # All parameters, except Uri and body (needed as an object)
        $p = Get-BaseParameters "Invoke-WebRequest"
        [void]$p.remove("Uri")
        [void]$p.remove("Body")
        [void]$p.remove("ContentType")
        $p
    }

    Begin {

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
        If ( $Script:settings.base.endswith("/") -eq $true ) {
            $base = $Script:settings.base
        } else {
            $base = "$( $Script:settings.base )/"
        }

        # Build custom Dynamics365 domain
        $base = "$( $base )api/$( $Service )/v$( $Script:settings.apiversion )"

        # Reduce input parameters to only allowed ones
        $updatedParameters = Skip-UnallowedBaseParameters -Base "Invoke-WebRequest" -Parameters $PSBoundParameters

        # Output parameters in debug mode
        If ( $Script:debugMode -eq $true ) {
            Write-Host "INPUT: $( Convertto-json -InputObject $PSBoundParameters -Depth 99 )"
        }

        # Prepare Authentication

        If ( $Script:settings.token.tokenUsage -eq "consume" ) {
            $rawToken = ( Get-Content -Path $Script:settings.token.tokenFilePath -Encoding UTF8 -Raw ).replace("`n","").replace("`r","")
            If ( $Script:settings.token.encryptTokenFile -eq $true ) {
                $token = Convert-SecureToPlaintext -String $rawToken
            } else {
                $token = $rawToken
            }
        } elseif ( $Script:settings.token.tokenUsage -eq "generate" ) {
            $token = Convert-SecureToPlaintext -String $Script:settings.login.accesstoken
        } else {
            throw "No token available!"
            exit 0 # TODO check, if this token is needed or should be another exit code
        }

        # Build up header
        $header = [Hashtable]@{
            "Authorization" = "Bearer $( $token )"
            "OData-MaxVersion" = "4.0"
            "OData-Version" = "4.0"
            "If-None-Match" = "null" # according to this: https://bengribaudo.com/blog/2021/04/09/5577/dataverse-web-api-tip-the-always-include-headers
            #"Prefer" = 'odata.include-annotations="*"'
            #"Accept" = "application/json"
        }

        # Empty the token variables
        $token = ""
        $rawToken = ""

        # Add auth header or just set it
        If ( $updatedParameters.ContainsKey("Headers") -eq $true ) {
            $header.Keys | ForEach-Object {
                $key = $_
                $updatedParameters.Headers.Add( $key, $header.$key )
            }
        } else {
            $updatedParameters.add("Headers",$header)
        }

        # Add additional headers from the settings, e.g. for api gateways or proxies
        $Script:settings.additionalHeaders.PSObject.Properties | ForEach-Object {
            $updatedParameters.Headers.add($_.Name, $_.Value)
        }

        # Set content type, if not present yet
        If ( $updatedParameters.ContainsKey("ContentType") -eq $false) {
            $updatedParameters.add("ContentType",$ContentType)
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

    }

    Process {

        #-----------------------------------------------
        # PREPARE QUERY
        #-----------------------------------------------

        $nvCollection = [System.Web.HttpUtility]::ParseQueryString([String]::Empty)
        $Query.PSObject.Properties | ForEach-Object {
            $nvCollection.Add( $_.Name, $_.Value )
        }


        #-----------------------------------------------
        # PREPARE URL
        #-----------------------------------------------

        $uriRequest = [System.UriBuilder]::new("$( $base )/$( $Path )")
        $uriRequest.Query = $nvCollection.ToString()
        $updatedParameters.Uri = $uriRequest.Uri.OriginalString


        #-----------------------------------------------
        # PREPARE BODY
        #-----------------------------------------------

        If ( $updatedParameters.ContainsKey("Body") -eq $true ) {
            $bodyJson = ConvertTo-Json -InputObject $Body -Depth 99
            $updatedParameters.Body = $bodyJson
        }


        #-----------------------------------------------
        # DO THE REQUEST
        #-----------------------------------------------

        $finished = $false
        $continueAfterTokenRefresh = $false
        $res = [System.Collections.ArrayList]@()
        Do {            

            # Execute the request
            try {

                # Output parameters in debug mode
                If ( $Script:debugMode -eq $true ) {
                    Write-Host "REST: $( Convertto-json -InputObject $updatedParameters -Depth 99 )"
                }

                Write-Verbose -Message "$( $updatedParameters.Method.ToString().ToUpper() ) $( $updatedParameters.Uri )" -verbose
                If ( $Script:logAPIrequests -eq $true ) {
                    Write-Log -Message "$( $updatedParameters.Method.ToString().ToUpper() ) $( $updatedParameters.Uri )" -severity verbose
                }
                $Script:pluginDebug = $updatedParameters

                #Write-Host ( convertto-json $updatedParameters )
                $wrInput = [Hashtable]@{
                    "Params" = $updatedParameters
                    "RetryHttpErrorList" = $Script:settings.errorhandling.RepeatOnHttpErrors
                    "MaxTriesSpecific" = $Script:settings.errorhandling.MaximumRetriesOnHttpErrorList
                    "MaxTriesGeneric" = $Script:settings.errorhandling.MaximumRetriesGeneric
                    "MillisecondsDelay" = $Script:settings.errorhandling.HttpErrorDelay
                }
                $wr = @( Invoke-WebRequestWithErrorHandling @wrInput )

                # Parse the result
                If ( $wr.Content -eq $null ) {
                    $wrContent = [Array]@()
                } else {
                    # TODO check with utf8 in returned header
                    If ( $wr.headers.'Content-Type' -like "application/json*" ) {
                        $wrContent = convertfrom-json -InputObject $wr.content #-Depth 99
                    } else {
                        $wrContent = $wr.content
                    }
                }

                #$wr = Invoke-WebRequest @updatedParameters -UseBasicParsing

            } catch {

                $e = $_

                Write-Log -Message $e.Exception.Message -Severity ERROR

                # parse the response code and body
                $errResponse = $e.Exception.Response
                $errBody = Import-ErrorForResponseBody -Err $e

                # Do this only once
                if ( $errResponse.StatusCode.value__ -eq 401 -and $continueAfterTokenRefresh -eq $false) {

                    Write-Log -Severity WARNING -Message "401 Unauthorized"
                    try {
                        $newToken = Save-NewToken
                        Write-Log -Severity WARNING -Message "Successful token refresh"
                        $wrInput.Params.Headers.Authorization = "Bearer $( $newToken )"
                        $continueAfterTokenRefresh = $true
                    } catch {
                        Write-Log -Severity ERROR -Message "Token refresh not successful"
                    }

                    If ( $continueAfterTokenRefresh -eq $true ) {
                        Continue
                    }

                }

                # $responseStream = $_.Exception.Response.GetResponseStream()
                # $responseReader = [System.IO.StreamReader]::new($responseStream)
                # $responseBody = $responseReader.ReadToEnd()
                # Write-Log -Message $responseBody -Severity ERROR

                throw $_.Exception

            }

            # Choose next page link add results to the collection
            If ( $Paging -eq $true ) {

                # If the result has a link to the next page, just follow it
                If ( $wrContent.psobject.properties.name -contains "@odata.nextLink" ) {

                    Write-Verbose "Next url: $( $wrContent."@odata.nextLink" )" -verbose
                    $updatedParameters.Uri = $wrContent."@odata.nextLink"

                } else {

                    # If this is less than the page size -> done!
                    $finished = $true

                }

                # Add result to return collection
                [void]$res.AddRange($wrContent.value)

            } else {

                # If this is only one request without paging -> done!
                $finished = $true

            }

            # If ( $Verbose -eq $true ) {
            #     Write-log $wr.Headers."Sforce-Limit-Info" -severity verbose #api-usage=2/15000
            # }
            $Script:pluginDebug = $wr.headers

        } Until ( $finished -eq $true )


        #-----------------------------------------------
        # SAVE CURRENT RATE
        #-----------------------------------------------

        # There is also: x-ms-dop-hint and x-ms-ratelimit-time-remaining-xrm-requests
        # Explained here: https://github.com/MicrosoftDocs/powerapps-docs/blob/main/powerapps-docs/developer/data-platform/api-limits.md

        If ( $Script:variableCache.Keys -contains "api_rate_remaining" ) {
            #$Script:variableCache.api_rate_limit = $wr.Headers."X-HubSpot-RateLimit-Daily"
            $Script:variableCache.api_rate_remaining = $wr.Headers."x-ms-ratelimit-burst-remaining-xrm-requests"
        } else {
            #$Script:variableCache.Add("api_rate_limit",$wr.Headers."X-HubSpot-RateLimit-Daily")
            $Script:variableCache.Add("api_rate_remaining", $wr.Headers."x-ms-ratelimit-burst-remaining-xrm-requests")
        }


        #-----------------------------------------------
        # RETURN
        #-----------------------------------------------

        # Always return the deltalink, if it is present
        If ( $Paging -eq $true ) {
            If ( $wrContent.psobject.properties.name -contains "@odata.deltaLink" ) {
                [PSCustomObject]@{
                    "@odata.deltaLink" = $wrContent."@odata.deltaLink"
                    "value" = $res
                }
            } else {
                [PSCustomObject]@{
                    "value" = $res
                }
            }
        } else {
            $wrContent
        }


    }

    End {

        <#
        If ( $Paging -eq $true ) {
            $res
        } else {
            $wr
        }
        #>

    }

 }

