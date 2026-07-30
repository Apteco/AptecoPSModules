<#

Builds the final request url for an Orbit API endpoint: base url + url template, with
{dataViewName} and any other {placeholder} in the template substituted, plus an optional
query string appended.

#>
function Resolve-OrbitUrl {
    [CmdletBinding()]
    param(
         [Parameter(Mandatory=$true)][PSCustomObject]$Endpoint
        ,[Parameter(Mandatory=$false)][Hashtable]$PathParameters = @{}
        ,[Parameter(Mandatory=$false)][Hashtable]$QueryParameters = @{}
    )

    $uri = "$( $Script:settings.base )$( $Endpoint.urlTemplate )"

    # {dataViewName} is used by most endpoint templates and is implied by the active session,
    # so it does not need to be passed in explicitly every time
    $uri = $uri -replace "\{dataViewName\}", [uri]::EscapeDataString( "$( $Script:settings.dataView )" )

    foreach ( $key in $PathParameters.Keys ) {
        $uri = $uri -replace "\{$( $key )\}", [uri]::EscapeDataString( "$( $PathParameters[$key] )" )
    }

    if ( $QueryParameters.Count -gt 0 ) {
        $pairs = $QueryParameters.Keys | ForEach-Object {
            "$( $_ )=$( [uri]::EscapeDataString( "$( $QueryParameters[$_] )" ) )"
        }
        $uri += "?" + ( $pairs -join "&" )
    }

    return $uri

}
