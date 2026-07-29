
Function Convert-PlaintextToSecure {

<#
.SYNOPSIS
    Converts a plaintext string to an encrypted string

.DESCRIPTION
    This function converts a plaintext string into an encrypted one that can be saved e.g. in text files.
    It encrypts in two layers:

    1. AES-256 via SecureString with a random keyfile (the classic format of this module)
    2. A machine-bound outer layer, so a stolen ciphertext plus keyfile cannot be decrypted
       on another machine. On Windows this uses DPAPI (with the keyfile as additional entropy),
       on Linux/macOS keys derived from the keyfile and the machine id.

.PARAMETER String
    The string you want to encrypt

.PARAMETER Scope
    Machine  (default) - decryptable on this machine only, by any account that can read the keyfile
    User               - decryptable on this machine only AND only by the current user account
    Portable           - legacy single-layer format (keyfile only, no machine binding);
                         use this only if you need to move ciphertexts between machines together with the keyfile

.EXAMPLE
    Convert-PlaintextToSecure -String "Hello World"

.EXAMPLE
    "Hello World" | Convert-PlaintextToSecure -Scope User

.INPUTS
    Decrypted String

.OUTPUTS
    Encrypted String

.NOTES
    Author:  florian.von.bracht@apteco.de

#>

    [cmdletbinding()]
    # The whole point of this function is to encrypt a caller-supplied plaintext string; there is no credential to source a SecureString from instead.
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingConvertToSecureStringWithPlainText', '')]
    param(
         [Parameter(Mandatory=$true,ValueFromPipeline)][String]$String
        ,[Parameter(Mandatory=$false)][ValidateSet('Machine','User','Portable')][String]$Scope = 'Machine'
        #,[Parameter(Mandatory=$false)][String]$KeyfilePath = ".\aes.key"
    )

    Begin {

        # Use the default keyfile, if not loaded yet
        If ( $null -eq $Script:keyfile ) {
            $Script:keyfile = $Script:defaultKeyfile
        }

        # Create the file, if not existing yet
        If ( (Test-Path -Path $Script:keyfile) -eq $false ) {
            New-KeyfileRaw -Path $Script:keyfile -ByteLength 32 -Force
        }

    }

    Process {

        $return = ""

        # read key bytes (handles both binary and legacy text format)
        $salt = Read-Keyfile -Path $Script:keyfile

        # inner layer: AES via SecureString with the keyfile
        $stringSecure = ConvertTo-SecureString -String $String -AsPlainText -Force
        $return = ConvertFrom-SecureString $stringSecure -Key $salt
        $stringSecure.Dispose()

        # outer layer: bind the ciphertext to this machine (and optionally this user)
        If ( $Scope -ne 'Portable' ) {
            $return = Protect-MachineBoundString -String $return -KeyBytes $salt -Scope $Scope
        }

        # return
        return $return

    }

    End {

    }

}
