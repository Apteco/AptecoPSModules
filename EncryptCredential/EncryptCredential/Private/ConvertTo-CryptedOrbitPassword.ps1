Function ConvertTo-CryptedOrbitPassword {
<#
.SYNOPSIS
    Transforms a password into the wire format expected by the Apteco Orbit API.

.DESCRIPTION
    WARNING: This is NOT encryption. It is a fixed character-shift obfuscation
    (each character's ASCII value is incremented or decremented by 1 based on
    odd/even parity) required by the Orbit API wire format.

    Anyone who can read the output can trivially reverse it. Do not rely on
    this function for confidentiality. Protect the value at the transport and
    storage layer instead (TLS, restricted file ACLs, secure credential stores).

.PARAMETER Password
    The plaintext password to obfuscate for the Orbit API.
#>
    param(
        [String]$Password
    )

    $cryptedPassword = @()
    $Password.ToCharArray() | ForEach-Object { [int][char]$_ } | ForEach-Object {
        If ($_ % 2 -eq 0) {
            $cryptedPassword += [char]( $_ + 1 )
        } else {
            $cryptedPassword += [char]( $_ - 1 )
        }
    }

    $cryptedPassword -join ""

}