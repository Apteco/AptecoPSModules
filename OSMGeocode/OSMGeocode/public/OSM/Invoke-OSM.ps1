<#
    .SYNOPSIS
        Wrapper for OpenStreetMaps to input address data and get back geocoded and fixed addresses and maybe some
        more information.

    .DESCRIPTION
        Apteco PS Modules - PowerShell OSM Geocoding

        Just define an address like

        $addr = [PSCustomObject]@{
            "street" = "Schaumainkai 87"
            "city" = "Frankfurt"
            "postalcode" = 60589
            "countrycodes" = "de"
        }

        and geocode it

        $addr | Invoke-OSM -Email "user@example.com" -AddressDetails -ExtraTags -ResultsLanguage "de"

        If you put in multiple objects, the geocoding will do 1 request per second like it should do to
        cover OSM terms and conditions.

    .PARAMETER Address
        The address to geocode (should include street, city, postalcode, countrycodes)

    .PARAMETER Email
        The email is a kind of useragent for identification for the current process

    .PARAMETER ResultsLanguage
        Language for the results

    .PARAMETER ExcludeKnownHashes
        This parameter leads to exclude hashes that are already in the cache
        Be aware, that this parameter kills known records that come in
        so if your input is a combination of id and address, this object won't
        be forwarded for known addresses

    .PARAMETER CombineIdAndHash
        Combine ID and address hash value so you definitely have every
        ID of your input data, even if hashed addresses are the same.
        This is useful when you later join OSM geocodes via an ID rather
        than a hashed address. Only works, if the inputobject has a
        property with the name ID or Id or id.

    .PARAMETER AddressDetails
        Load more details from OSM

    .PARAMETER ExtraTags
        Load extra tags from OSM

    .PARAMETER NameDetails
        Load name details from OSM like opening hours etc.

    .PARAMETER ReturnOnlyFirstPosition
        If there are multiple addresses in the result, return only the entry at position 1

    .PARAMETER AddMetaData
        Wraps the result with more metadata

    .PARAMETER AddToHashCache
        Directly puts the new hash value into the cache so it can be used to exclude some records

    .PARAMETER ReturnHashTable
        Instead of PSCustomObject, only works together with -AddMetaData

    .PARAMETER ReturnJson
        Formats the returned addresses as json rather than PSCustomObjects, only works together with -AddMetaData

    .PARAMETER Verbose
        Shows you more information about the current status

    .EXAMPLE
        $addr = [PSCustomObject]@{"street" = "Schaumainkai 87";"city" = "Frankfurt";"postalcode" = 60589;"countrycodes" = "de"}
        $addr | Invoke-OSM -Email "user@example.com" -AddressDetails -ExtraTags -ResultsLanguage "de"

    .INPUTS
        Objects

    .OUTPUTS
        Objects

    .NOTES
        Author:  florian.von.bracht@apteco.de

#>
function Invoke-OSM {
    [CmdletBinding()]

    param (

        # Input parameter
         [Parameter(Mandatory = $true, ValueFromPipeline = $true, Position=0)][PSCustomObject]$Address  # the address to geocode (should include street, city, postalcode, countrycodes)
        ,[Parameter(Mandatory = $true)][String]$Email                                                   # the email is a kind of useragent for identification for the current process
        ,[Parameter(Mandatory = $false)][String]$ResultsLanguage = "de"                                 # language for the results
        ,[Parameter(Mandatory = $false)][Switch]$ExcludeKnownHashes = $false                            # this parameter leads to exclude hashes that are already in the cache
                                                                                                        # Be aware, that this parameter kills known records that come in
                                                                                                        # so if your input is a combination of id and address, this object won't
                                                                                                        # be forwarded for known addresses
        ,[Parameter(Mandatory = $false)][Switch]$CombineIdAndHash = $false                              # Combine ID and address hash value so you definitely have every
                                                                                                        # ID of your input data, even if hashed addresses are the same
                                                                                                        # This is useful when you later join OSM geocodes via an ID rather
                                                                                                        # than a hashed address

        # More OSM data
        ,[Parameter(Mandatory = $false)][Switch]$AddressDetails = $false                    # load more details from osm
        ,[Parameter(Mandatory = $false)][Switch]$ExtraTags = $false                         # load extra tags from osm
        ,[Parameter(Mandatory = $false)][Switch]$NameDetails = $false                       # load name details from osm like opening hours etc.

        # Options for return
        ,[Parameter(Mandatory = $false)][Switch]$ReturnOnlyFirstPosition = $false           # if there are multiple addresses in the result, return only the entry at position 1
        ,[Parameter(Mandatory = $false)][Switch]$AddMetaData = $false                       # wraps the result with more metadata
        ,[Parameter(Mandatory = $false)][Switch]$AddToHashCache = $false                    # Directly puts the new hash value into the cache so it can be used to exclude some records
        ,[Parameter(Mandatory = $false)][Switch]$ReturnHashTable = $false                   # Instead of PSCustomObject, only works together with -AddMetaData
        ,[Parameter(Mandatory = $false)][Switch]$ReturnJson = $false                        # Formats the returned addresses as json rather than PSCustomObjects, only works together with -AddMetaData

    )

    begin {

        #-----------------------------------------------
        # START
        #-----------------------------------------------

        #Add-Type -AssemblyName System.Web # outcomment later
        #Import-Module ConvertStrings

        $i = 0
        $start = [datetime]::Now # fill this variable

        $maxMillisecondsPerRequest = 1000 #$settings.millisecondsPerRequest
        #Write-Log "Will create 1 request per $( $maxMillisecondsPerRequest ) milliseconds" -Severity VERBOSE

        $base = "https://nominatim.openstreetmap.org/" # TODO put this into settings

        If ( $AddressDetails -eq $true ) {
            $loadAddressDetails = 1
        } else {
            $loadAddressDetails = 0
        }

        If ( $ExtraTags -eq $true ) {
            $loadExtraTags = 1
        } else {
            $loadExtraTags = 0
        }

        If ( $NameDetails -eq $true ) {
            $loadNameDetails = 1
        } else {
            $loadNameDetails = 0
        }


        #-----------------------------------------------
        # VALIDATE EMAIL
        #-----------------------------------------------

        # This throws an exception, if it is not able to parse it
        $emailAddress = [mailaddress]$Email


        #-----------------------------------------------
        # ADDITIONAL HEADERS
        #-----------------------------------------------

        # Add additional headers from the settings, e.g. for api gateways or proxies
        # $Script:settings.additionalHeaders.PSObject.Properties | ForEach-Object {
        #     $updatedParameters.add($_.Name, $_.Value)
        # }

        #-----------------------------------------------
        # CONTENT TYPE
        #-----------------------------------------------

        # Set content type, if not present yet
        # If ( $updatedParameters.ContainsKey("ContentType") -eq $false) {
        #     $updatedParameters.add("ContentType",$Script:settings.contentType)
        # }


    }

    process {

        #-----------------------------------------------
        # BUILD THE HASH OF ADDRESS
        #-----------------------------------------------

        # Build hash value
        $hashValue = Get-AddressHash -Address $Address
        If ( $CombineIdAndHash -eq $true ) { # TODO check case sensitivity
            $hashedInput = "$( $Address.id )#$( $hashValue )"
        } else {
            $hashedInput = $hashValue
        }


        #-----------------------------------------------
        # CHECK IF THIS REQUEST SHOULD BE DONE
        #-----------------------------------------------

        If ( $ExcludeKnownHashes -eq $false -or ( $ExcludeKnownHashes -eq $true -and $Script:knownHashes -notcontains $hashedInput )) {


            #-----------------------------------------------
            # PREPARE QUERY
            #-----------------------------------------------

            $nvCollection = [System.Web.HttpUtility]::ParseQueryString([String]::Empty) #, [System.Text.Encoding]::UTF8)
            $Address.PSObject.Properties | where-object { $_.Name -in $Script:allowedQueryParameters } | ForEach-Object {
                $nvCollection.Add( $_.Name, $_.Value )
            }

            # Create address parameter string like streetSchaumainkai%2087&city=Frankfurt&postalcode=60589&countrycodes=de
            # $addrParams = [System.Collections.ArrayList]@()
            # $paramMap.Keys | ForEach {
            #     $key = $_
            #     $value = $addr[$paramMap[$key]]
            #     [void]$addrParams.add("$( $key )=$( [uri]::EscapeDataString($value) )")
            # }


            #-----------------------------------------------
            # ADD MORE TO QUERY
            #-----------------------------------------------

            # refers to: https://nominatim.org/release-docs/latest/api/Search/
            $nvCollection.Add( "format", "jsonv2" )
            $nvCollection.Add( "layer", "address" )
            #$nvCollection.Add( "featureType", "city" )
            $nvCollection.Add( "dedupe", "1" )
            $nvCollection.Add( "debug", "0" )

            $nvCollection.Add( "accept-language", $ResultsLanguage )
            $nvCollection.Add( "addressdetails", $loadAddressDetails )
            $nvCollection.Add( "extratags", $loadExtraTags )
            $nvCollection.Add( "namedetails", $loadNameDetails )
            $nvCollection.Add( "email", $emailAddress.Address )


            #-----------------------------------------------
            # PREPARE URL
            #-----------------------------------------------

            $uriRequest = [System.UriBuilder]::new("$( $base )search")
            $uriRequest.Query = [System.Web.HttpUtility]::UrlDecode( $nvCollection.ToString() )
            # Using an alternative way becaue umlauts can create massive problems in queries
            # $queryArray = [Array]@()
            # $nvCollection.GetEnumerator() | ForEach-Object {
            #     $key = $_
            #     $queryArray += "$( $key )=$( [uri]::EscapeDataString( $nvCollection[$key] ) )"
            # }
            # $uriRequest.Query = $queryArray -join "&"


            #-----------------------------------------------
            # LOOP THROUGH DATA
            #-----------------------------------------------

            # Parameters for call
            $restParams = @{
                "Uri" = $uriRequest.Uri.OriginalString
                "Method" = "GET"
                "UserAgent" = $emailAddress.Address #$script:settings.useragent
                "ContentType" = "application/json; charset=utf-8"
                #Verbose = $false
            }

            # Wait until 1 second is full, then proceed
            # This is only relevant for all calls after the first one
            If ( $i -gt 0 ) {
                $ts = New-TimeSpan -Start $start -End ( [datetime]::Now )
                if ( $ts.TotalMilliseconds -lt $maxMillisecondsPerRequest ) {
                    $waitLonger = [math]::ceiling( $maxMillisecondsPerRequest - $ts.TotalMilliseconds )
                    Write-Verbose "Waiting $( $waitLonger ) ms"
                    Start-Sleep -Milliseconds $waitLonger
                }
            }

            Write-Verbose $uriRequest.Uri.OriginalString

            # Request to OSM
            $start = [datetime]::Now
            #$t = Measure-Command {
                # TODO [ ] possibly implement proxy, if needed
                # TODO add try catch here
                $res = Invoke-RestMethod @restParams #-Uri $uriRequest.Uri.OriginalString
            #}
            $i += 1

            #$pl = ConvertTo-Json -InputObject $res -Depth 99 -Compress


            #-----------------------------------------------
            # DECIDE TO RETURN WHOLE RESULT OR FIRST ENTRY
            #-----------------------------------------------

            If ( $ReturnOnlyFirstPosition -eq $true ) {
                $ret = $res[0]
            } else {
                $ret = $res
            }

            #-----------------------------------------------
            # CACHE HASHVALUE
            #-----------------------------------------------

            If ( $AddToHashCache -eq $true ) {
                Add-ToHashCache -InputHash $hashedInput
            }


            #-----------------------------------------------
            # RETURN RAW OR ADD SOME METADATA
            #-----------------------------------------------

            If ( $AddMetaData -eq $true ) {

                If ( $ReturnJson -eq $true ) {
                    $returnAddress = ConvertTo-Json -InputObject $Address -Depth 99
                    $returnResults = ConvertTo-Json -InputObject $ret -Depth 99
                } else {
                    $returnAddress = $Address
                    $returnResults = $ret
                }


                If ( $ReturnHashTable -eq $true ) {
                    [Hashtable]@{
                        "inputHash" = $hashedInput
                        "inputObject" = $returnAddress
                        "results" = $returnResults
                        "total" = $res.count
                    }
                } else {
                    [PSCustomObject]@{
                        "inputHash" = $hashedInput
                        "inputObject" = $returnAddress
                        "results" = $returnResults
                        "total" = $res.count
                    }
                }



            } else {

                $ret

            }

        }

    }

    end {
        Write-Verbose "Geocoded $( $i ) addresses"
    }

}
