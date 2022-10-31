
<#

This function copies the key, not moving it

#>
Function Export-Keyfile {

<#
.SYNOPSIS
    Exporting the keyfile to another path

.DESCRIPTION
    This function is using the currently defined keyfile or the automatically generated one and exports it to the defined $Path

.PARAMETER Path
    The place where you want to export it to

.PARAMETER Force
    Use this parameter to enforce overwriting of existing keys

.EXAMPLE
    Export-Keyfile -Path "C:\temp\key.aes"

.INPUTS
    String

.OUTPUTS
    FileItem

.NOTES
    Author:  florian.von.bracht@apteco.de

#>

    [CmdletBinding()]
    param(
          [Parameter(Mandatory=$true,ValueFromPipeline=$true)][String]$Path
         ,[Parameter(Mandatory=$false)][Switch]$Force
    )

    Begin {

        # Use the default keyfile, if not loaded yet
        If ( $null -eq $Script:keyfile ) {
            $Script:keyfile = $Script:defaultKeyfile
        }

    }

    Process {

        # TODO [ ] check if $Path and $Script:keyfile are the same

        # Create the file, if not existing yet
        If ( (Test-Path -Path $Script:keyfile) -eq $false ) {
            Create-KeyFile -Path $Script:keyfile -ByteLength 32
        }

        # Move the keyfile to the new destination
        If ( (Test-Path -Path $Path -IsValid) -eq $true ) {
            If ( (Test-Path -Path $Path) -eq $true -and $Force -eq $false ) {
                Write-Error "There is already an file at the path '$( $Path )'. Please use -Force to overwrite the file"
            } else {
                Copy-Item -Path $Script:keyfile -Destination $Path -Force
            }
        }

        # Change it to the new path
        $Script:keyfile = $Path

        # Return
        ( Get-Item -Path $Script:keyfile )

    }

    End {}

}