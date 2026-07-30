<#

The Orbit API's "SALTED" login flow expects the password to first go through this
non-cryptographic, per-character transform (even char code -> +1, odd char code -> -1) before
it is (optionally) salted and hashed. This is not a security measure - it is a fixed, documented
step the server expects as part of building PasswordHash for CreateSessionSalted.

#>
function Protect-OrbitPassword {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)][String]$Password
    )

    $transformed = $Password.ToCharArray() | ForEach-Object {
        $code = [int][char]$_
        if ( $code % 2 -eq 0 ) {
            [char]( $code + 1 )
        } else {
            [char]( $code - 1 )
        }
    }

    return ( $transformed -join "" )

}
