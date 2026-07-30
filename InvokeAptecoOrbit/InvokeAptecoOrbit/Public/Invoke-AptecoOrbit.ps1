function Invoke-AptecoOrbit {
    [CmdletBinding()]

    <#
    .SYNOPSIS
        Calls a single Apteco Orbit API endpoint by its endpoint key.

    .DESCRIPTION
        Apteco PS Modules - generic authenticated Orbit API call

        Looks up the endpoint definition (HTTP method + url template) from the Orbit API's own
        endpoint catalog, resolves path/query parameters, attaches the bearer token from the
        active session (see Connect-AptecoOrbit) and performs the request. On a single 401 it
        refreshes the session once and retries.

    .PARAMETER Key
        The endpoint key/name as returned by the Orbit API's About/Endpoints catalog, e.g. "GetPeopleStageSystem"

    .PARAMETER PathParameters
        Values to substitute into the endpoint's url template, e.g. @{ systemName = "Demo" }

    .PARAMETER QueryParameters
        Values appended to the url as a query string, e.g. @{ offset = 0; count = 100 }

    .PARAMETER Body
        Request body for non-GET calls

    .PARAMETER ContentType
        Content type of the request body. Default "application/json".

    .EXAMPLE
        Invoke-AptecoOrbit -Key "GetPeopleStageSystem" -QueryParameters @{ systemName = "Demo" }

    .INPUTS
        None

    .OUTPUTS
        PSCustomObject - the parsed JSON response

    .NOTES
        Author:  florian.von.bracht@apteco.de

    #>

    param(
         [Parameter(Mandatory=$true)][String]$Key
        ,[Parameter(Mandatory=$false)][Hashtable]$PathParameters = @{}
        ,[Parameter(Mandatory=$false)][Hashtable]$QueryParameters = @{}
        ,[Parameter(Mandatory=$false)]$Body = $null
        ,[Parameter(Mandatory=$false)][String]$ContentType = "application/json"
    )

    begin {

        if ( $null -eq $Script:sessionId ) {
            Get-OrbitSession
        }

    }

    process {

        $endpoint = Get-OrbitEndpointDefinition -Key $Key
        $uri = Resolve-OrbitUrl -Endpoint $endpoint -PathParameters $PathParameters -QueryParameters $QueryParameters

        for ( $attempt = 0; $attempt -le 1; $attempt++ ) {

            $headers = @{
                "accept" = "application/json"
            }

            if ( $endpoint.AllowsAnonymousAccess -ne $true ) {
                $accessToken = if ( $Script:settings.encryptToken -eq $true ) {
                    Convert-SecureToPlaintext -String $Script:sessionToken
                } else {
                    $Script:sessionToken
                }
                $headers["Authorization"] = "Bearer $( $accessToken )"
            }

            $requestParams = @{
                Uri         = $uri
                Method      = $endpoint.method
                Headers     = $headers
                ContentType = $ContentType
            }

            if ( $null -ne $Body ) {
                $requestParams.Body = if ( $ContentType -eq "application/json" ) { $Body | ConvertTo-Json -Depth 20 } else { $Body }
            }

            try {

                return Invoke-RestMethod @requestParams

            } catch {

                $statusCode = $_.Exception.Response.StatusCode.value__

                if ( $statusCode -eq 401 -and $attempt -eq 0 ) {
                    Write-Verbose "Orbit session expired or rejected, refreshing and retrying once"
                    Get-OrbitSession -Force
                    continue
                }

                throw

            }

        }

    }

}
