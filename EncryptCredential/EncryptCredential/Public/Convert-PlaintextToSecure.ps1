
Function Convert-PlaintextToSecure {

<#
.SYNOPSIS
    Converts a plaintext string to an encrypted string

.DESCRIPTION
    This function converts a plaintext string back to an encrypted that can be saved e.g. in text files. It uses a secure string and a salt keyfile to make this happen.

.PARAMETER String
    The string you want to encrypt

.EXAMPLE
    Convert-PlaintextToSecure -String "Hello World"

.EXAMPLE
    "Hello World" | Convert-PlaintextToSecure

.INPUTS
    Decrypted String

.OUTPUTS
    Encrypted String

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

        # Create the file, if not existing yet
        If ( (Test-Path -Path $Script:keyfile) -eq $false ) {
            New-KeyFile -Path $Script:keyfile -ByteLength 32
        }

    }

    Process {

        $return = ""

        # read key bytes (handles both binary and legacy text format)
        $salt = Read-Keyfile -Path $Script:keyfile

        # convert
        $stringSecure = ConvertTo-secureString -String $String -asplaintext -force
        $return = ConvertFrom-SecureString $stringSecure -Key $salt

        # return
        return $return

    }

    End {

    }

}
