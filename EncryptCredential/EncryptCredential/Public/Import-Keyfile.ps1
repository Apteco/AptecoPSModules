Function Import-Keyfile {

<#
.SYNOPSIS
    Importing the keyfile from another path than the default

.DESCRIPTION
    This function is importing an keyfile (consisting of random bytes) from the defined $Path

.PARAMETER Path
    The place where you want to import the file from

.EXAMPLE
    Import-Keyfile -Path "C:\temp\key.aes"

.INPUTS
    String

.OUTPUTS
    $null

.NOTES
    Author:  florian.von.bracht@apteco.de

#>

    [CmdletBinding()]
    param(
         [Parameter(Mandatory=$true,ValueFromPipeline=$true)][String]$Path
    )

    Begin {

    }

    Process {

        If ( (Test-Path -Path $Path) -eq $true ) {

            # Validate the content is a usable AES key before accepting it
            Try {
                $keyBytes = Read-Keyfile -Path $Path
            } Catch {
                Write-Error -Message "The file at '$( $Path )' is not a valid keyfile: $( $_.Exception.Message )"
                return
            }

            If ( $keyBytes.Length -in @(16, 24, 32) ) {
                Write-Information -MessageData "Keyfile is valid"
                $Script:keyfile = $Path
            } else {
                Write-Error -Message "The file at '$( $Path )' is not a valid keyfile: the key must be 16, 24 or 32 bytes, but is $( $keyBytes.Length ) bytes"
            }

        }  else {
            Write-Error -Message "The path you have provided does not exist"
        }

    }

    End {}

}