Function New-Keyfile {

<#
.SYNOPSIS
    Generates a new keyfile, replacing any existing one.

.DESCRIPTION
    Creates a fresh cryptographically random keyfile at the currently configured
    path (or the default path if none has been set). The old keyfile is deleted.

    WARNING: Any strings encrypted with the previous keyfile will no longer be
    decryptable after this operation. Re-encrypt all stored credentials after
    calling this function.

.EXAMPLE
    New-Keyfile

.EXAMPLE
    New-Keyfile -Verbose

.OUTPUTS
    System.IO.FileInfo

.NOTES
    Author:  florian.von.bracht@apteco.de

#>

    [CmdletBinding(SupportsShouldProcess, ConfirmImpact='High')]
    param()

    Begin {

        # Use the default keyfile path if none has been loaded
        If ( $null -eq $Script:keyfile ) {
            $Script:keyfile = $Script:defaultKeyfile
        }

    }

    Process {

        If ( $PSCmdlet.ShouldProcess($Script:keyfile, 'Regenerate keyfile - existing encrypted strings will become unreadable') ) {

            Write-Warning "Regenerating keyfile at '$( $Script:keyfile )'. All previously encrypted strings are now invalid."
            New-KeyfileRaw -Path $Script:keyfile -ByteLength 32 -Force
            Get-Item -Path $Script:keyfile

        }

    }

    End {}

}
