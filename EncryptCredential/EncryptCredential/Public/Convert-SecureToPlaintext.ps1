
Function Convert-SecureToPlaintext {

<#
.SYNOPSIS
    Converts a string that has been encrypted by this modules back to plaintext

.DESCRIPTION
    This function converts an encrypted string back to plaintext. It uses a secure string and a salt keyfile to make this happen.

.PARAMETER String
    The string you want to decrypt

.EXAMPLE
    Convert-SecureToPlaintext -String $str

.EXAMPLE
    $str | Convert-SecureToPlaintext

.INPUTS
    Encrypted String

.OUTPUTS
    Decrypted String

.NOTES
    Author:  florian.von.bracht@apteco.de

#>

    [cmdletbinding()]
    param(
         [Parameter(Mandatory=$true,ValueFromPipeline)][String]$String
        #,[Parameter(Mandatory=$false)][String]$KeyfilePath = ".\aes.key"
    )

    Begin {

        # Use the default keyfile, if not loaded yet
        If ( $null -eq $Script:keyfile ) {
            $Script:keyfile = $Script:defaultKeyfile
        }

        # Give a hint the file needs to be loaded
        If ( (Test-Path -Path $Script:keyfile) -eq $false ) {
            throw "The keyfile does not exist. Use 'Import-Keyfile -Path' to load a valid keyfile."
        }

    }

    Process {

        $return = ""

        # read key bytes (handles both binary and legacy text format)
        $salt = Read-Keyfile -Path $Script:keyfile

        # If the string carries the machine-bound outer layer, remove it first.
        # Legacy strings (created before 0.4.0 or with -Scope Portable) skip this and
        # go straight to the keyfile decryption -> downwards compatible.
        $innerString = $String
        If ( $String -like 'ApSec2|*' ) {
            Try {
                $innerString = Unprotect-MachineBoundString -String $String -KeyBytes $salt
            } Catch {
                throw "Decryption of the machine-bound layer failed. The string was probably encrypted on another machine or by another user account, or the keyfile was exchanged. Original error: $( $_.Exception.Message )"
            }
        }

        #convert
        Try {
            $stringSecure = ConvertTo-SecureString -String $innerString -Key $salt
            $return = (New-Object PSCredential "dummy",$stringSecure).GetNetworkCredential().Password
            $stringSecure.Dispose()
        } Catch {
            throw "Decryption failed, maybe the keyfile was exchanged or you copied the files to another machine? Original error: $( $_.Exception.Message )"
        }

        #return
        return $return

    }

    End {

    }

}


