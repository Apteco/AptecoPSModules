
function Invoke-OSM {
    [CmdletBinding()]
    param (
         [Parameter(Mandatory = $true, ValueFromPipeline = $true)][PSCustomObject]$Address  # the address to geocode (should include street, city, postalcode, countrycodes)
        ,[Parameter(Mandatory = $true)][String]$UserAgent                                   # the useragent is a kind of identification for the current process
        ,[Parameter(Mandatory = $false)][String]$ResultsLanguage = "de"                     # language for the results
        ,[Parameter(Mandatory = $false)][Switch]$AddressDetails = $false                    # load more details from osm
        ,[Parameter(Mandatory = $false)][Switch]$ExtraTags = $false                         # load extra tags from osm
        ,[Parameter(Mandatory = $false)][Switch]$ReturnOnlyFirstPosition = $false           # if there are multiple addresses in the result, return only the entry at position 1
        ,[Parameter(Mandatory = $false)][Switch]$AddMetaData = $false                       # wraps the result with more metadata
    )
    
    begin {

        #Add-Type -AssemblyName System.Web # outcomment later
        #Import-Module ConvertStrings

        $i = 0
        $start = [datetime]::Now # fill this variable

        $maxMillisecondsPerRequest = 1000 #$settings.millisecondsPerRequest
        #Write-Log "Will create 1 request per $( $maxMillisecondsPerRequest ) milliseconds" -Severity VERBOSE

        $base = "https://nominatim.openstreetmap.org/"

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
        # PREPARE QUERY
        #-----------------------------------------------

        $global:nvCollection = [System.Web.HttpUtility]::ParseQueryString([String]::Empty) #, [System.Text.Encoding]::UTF8)
        $Address.PSObject.Properties | ForEach-Object {
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

        $nvCollection.Add( "format", "jsonv2" )
        $nvCollection.Add( "accept-language", $ResultsLanguage )
        $nvCollection.Add( "addressdetails", $loadAddressDetails )
        $nvCollection.Add( "extratags", $loadExtraTags )


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
            #"Uri" = $uriRequest.Uri.OriginalString
            "Method" = "Get"
            "UserAgent" = $UserAgent #$script:settings.useragent
            "ContentType" = "application/json; charset=utf-8"
            #Verbose = $false
        }

        # Wait until 1 second is full, then proceed
        # This is only relevant for all calls after the first one
        If ( $i -gt 0) {            
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
        $t = Measure-Command {
            # TODO [ ] possibly implement proxy, if needed
            # TODO add try catch here
            $res = Invoke-RestMethod -Uri $uriRequest.Uri.OriginalString @restParams
        }
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
        # RETURN RAW OR ADD SOME METADATA
        #-----------------------------------------------

        If ( $AddMetaData -eq $true ) {

            # Build hash value
            $inputStringToHash = [System.Text.StringBuilder]::new()        
            $Address.PSObject.Properties | ForEach-Object {
                $prop = $_.Name
                [void]$inputStringToHash.Append( $Address.$prop.toLower() )
            }
            $hashedInput = Get-StringHash -salt "" -InputString $inputStringToHash.ToString() -HashName "sha256"

            [PSCustomObject]@{
                "inputHash" = $hashedInput
                "results" = $ret
                "total" = $res.count
            }

        } else {

            $ret

        }
        

        

        


    }
    
    end {
        
    }
}


# Geocode a single address
<#
$addr = [PSCustomObject]@{
    "street" = "Schaumainkai 87"
    "city" = "Frankfurt"
    "postalcode" = 60589
    "countrycodes" = "de"
}

Invoke-OSM -Address $addr -UserAgent "florian.von.bracht@apteco.de" -AddressDetails -ExtraTags -verbose
# OR
$addr | Invoke-OSM -UserAgent "florian.von.bracht@apteco.de" -AddressDetails -ExtraTags -verbose
#>


# Geocode a multiple addresses, but be aware, there could be problems with the encoding if not reading directly from databases or files
<#
$addresses = @(
    [PSCustomObject]@{
        "street" = "Schaumainkai 87"
        "city" = "Frankfurt"
        "postalcode" = 60589
        "countrycodes" = "de"
    }
    [PSCustomObject]@{
        "street" = "Kaiserstrasse 35"
        "city" = "Frankfurt"
        #"postalcode" = 60589
        "countrycodes" = "de"
    }
)

$addresses = Import-csv ".\test.csv" -Encoding UTF8 -Delimiter "`t"
#$addresses | Invoke-OSM -UserAgent "florian.von.bracht@apteco.de" -AddressDetails -ExtraTags -verbose
$addresses | Invoke-OSM -UserAgent "florian.von.bracht@apteco.de" -AddressDetails -ExtraTags -AddMetaData -ReturnOnlyFirstPosition -ResultsLanguage "de" | Out-GridView
#>