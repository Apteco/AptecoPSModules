


<#

Loaded from https://github.com/PowerShell/PowerShell/issues/7092 to allow the creation of hashes of SSL certificates

Get-SHA256Thumbprint "https://www.apteco.de"
#Get-SHA256Thumbprint -URL "https://google.de"

#>

Function Get-SHA256Thumbprint {
    
    [CmdletBinding()]
    param(
        [Parameter(
            Position=0,
            Mandatory=$true,
            ValueFromPipeline=$true,
            ValueFromPipelineByPropertyName=$true)
        ]
        [Alias('FullName')]
        [String]$Url
    )

    Process {

        $cert = Get-SslCertificate -URL $Url
        $certBytes = $cert.GetRawCertData()

        $sha256 = [Security.Cryptography.SHA256]::Create()
        $hash = $sha256.ComputeHash($certBytes)
        $thumbprint = [BitConverter]::ToString($hash).Replace('-',':')

        # Return
        return $thumbprint

    }
}

#Get-SHA256Thumbprint -URL "https://google.de"