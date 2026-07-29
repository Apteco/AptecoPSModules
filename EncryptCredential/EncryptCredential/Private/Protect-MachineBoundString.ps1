Function Protect-MachineBoundString {

<#
    Wraps an already key-encrypted string (output of ConvertFrom-SecureString -Key) into a
    machine-bound outer layer, so a stolen ciphertext + keyfile cannot be decrypted on
    another machine.

    Windows (Desktop + Core):
        DPAPI (ProtectedData) with the keyfile bytes as additional entropy.
        Scope 'Machine' -> DataProtectionScope::LocalMachine (any account on this machine
                           that also has the keyfile can decrypt)
        Scope 'User'    -> DataProtectionScope::CurrentUser (bound to this machine AND
                           this user account)

    Linux/macOS:
        No DPAPI available. Encryption keys are derived via HMAC-SHA256 from the keyfile
        bytes and the machine id (plus the username for scope 'User'), then AES-256-CBC
        with a random IV and HMAC-SHA256 over IV+ciphertext (encrypt-then-MAC).
        Note: this binding is best effort - an attacker who can read the keyfile AND the
        machine id can reconstruct the key offline.

    Output format: ApSec2|<Scope>|<Base64>
#>

    param(
         [Parameter(Mandatory=$true)][String]$String
        ,[Parameter(Mandatory=$true)][Byte[]]$KeyBytes
        ,[Parameter(Mandatory=$true)][ValidateSet('Machine','User')][String]$Scope
    )

    $plainBytes = [System.Text.Encoding]::UTF8.GetBytes($String)

    If ( $PSVersionTable.PSEdition -eq 'Desktop' -or $IsWindows ) {

        # ProtectedData lives in System.Security on Windows PowerShell 5.1
        If ( $PSVersionTable.PSEdition -eq 'Desktop' ) {
            Add-Type -AssemblyName System.Security
        }

        $dpapiScope = If ( $Scope -eq 'User' ) {
            [System.Security.Cryptography.DataProtectionScope]::CurrentUser
        } else {
            [System.Security.Cryptography.DataProtectionScope]::LocalMachine
        }

        $protectedBytes = [System.Security.Cryptography.ProtectedData]::Protect($plainBytes, $KeyBytes, $dpapiScope)

    } else {

        # Derive independent encryption and MAC keys from keyfile + machine context
        $context = Get-MachineIdentifier
        If ( $Scope -eq 'User' ) {
            $context = "$( $context )|$( [System.Environment]::UserName )"
        }

        $kdf = [System.Security.Cryptography.HMACSHA256]::new($KeyBytes)
        $encKey = $kdf.ComputeHash([System.Text.Encoding]::UTF8.GetBytes("enc|$( $context )"))
        $macKey = $kdf.ComputeHash([System.Text.Encoding]::UTF8.GetBytes("mac|$( $context )"))
        $kdf.Dispose()

        $aes = [System.Security.Cryptography.Aes]::Create()
        Try {
            $aes.Key = $encKey
            $aes.GenerateIV()
            $encryptor = $aes.CreateEncryptor()
            $cipherBytes = $encryptor.TransformFinalBlock($plainBytes, 0, $plainBytes.Length)
            $encryptor.Dispose()
            $ivAndCipher = $aes.IV + $cipherBytes
        } Finally {
            $aes.Dispose()
        }

        $hmac = [System.Security.Cryptography.HMACSHA256]::new($macKey)
        $mac = $hmac.ComputeHash($ivAndCipher)
        $hmac.Dispose()

        $protectedBytes = $ivAndCipher + $mac

    }

    "ApSec2|$( $Scope )|$( [Convert]::ToBase64String($protectedBytes) )"

}
