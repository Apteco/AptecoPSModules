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
            Write-Information -MessageData "Keyfile is valid"
            $Script:keyfile = $Path
        }  else {
            Write-Error -Message "The path you have provided does not exist"
        }

    }

    End {}

}