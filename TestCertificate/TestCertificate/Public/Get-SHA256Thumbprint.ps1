function Get-SHA256Thumbprint {
    [CmdletBinding()]

    <#
    .SYNOPSIS
        Computes the SHA-256 thumbprint of the SSL/TLS certificate presented by a given HTTPS url.

    .DESCRIPTION
        Apteco PS Modules - SSL certificate SHA-256 thumbprint

        Convenience wrapper around Get-SslCertificate that returns just the SHA-256 thumbprint,
        formatted as colon-separated hex pairs (e.g. for comparing against a known-good pin).

    .PARAMETER Url
        The https url to connect to

    .EXAMPLE
        Get-SHA256Thumbprint -Url "https://www.apteco.de"

    .INPUTS
        String

    .OUTPUTS
        String

    .NOTES
        Author:  florian.von.bracht@apteco.de

    #>

    param(
        [Parameter(
            Position=0,
            Mandatory=$true,
            ValueFromPipeline=$true,
            ValueFromPipelineByPropertyName=$true
        )]
        [Alias('FullName')]
        [String]$Url
    )

    process {

        $certificate = Get-SslCertificate -Url $Url
        $certificateBytes = $certificate.GetRawCertData()

        $sha256 = [System.Security.Cryptography.SHA256]::Create()
        try {
            $hash = $sha256.ComputeHash($certificateBytes)
        } finally {
            $sha256.Dispose()
        }

        return [BitConverter]::ToString($hash).Replace('-', ':')

    }

}
