<#

Hashes a string with the algorithm name the Orbit API itself reports (via
CreateLoginParameters' hashAlgorithm field, e.g. "SHA256"), optionally appending a salt before
hashing. Used twice in the "SALTED" login flow: once unsalted, once with the server's loginSalt.

#>
function Get-OrbitStringHash {
    [CmdletBinding()]
    param(
         [Parameter(Mandatory=$true)][String]$InputString
        ,[Parameter(Mandatory=$true)][String]$HashName
        ,[Parameter(Mandatory=$false)][String]$Salt = ""
        ,[Parameter(Mandatory=$false)][Bool]$Uppercase = $false
    )

    $algorithm = [System.Security.Cryptography.HashAlgorithm]::Create( $HashName )
    try {
        $bytes = [System.Text.Encoding]::UTF8.GetBytes( $InputString + $Salt )
        $hashBytes = $algorithm.ComputeHash( $bytes )
    } finally {
        $algorithm.Dispose()
    }

    $stringBuilder = New-Object System.Text.StringBuilder
    foreach ( $byte in $hashBytes ) {
        [void]$stringBuilder.Append( $byte.ToString("x2") )
    }

    $result = $stringBuilder.ToString()

    if ( $Uppercase -eq $true ) {
        return $result.ToUpper()
    }
    return $result

}
