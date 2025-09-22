<#
"Hello World" | Get-PlaintextToSecure | Get-SecureToPlaintext

WARNUNG: No keyfile present at '.\aes.key'. Creating it now
Hello World


"Hello World" | Get-PlaintextToSecure
76492d1116743f0423413b16050a5345MgB8AHIATAAyADEAcwBiAGsATwBJAEgANQBFAEUAbwBsAHUANABWAE8AaQBtAEEAPQA9AHwAMQBmADMANAA0ADAAMAA2AGYANABmAGQAOQBmAGYAYwA4AGMAYQA0ADkAOQBjADcAZQA4ADEANgAxAGIANAAxADMANgBlADMANQAwADEAYgBiADEAZABkAGQAMgAzADAAMgA5AGQANQBmADgAMABkAGUANABmAGEANAAwAGMAMwA=


Save this text into a variable like

$t = "Hello World" | Get-PlaintextToSecure

And decrypt it with

$t | Get-SecureToPlaintext
Hello World

Please don't try to move the keyfile or the encrypted string to another machine. It uses a combination of AES encryption and SecureString, where the last one is dependent on the current machine or account.
You can only decrypt the text on the same machine/account where you have encrypted it.

If you don't provide a keyfile, it will be automatically generated with your first call of 'Get-PlaintextToSecure'

#>

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
            Create-KeyFile -Path $Script:keyfile -ByteLength 32
        }

    }

    Process {

        $return = ""

        # generate salt
        $salt = Get-Content -Path $Script:keyfile -Encoding UTF8

        # convert
        $stringSecure = ConvertTo-secureString -String $String -asplaintext -force
        $return = ConvertFrom-SecureString $stringSecure -Key $salt

        # return
        return $return

    }

    End {

    }

}
