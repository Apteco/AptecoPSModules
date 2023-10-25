
function Invoke-Hubspot {

    [CmdletBinding()]
    param (
         [Parameter(Mandatory=$true)][String]$Object                                # The cleverreach object like groups or mailings (first part after the main url)
        ,[Parameter(Mandatory=$false)][String]$Path = ""                            # The path in the url after the object
        ,[Parameter(Mandatory=$false)][PSCustomObject]$Query = [PSCustomObject]@{}  # Query parameters for the url
        ,[Parameter(Mandatory=$false)][Switch]$Paging = $false                      # Automatic paging through the result, only needed for a few calls
        ,[Parameter(Mandatory=$false)][Int]$Pagesize = 0                          # Pagesize, if not defined in settings. For reports the max is 100.
        ,[Parameter(Mandatory=$false)][ValidateScript({
            If ($_ -is [PSCustomObject]) {
                 [PSCustomObject]$_
              # } elseif ($_ -is [System.Collections.Specialized.OrderedDictionary]) {
              #     [System.Collections.Specialized.OrderedDictionary]$_
              # }
            } ElseIf ($_ -is [System.Collections.ArrayList] -or $_ -is [Array]) {
                [System.Collections.ArrayList]$_
            }
         })]$Body = [PSCustomObject]@{}   # Body to upload, e.g. for POST and PUT requests, will automatically transformed into JSON
    )
    DynamicParam {
        # All parameters, except Uri and body (needed as an object)
        $p = Get-BaseParameters "Invoke-WebRequest"
        [void]$p.remove("Uri")
        [void]$p.remove("Body")
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


        #-----------------------------------------------
        # CREATE URL
        #-----------------------------------------------

        # Check the slash at the end
        If ( $Script:settings.base.endswith("/") -eq $true ) {
            $base = $Script:settings.base
        } else {
            $base = "$( $Script:settings.base )/"
        }

        # Build custom hubspot domain
        $base = "$( $base )$( $object )/v$( $script:settings.apiversion )/"


        #-----------------------------------------------
        # CHECK INPUT PARAMETERS
        #-----------------------------------------------

        # Reduce input parameters to only allowed ones
        $updatedParameters = Skip-UnallowedBaseParameters -Base "Invoke-WebRequest" -Parameters $PSBoundParameters

        # Output parameters in debug mode
        If ( $Script:debugMode -eq $true ) {
            Write-Host "INPUT: $( Convertto-json -InputObject $PSBoundParameters -Depth 99 )"
        }


        #-----------------------------------------------
        # AUTHENTICATION
        #-----------------------------------------------

        # Prepare Authentication
        If ( $Script:settings.token.tokenUsage -eq "consume" ) {
            $rawToken = ( Get-Content -Path $Script:settings.token.tokenFilePath -Encoding UTF8 -Raw ).replace("`n","").replace("`r","")
            If ( $Script:settings.token.encryptTokenFile -eq $true ) {
                $token = Convert-SecureToPlaintext -String $rawToken
            } else {
                $token = $rawToken
            }
        } else {
            throw "No token available!"
            exit 0 # TODO check, if this token is needed or should be another exit code
        }


        #-----------------------------------------------
        # HEADER
        #-----------------------------------------------

        $header = [Hashtable]@{
            "Authorization" = "Bearer $( $token )"
            #"Accept" = "application/json"
        }

        # Empty the token variables
        $token = ""
        $rawToken = ""

        # Add auth header or just set it
        If ( $updatedParameters.ContainsKey("Header") -eq $true ) {
            $header.Keys | ForEach-Object {
                $key = $_
                $updatedParameters.Header.Add( $key, $header.$key )
            }
        } else {
            $updatedParameters.add("Header",$header)
        }


        #-----------------------------------------------
        # ADDITIONAL HEADERS
        #-----------------------------------------------

        # Add additional headers from the settings, e.g. for api gateways or proxies
        $Script:settings.additionalHeaders.PSObject.Properties | ForEach-Object {
            $updatedParameters.add($_.Name, $_.Value)
        }


        #-----------------------------------------------
        # CONTENT TYPE
        #-----------------------------------------------

        # Set content type, if not present yet
        If ( $updatedParameters.ContainsKey("ContentType") -eq $false) {
            $updatedParameters.add("ContentType",$Script:settings.contentType)
        }


        #-----------------------------------------------
        # PATH
        #-----------------------------------------------

        # normalize the path, remove leading and trailing slashes
        If ( $Path -ne "") {
            If ( $Path.StartsWith("/") -eq $true ) {
                $Path = $Path.Substring(1)
            }
            If ( $Path.EndsWith("/") -eq $true ) {
                $Path = $Path -replace ".$"
            }
        }


        #-----------------------------------------------
        # PAGING
        #-----------------------------------------------

        # set the pagesize
        <#
        If ( $Pagesize -gt 0 ) {
            $currentPagesize = $Pagesize
        } else {
            $currentPagesize = $Script:settings.pageSize
        }
        #>

        # set paging parameters
        
        If ( $Paging -eq $true ) {

            <#
            Switch ( $updatedParameters.Method ) {

                "GET"{
                    #Write-Host "get"
                    $Query | Add-Member -MemberType NoteProperty -Name "pagesize" -Value $currentPagesize  #$Script:settings.pageSize
                    $Query | Add-Member -MemberType NoteProperty -Name "page" -Value 0
                }

                "POST" {
                    If ( $Body -is [PSCustomObject] ) {
                        $Body | Add-Member -MemberType NoteProperty -Name "pagesize" -Value $currentPagesize # $Script:settings.pageSize
                        $Body | Add-Member -MemberType NoteProperty -Name "page" -Value 0
                    # } elseif ( $Body -is [System.Collections.Specialized.OrderedDictionary] ) {
                    #     $Body.add("pagesize", $Script:settings.pageSize)
                    #     $Body.add("page", 0)
                    }
                }

            }
            #>

            # Parameter for paging
            If ( $updatedParameters.Method -eq "POST") {
                $Body | Add-Member -MemberType NoteProperty -Name "after" -Value 0
            }

            # Add a collection instead of a single object for the return
            $res = [System.Collections.ArrayList]@()

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

        $uriRequest = [System.UriBuilder]::new("$( $base )$( $Path )")
        $uriRequest.Query = $nvCollection.ToString()
        $updatedParameters.Uri = $uriRequest.Uri.OriginalString


        $finished = $false
        $continueAfterTokenRefresh = $false
        Do {
            
            #-----------------------------------------------
            # PREPARE BODY
            #-----------------------------------------------

            If ( $updatedParameters.ContainsKey("Body") -eq $true ) {
                $bodyJson = ConvertTo-Json -InputObject $Body -Depth 99 -compress
                $updatedParameters.Body = $bodyJson
                write-verbose $bodyJson -verbose
            }

            
            #-----------------------------------------------
            # EXECUTE THE REQUEST
            #-----------------------------------------------

            try {

                # Output parameters in debug mode
                If ( $Script:debugMode -eq $true ) {
                    Write-Host "REST: $( Convertto-json -InputObject $updatedParameters -Depth 99 )"
                }

                #If ( $Script:logAPIrequests -eq $true ) {
                    Write-Log -Message "$( $updatedParameters.Method.ToString().ToUpper() ) $( $updatedParameters.Uri )" -severity verbose
                #}

                #Write-Verbose ( $updatedParameters | convertto-json -depth 99 ) -verbose

                #Write-Host ( convertto-json $updatedParameters )
                $wrInput = [Hashtable]@{
                    "Params" = $updatedParameters
                    "RetryHttpErrorList" = $Script:settings.errorhandling.RepeatOnHttpErrors
                    "MaxTriesSpecific" = $Script:settings.errorhandling.MaximumRetriesOnHttpErrorList
                    "MaxTriesGeneric" = $Script:settings.errorhandling.MaximumRetriesGeneric
                    "MillisecondsDelay" = $Script:settings.errorhandling.HttpErrorDelay
                }
                $wr = @( Invoke-WebRequestWithErrorHandling @wrInput )
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
                        $wrInput.Params.Header.Authorization = "Bearer $( $newToken )"
                        $continueAfterTokenRefresh = $true
                    } catch {
                        Write-Log -Severity ERROR -Message "Token refresh not successful"
                    }

                    If ( $continueAfterTokenRefresh -eq $true ) {
                        Continue
                    }

                }

                # Wait if we had too many requests
                # if ( $errResponse.StatusCode.value__ -eq 429 ) {

                #     Write-Log -Severity WARNING -Message "429 Too Many Requests"
                #     Continue

                # }


                # $responseStream = $_.Exception.Response.GetResponseStream()
                # $responseReader = [System.IO.StreamReader]::new($responseStream)
                # $responseBody = $responseReader.ReadToEnd()
                # Write-Log -Message $responseBody -Severity ERROR

                throw $_.Exception

            }

            # Parse the content directly
            If ( $wr.Content -eq $null ) {
                $content = [Array]@()
            } else {
                If ( $wr.headers.'Content-Type' -like "application/json*" ) {
                    $content = convertfrom-json -InputObject $wr.content #-Depth 99
                } else {
                    $content = $wr.content
                }
            }
            
            # Handle paging
            If ( $Paging -eq $true ) {

                # If we have a paging link, just place it
                If ( $content.paging ) {

                    Switch ( $updatedParameters.Method ) {

                        "GET"{
                            #Write-verbose ( $content.paging | convertto-json -depth 99) -verbose
                            $updatedParameters.Uri = $content.paging.next.link
                            #Write-Verbose $content.paging.next.link -verbose
                        }
    
                        "POST" {
                            $Body.after = $content.paging.next.after
                        }

                    }
                    
                } else {

                    # Otherwise -> done!
                    $finished = $true

                }

                # Add result to return collection
                [void]$res.Add($content)

            } else {
                                
                # If this is only one request without paging -> done!
                $finished = $true

            }


        } Until ( $finished -eq $true )


        #-----------------------------------------------
        # SAVE CURRENT RATE AFTER LAST CALL
        #-----------------------------------------------

        If ( $Script:variableCache.Keys -contains "api_rate_limit" ) {
            $Script:variableCache.api_rate_limit = $wr.Headers."X-HubSpot-RateLimit-Daily"
            $Script:variableCache.api_rate_remaining = $wr.Headers."X-HubSpot-RateLimit-Daily-Remaining"
        } else {
            $Script:variableCache.Add("api_rate_limit",$wr.Headers."X-HubSpot-RateLimit-Daily")
            $Script:variableCache.Add("api_rate_remaining", $wr.Headers."X-HubSpot-RateLimit-Daily-Remaining")
        }


        #-----------------------------------------------
        # RETURN
        #-----------------------------------------------

        # TODO this could maybe be more performant returning the data directly instead of writing it into a variable
        If ( $Paging -eq $true ) {
            $ret = $res
        } else {
            # TODO check with utf8 in returned header
            $ret = $content
        }

        #return
        $ret


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

