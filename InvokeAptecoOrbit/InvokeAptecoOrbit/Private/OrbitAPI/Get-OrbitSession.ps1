<#

Reuses the cached session from $Script:settings.sessionFile if it is still valid, otherwise
logs in again via New-OrbitSession.

#>
function Get-OrbitSession {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)][Switch]$Force = $false
    )

    if ( $Force -eq $false -and ( Test-Path -Path $Script:settings.sessionFile ) ) {

        $cached = Get-Content -Encoding UTF8 -Path $Script:settings.sessionFile | ConvertFrom-Json
        $expires = [datetime]::Parse( $cached.expires, [System.Globalization.CultureInfo]::InvariantCulture, [System.Globalization.DateTimeStyles]::RoundtripKind )

        if ( $expires -gt [datetime]::Now ) {
            $Script:sessionId = $cached.sessionId
            $Script:sessionToken = $cached.accessToken
            $Script:sessionExpires = $expires
            return
        }

    }

    New-OrbitSession

}
