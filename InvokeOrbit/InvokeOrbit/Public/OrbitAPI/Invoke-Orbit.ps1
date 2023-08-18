
function Invoke-Orbit {

<#
    .SYNOPSIS
        Writing log messages into a logfile and additionally to the console output.
        The messages are also redirected to the Apteco software, if used in a custom channel

    .DESCRIPTION
        Apteco PS Modules - PowerShell file rows count

        Just use

        Measure-Rows -Path "C:\Temp\Example.csv"

        or 

        "C:\Temp\Example.csv" | Measure-Rows -SkipFirstRow

        or 

        Measure-Rows -Path "C:\Temp\Example.csv" -Encoding UTF8

        to count the rows in a csv file. It uses a .NET streamreader and is extremly fast.

        The default encoding is UTF8, but it uses the ones available in [System.Text.Encoding]

        If you want to skip the first line, just use this Switch -SkipFirstRow

    .PARAMETER Path
        Path for the file to measure

    .PARAMETER SkipFirstRow
        Skips the first row, e.g. for use with CSV files that have a header

    .PARAMETER Encoding
        Uses encodings for the file. Default is UTF8

    .EXAMPLE
        Measure-Rows -Path "C:\Temp\Example.csv"

    .EXAMPLE
        "C:\Temp\Example.csv" | Measure-Rows -SkipFirstRow

    .EXAMPLE
        Measure-Rows -Path "C:\Temp\Example.csv" -Encoding UTF8

    .EXAMPLE
        "C:\Users\Florian\Downloads\ac_adressen.csv", "C:\Users\Florian\Downloads\italian.csv" | Measure-Rows -SkipFirstRow -Encoding ([System.Text.Encoding]::UTF8) 
        
    .INPUTS
        String

    .OUTPUTS
        Long

    .NOTES
        Author:  florian.von.bracht@apteco.de

    #>

    [CmdletBinding()]

    # Add additional parameters to this function
    param (
         [Parameter(Mandatory=$true)][String]$Key                   # The endpoint name to call
        ,[Parameter(Mandatory=$false)][Hashtable]$PathParam = @{}             # Additional params for the url path
        ,[Parameter(Mandatory=$false)][Hashtable]$QueryParam = @{}            # Addtional params for the url query
    )

    # Keep the original parameters of the underlying function
    DynamicParam { Get-BaseParameters "Invoke-WebRequest" }

    Begin {

        #-----------------------------------------------
        # START TIMER
        #-----------------------------------------------

        $processStart = [datetime]::now

        #-----------------------------------------------
        # LOG
        #-----------------------------------------------
<#
        $moduleName = "UPLOAD"

        # Start the log
        Write-Log -message $Script:logDivider
        Write-Log -message $moduleName -Severity INFO

        # Log the params, if existing
        Write-Log -message "INPUT:"
        if ( $InputHashtable ) {
            $InputHashtable.Keys | ForEach-Object {
                $param = $_
                Write-Log -message "    $( $param ) = '$( $InputHashtable[$param] )'" -writeToHostToo $false
            }
        }
#>

        #-----------------------------------------------
        # DEPENDENCIES
        #-----------------------------------------------
<#
        Import-Module MeasureRows
        Import-Module SqlServer
        Import-Lib -IgnorePackageStructure
        #[void][Reflection.Assembly]::LoadFile("C:\Users\Administrator.kikapp\Downloads\test\lib\Microsoft.Bcl.AsyncInterfaces.7.0.0\lib\net462\Microsoft.Bcl.AsyncInterfaces.dll")
#>


    }

    Process {

        # Get endpoint information first
        # TODO [ ] Lookup the settings how the endpoints should be loaded
        $endpoint = Get-Endpoint -key $key

        # Build uri
        $uri = Resolve-Url -endpoint $endpoint -additional $additional -query $query
            
        # Base headers

        $headers += @{
            "accept"="application/json"
        }

        # Add this parameter to the params, if it is not overridden
        $ContentType = "application/json"

        # Add this to the parameters
        $Method = $endpoint.method

        # Prepare the parameters
        $updatedParameters = Skip-UnallowedBaseParameters -Base "Invoke-WebRequest" -Parameters $PSBoundParameters

        # TODO [ ] Test the $Verbose parameter


        

        $tries = 0
        Do {

            try {
                
                if ( $endpoint.AllowsAnonymousAccess -eq $false ) {
                    
                    # decrypt secure string
                    if ( $settings.encryptToken ) {
                        $accessToken = Get-SecureToPlaintext -String $Script:accessToken
                    } else {
                        $accessToken = $Script:accessToken
                    }

                    $auth = "Bearer $( $accessToken )"

                    if ($tries -eq 1) {  
                        # remove auth header first, if this is the second try
                        $headers.Remove("Authorization")                                      
                    } 

                    $headers += @{
                        "Authorization"=$auth
                    }
                    
                }
            
                $response = Invoke-WebRequest @updatedParameters

                <#
                switch ( $endpoint.method ) {
                    
                    "GET" {
                        # Request the original function
                        $response = Invoke-RestMethod -Uri $uri -ContentType $contentType -Method $endpoint.method -Headers $headers -Verbose:$verboseCall -OutFile $outFile

                    }

                    default {

                        $response = Invoke-RestMethod -Uri $uri -ContentType $contentType -Method $endpoint.method -Body $body -Headers $headers -Verbose:$verboseCall -OutFile $outFile

                    }

                }
                #>

            
            } catch {

                <#
                #Write-Host $_.Exception.Response.StatusDescription
                $e = ParseErrorForResponseBody($_)
                Write-Host ( $e | ConvertTo-Json -Depth 20 )

                #If ($_.Exception.Response.StatusCode.value__ -eq "500") {
                    Create-AptecoSession
                #}
                #>

            }
            

        } until ( $tries++ -eq 1 -or $response ) # this gives us one retry


    }

    End {

        return $response

    }

}
