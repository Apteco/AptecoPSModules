Function Unprotect-MachineBoundString {

<#
    Reverses Protect-MachineBoundString. Takes the full 'ApSec2|<Scope>|<Base64>' string
    and returns the inner key-encrypted string (input for ConvertTo-SecureString -Key).
#>

    param(
         [Parameter(Mandatory=$true)][String]$String
        ,[Parameter(Mandatory=$true)][Byte[]]$KeyBytes
    )

    $parts = $String -split '\|', 3
    If ( $parts.Count -ne 3 -or $parts[0] -ne 'ApSec2' -or $parts[1] -notin @('Machine','User') ) {
        throw "The string is not in a valid machine-bound format."
    }

    $scope = $parts[1]
    $protectedBytes = [Convert]::FromBase64String($parts[2])

    If ( $PSVersionTable.PSEdition -eq 'Desktop' -or $IsWindows ) {

        If ( $PSVersionTable.PSEdition -eq 'Desktop' ) {
            Add-Type -AssemblyName System.Security
        }

        $dpapiScope = If ( $scope -eq 'User' ) {
            [System.Security.Cryptography.DataProtectionScope]::CurrentUser
        } else {
            [System.Security.Cryptography.DataProtectionScope]::LocalMachine
        }

        $plainBytes = [System.Security.Cryptography.ProtectedData]::Unprotect($protectedBytes, $KeyBytes, $dpapiScope)

    } else {

        If ( $protectedBytes.Length -lt ( 16 + 32 + 1 ) ) {
            throw "The machine-bound payload is too short to be valid."
        }

        $context = Get-MachineIdentifier
        If ( $scope -eq 'User' ) {
            $context = "$( $context )|$( [System.Environment]::UserName )"
        }

        $kdf = [System.Security.Cryptography.HMACSHA256]::new($KeyBytes)
        $encKey = $kdf.ComputeHash([System.Text.Encoding]::UTF8.GetBytes("enc|$( $context )"))
        $macKey = $kdf.ComputeHash([System.Text.Encoding]::UTF8.GetBytes("mac|$( $context )"))
        $kdf.Dispose()

        $macOffset = $protectedBytes.Length - 32
        $ivAndCipher = $protectedBytes[0..($macOffset - 1)]
        $mac = $protectedBytes[$macOffset..($protectedBytes.Length - 1)]

        # Verify the MAC before touching the ciphertext (constant-time comparison)
        $hmac = [System.Security.Cryptography.HMACSHA256]::new($macKey)
        $expectedMac = $hmac.ComputeHash([byte[]]$ivAndCipher)
        $hmac.Dispose()
        $diff = 0
        For ( $i = 0; $i -lt 32; $i++ ) {
            $diff = $diff -bor ( $mac[$i] -bxor $expectedMac[$i] )
        }
        If ( $diff -ne 0 ) {
            throw "Integrity check failed. The string was tampered with or belongs to another machine/user."
        }

        $aes = [System.Security.Cryptography.Aes]::Create()
        Try {
            $aes.Key = $encKey
            $aes.IV = [byte[]]$ivAndCipher[0..15]
            $decryptor = $aes.CreateDecryptor()
            $cipherBytes = [byte[]]$ivAndCipher[16..($ivAndCipher.Length - 1)]
            $plainBytes = $decryptor.TransformFinalBlock($cipherBytes, 0, $cipherBytes.Length)
            $decryptor.Dispose()
        } Finally {
            $aes.Dispose()
        }

    }

    [System.Text.Encoding]::UTF8.GetString($plainBytes)

}
