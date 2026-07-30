function Get-OrbitEndpointDefinition {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)][String]$Key
    )

    if ( $null -eq $Script:endpoints ) {
        [void]( Get-OrbitEndpoints )
    }

    $endpoint = $Script:endpoints | Where-Object { $_.name -eq $Key } | Select-Object -First 1

    if ( $null -eq $endpoint ) {
        throw "Unknown Orbit API endpoint '$( $Key )'. Check the key, or call Get-OrbitEndpoints to refresh the endpoint catalog if it was recently added on the server."
    }

    return $endpoint

}
