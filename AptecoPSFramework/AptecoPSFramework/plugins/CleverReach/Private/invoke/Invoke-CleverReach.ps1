


# These functions inherit the parameters of the original functions/cmdlets
# And as an example adds an additional parameter
# There are two functions for the different PowerShell Editions

#Write-Log -message "Found $( $mailings.draft.count  ) mailings"

# This extended function allows adding normal parameters for invoke-restmethod like proxying

<#

EXAMPLES

$param = [PSCustomObject]@{
    state = "draft"
    limit = 999
}
$list = Invoke-CR -Object "groups" -Query $param -Method "GET" -Verbose

$choice = $list | Out-GridView -PassThru

# e.g. 1158799
$listDetails = Invoke-CR -Object "groups" -Method "GET" -Verbose -Path "$( $choice.id )/stats"
$listDetails 

$param = [PSCustomObject]@{
    type = "all"
    detail = 4
}
$receivers = Invoke-CR -Object "groups" -Query $param -Method "GET" -Verbose -Path "$( $choice.id )/receivers" -Paging #-Body ([PSCustomObject]@{"test"="Balloon"}) 


$filterBody = [PSCustomObject]@{
    "groups" = [Array]@(,$choice.id)
    "operator" = "AND"
    "rules" = [Array]@(,
        [PSCustomObject]@{
            "field" = "tags"
            "logic" = "contains"
            "condition" = "CR.TopRating"
        }
        [PSCustomObject]@{
            "field" = "activated"
            "logic" = "bg"
            "condition" = "1"
        }
    )
    "orderby" = "activated desc"
    "detail" = 4
}

# Runtime filter with paging
$filter = Invoke-CR -Object "receivers" -Path "filter.json" -Method POST -Verbose -Paging -Body $filterBody

#>


function Invoke-CR {

    [CmdletBinding()]
    param (
         [Parameter(Mandatory=$true)][String]$Object                                # The cleverreach object like groups or mailings (first part after the main url)
        ,[Parameter(Mandatory=$false)][String]$Path = ""                            # The path in the url after the object
        ,[Parameter(Mandatory=$false)][PSCustomObject]$Query = [PSCustomObject]@{}  # Query parameters for the url
        ,[Parameter(Mandatory=$false)][Switch]$Paging = $false                      # Automatic paging through the result, only needed for a few calls
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
        $p = Get-BaseParameters "Invoke-RestMethod"
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

        # check url, if it ends with a slash
        If ( $Script:settings.base.endswith("/") -eq $true ) {
            $base = $Script:settings.base
        } else {
            $base = "$( $Script:settings.base )/"
        }

        # Reduce input parameters to only allowed ones
        $updatedParameters = Skip-UnallowedBaseParameters -Base "Invoke-RestMethod" -Parameters $PSBoundParameters

        # Output parameters in debug mode
        If ( $Script:debugMode -eq $true ) {
            Write-Host "INPUT: $( Convertto-json -InputObject $PSBoundParameters -Depth 99 )"
        }
        
        # Prepare Authentication
        If ( $Script:settings.token.tokenUsage -eq "consume" ) {
            $rawToken = Get-Content -Path $Script:settings.token.tokenFilePath -Encoding UTF8 -Raw
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
        #$auth = "Bearer $( $token )" #"Bearer $( $settings.token )" #$( Get-SecureToPlaintext -String $Script:settings.login.accesstoken )"
        $header = [Hashtable]@{
            "Authorization" = "Bearer $( $token )"
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

        # Add additional headers from the settings, e.g. for api gateways or proxies
        $Script:settings.additionalHeaders.PSObject.Properties | ForEach-Object {
            $updatedParameters.add($_.Name, $_.Value)
        }

        # Set content type, if not present yet
        If ( $updatedParameters.ContainsKey("ContentType") -eq $false) {
            $updatedParameters.add("ContentType",$Script:settings.contentType) 
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

        If ( $Paging -eq $true ) {

            Switch ( $updatedParameters.Method ) {
            
                "GET"{
                    #Write-Host "get"
                    $Query | Add-Member -MemberType NoteProperty -Name "pagesize" -Value $Script:settings.pageSize
                    $Query | Add-Member -MemberType NoteProperty -Name "page" -Value 0
                }

                "POST" {
                    If ( $Body -is [PSCustomObject] ) {
                        $Body | Add-Member -MemberType NoteProperty -Name "pagesize" -Value $Script:settings.pageSize
                        $Body | Add-Member -MemberType NoteProperty -Name "page" -Value 0
                    # } elseif ( $Body -is [System.Collections.Specialized.OrderedDictionary] ) {
                    #     $Body.add("pagesize", $Script:settings.pageSize)
                    #     $Body.add("page", 0)
                    }
                }

            }

            # Add a collection instead of a single object for the return
            $res = [System.Collections.ArrayList]@()

        }

    }

    Process {

        $finished = $false

        Do {

            # Prepare query
            $nvCollection = [System.Web.HttpUtility]::ParseQueryString([String]::Empty)
            $Query.PSObject.Properties | ForEach-Object {
                $nvCollection.Add( $_.Name, $_.Value )
            }

            # Prepare URL
            $uriRequest = [System.UriBuilder]::new("$( $base )$( $object ).json/$( $Path )")
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
                If ( $Script:debugMode -eq $true ) {
                    Write-Host "REST: $( Convertto-json -InputObject $updatedParameters -Depth 99 )"
                }

                If ( $Script:logAPIrequests -eq $true ) {
                    Write-Log -Message "$( $updatedParameters.Method.ToString().ToUpper() ) $( $updatedParameters.Uri )"
                }
                $wr = Invoke-RestMethod @updatedParameters
                
            }
            catch {
                Write-Log -Message $_.Exception.Message -Severity ERROR
                throw $_.Exception
            }
            
            # Increase page and add results to the collection
            If ( $Paging -eq $true ) {

                # If the result equals the pagesize, try it one more time with the next page
                If ( $wr.count -eq $Script:settings.pageSize ) {

                    Switch ( $updatedParameters.Method ) {
                
                        "GET"{
                            $Query.page += 1
                        }
        
                        "POST" {
                            $Body.page += 1
                        }
                    }

                } else {

                    # If this is less than the page size -> done!
                    $finished = $true

                }

                # Add result to return collection
                [void]$res.AddRange($wr)

            } else {

                # If this is only one request without paging -> done!
                $finished = $true

            }

        } Until ( $finished -eq $true )
 
    }

    End {

        If ( $Paging -eq $true ) {
            $res
        } else {
            $wr
        }

    }
 
 } 


 <#
$script:settings = [PSCustomObject]@{
    "base" = "https://rest.cleverreach.com/v3/"
    "contentType" = "application/json; charset=utf-8"
    "pageSize" = 2
    "token"= [PSCustomObject]@{
                  
                  "tokenUsage" =  "consume"
                  "encryptTokenFile"=  $false
                  "tokenFilePath"=  "C:\temp\cr.token"
              }


    "additionalHeaders" = [PSCustomObject]@{
        #"X-API" = "abcdef"
    }                                                       # static headers that should be send to the URL, sometimes needed for API gateways
    "additionalParameters" = [PSCustomObject]@{
        #"Proxy" = "http://proxy.example.com"
        #"SkipHeaderValidation" = $true
    }                                                       # additional parameter for the Invoke-RestMethod call like Proxy or ProxyCredential, see https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.utility/invoke-restmethod


}

$body = [PSCustomObject]@{
    "name" = $newAttributeName
    "type" = "text"                     # text|number|gender|date
    "description" = $newAttributeName   # optional 
    #"preview_value" = "real name"       # optional
    #"default_value" = "Bruce Wayne"     # optional
}

Invoke-CR -Object "groups" -Method "POST" -Path "/$( $groupId )/attributes" -Body $body -Verbose








$param = [PSCustomObject]@{
    state = "draft"
    limit = 999
}
$list = Invoke-CR -Object "groups" -Query $param -Method "GET" -Verbose

$choice = $list | Out-GridView -PassThru

# e.g. 1158799
$listDetails = Invoke-CR -Object "groups" -Method "GET" -Verbose -Path "$( $choice.id )/stats"
$listDetails 

$filterBody = [PSCustomObject]@{
    "groups" = [Array]@(,$choice.id)
    "operator" = "AND"
    "rules" = [Array]@(,
        [PSCustomObject]@{
            "field" = "tags"
            "logic" = "contains"
            "condition" = "CR.TopRating"
        }
        [PSCustomObject]@{
            "field" = "activated"
            "logic" = "bg"
            "condition" = "1"
        }
    )
    "orderby" = "activated desc"
    "detail" = 4
}

# Runtime filter with paging
# $a = [System.Collections.ArrayList]::new()
# $a.Add("abc")
# $a.Add("def")
$filter = Invoke-CR -Object "receivers" -Path "filter.json" -Method POST -Verbose -Paging -Body $filterBody





exit 0





$param = [PSCustomObject]@{
    type = "all"
    detail = 4
}
$receivers = Invoke-CR -Object "groups" -Query $param -Method "GET" -Verbose -Path "$( $choice.id )/receivers" -Paging #-Body ([PSCustomObject]@{"test"="Balloon"}) 



#>