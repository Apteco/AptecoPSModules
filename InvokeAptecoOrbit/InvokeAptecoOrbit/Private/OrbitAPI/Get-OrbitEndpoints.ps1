<#

Downloads and caches the Orbit API's own endpoint catalog (About/Endpoints), which maps an
endpoint key/name to its HTTP method and url template. Every other call in this module looks
up its endpoint definition from this cache via Get-OrbitEndpointDefinition.

#>
function Get-OrbitEndpoints {
    [CmdletBinding()]
    param()

    $pageSize = 100
    $offset = 0
    $totalCount = 0
    $endpoints = [System.Collections.ArrayList]@()

    do {

        $uri = "$( $Script:settings.base )About/Endpoints?excludeEndpointsWithNoLicenceRequirements=false&excludeEndpointsWithNoRoleRequirements=false&count=$( $pageSize )&offset=$( $offset )"
        $response = Invoke-RestMethod -Uri $uri -Method Get -ContentType "application/json; charset=utf-8"

        if ( $totalCount -eq 0 ) {
            $totalCount = $response.totalCount
        }

        [void]$endpoints.AddRange( @( $response.list ) )
        $offset += $pageSize

    } until ( $totalCount -eq 0 -or $offset -ge $totalCount )

    $Script:endpoints = $endpoints

    return $Script:endpoints

}
