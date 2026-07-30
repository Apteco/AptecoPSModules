<#

Logs in against the Orbit API and caches the resulting session to $Script:settings.sessionFile.

Only the "SIMPLE" login type is implemented. The Orbit API also offers a "SALTED" login type
(a multi-step, salted-hash exchange), but that requires knowing the exact hash algorithm and
salting order the target instance expects, which was never verified end-to-end - rather than
port a guessed implementation, it throws until someone can confirm the real handshake against
a live instance.

#>
function New-OrbitSession {
    [CmdletBinding()]
    param()

    if ( $null -eq $Script:credential ) {
        throw "No credentials available. Call Connect-AptecoOrbit first."
    }

    switch ( $Script:settings.loginType ) {

        "SIMPLE" {

            $body = @{
                "UserLogin" = $Script:credential.UserName
                "Password"  = $Script:credential.GetNetworkCredential().Password
            }

            $endpoint = Get-OrbitEndpointDefinition -Key "CreateSessionSimple"
            $uri = Resolve-OrbitUrl -Endpoint $endpoint

            $login = Invoke-RestMethod -Uri $uri -Method $endpoint.method -ContentType "application/x-www-form-urlencoded" -Body $body

        }

        default {
            throw "Login type '$( $Script:settings.loginType )' is not implemented yet. Only 'SIMPLE' is currently supported."
        }

    }

    $Script:sessionId = $login.sessionId
    $Script:sessionToken = if ( $Script:settings.encryptToken -eq $true ) {
        Convert-PlaintextToSecure -String $login.accessToken
    } else {
        $login.accessToken
    }
    $Script:sessionExpires = [datetime]::Now.AddMinutes( $Script:settings.ttl )

    $session = [PSCustomObject]@{
        sessionId   = $Script:sessionId
        accessToken = $Script:sessionToken
        expires     = $Script:sessionExpires.ToString("o")
        encrypted   = $Script:settings.encryptToken
    }

    $session | ConvertTo-Json | Set-Content -Encoding UTF8 -Path $Script:settings.sessionFile

}
