Function ConvertTo-CryptedOrbitPassword {
<#
Password encryption for Apteco Orbit
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