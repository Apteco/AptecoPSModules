function Set-OrbitTlsProtocol {
    [CmdletBinding()]
    param()

    # Windows PowerShell (Desktop, .NET Framework) needs an explicit opt-in for TLS1.2/1.3.
    # pwsh (Core) already negotiates the modern set by default, so it is left untouched.
    if ( $PSEdition -eq "Desktop" -and $Script:settings.changeTLS -eq $true ) {

        $protocols = $Script:settings.allowedProtocols | ForEach-Object { [System.Net.SecurityProtocolType]$_ }
        $combined = $protocols[0]
        $protocols | Select-Object -Skip 1 | ForEach-Object { $combined = $combined -bor $_ }
        [System.Net.ServicePointManager]::SecurityProtocol = $combined

    }

}
