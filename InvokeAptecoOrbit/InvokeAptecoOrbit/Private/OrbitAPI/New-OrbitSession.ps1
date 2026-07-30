<#

Logs in against the Orbit API and caches the resulting session to $Script:settings.sessionFile.

Both the "SIMPLE" and "SALTED" login types are supported. "SALTED" first asks the server for
its login parameters (CreateLoginParameters), then builds the password hash the server expects:
Protect-OrbitPassword transform -> optionally append the server's userSalt -> hash -> hash again
with the server's loginSalt appended.

#>
function New-OrbitSession {
    [CmdletBinding()]
    param()

    if ( $null -eq $Script:credential ) {
        throw "No credentials available. Call Connect-AptecoOrbit first."
    }

    $plainPassword = $Script:credential.GetNetworkCredential().Password

    switch ( $Script:settings.loginType ) {

        "SIMPLE" {

            $body = @{
                "UserLogin" = $Script:credential.UserName
                "Password"  = $plainPassword
            }

            $endpointKey = "CreateSessionSimple"

        }

        "SALTED" {

            $loginParametersEndpoint = Get-OrbitEndpointDefinition -Key "CreateLoginParameters"
            $loginParametersUri = Resolve-OrbitUrl -Endpoint $loginParametersEndpoint

            $loginDetails = Invoke-RestMethod -Uri $loginParametersUri -Method $loginParametersEndpoint.method -ContentType "application/x-www-form-urlencoded" -Body @{ "userName" = $Script:credential.UserName }

            $passwordStep1 = Protect-OrbitPassword -Password $plainPassword

            if ( $loginDetails.saltPassword -eq $true -and "" -ne $loginDetails.userSalt ) {
                $passwordStep1 += $loginDetails.userSalt
            }

            $passwordStep2 = Get-OrbitStringHash -InputString $passwordStep1 -HashName $loginDetails.hashAlgorithm
            $passwordStep3 = Get-OrbitStringHash -InputString $passwordStep2 -HashName $loginDetails.hashAlgorithm -Salt $loginDetails.loginSalt

            $body = @{
                "Username"     = $Script:credential.UserName
                "LoginSalt"    = $loginDetails.loginSalt
                "PasswordHash" = $passwordStep3
            }

            $endpointKey = "CreateSessionSalted"

        }

        default {
            throw "Login type '$( $Script:settings.loginType )' is not supported. Use 'SIMPLE' or 'SALTED'."
        }

    }

    $endpoint = Get-OrbitEndpointDefinition -Key $endpointKey
    $uri = Resolve-OrbitUrl -Endpoint $endpoint

    $login = Invoke-RestMethod -Uri $uri -Method $endpoint.method -ContentType "application/x-www-form-urlencoded" -Body $body

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
