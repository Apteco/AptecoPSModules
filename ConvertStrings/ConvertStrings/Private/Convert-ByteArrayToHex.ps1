Function Convert-ByteArrayToHex {

    <#
    .SYNOPSIS
        Converts a byte array into its hexadecimal string representation

    .DESCRIPTION
        Apteco PS Modules - Transform bytes into hexadecimal string (e.g. for hash values)

        So e.g. if you create a byte array
        $bytes = [System.Text.encoding]::UTF8.GetBytes("Hello World")

        and call

        Convert-ByteArrayToHex -ByteArray $bytes

        you get the hexadecimal string representation like

        48656c6c6f20576f726c64

    .PARAMETER ByteArray
        Byte array as an input for this function

    .EXAMPLE
        Convert-ByteArrayToHex -ByteArray @(72, 101, 108, 108, 111, 32, 87, 111, 114, 108, 100)
        
    .INPUTS
        Byte[]

    .OUTPUTS
        String

    .NOTES
        Author:  florian.von.bracht@apteco.de

    #>

    [CmdletBinding()]
    param (
         [Parameter(Mandatory=$true)][Byte[]]$ByteArray
    )

    Process {
        
        # Create StringBuilder
        $stringBuilder = [System.Text.StringBuilder]::new($ByteArray.Length * 2)

        # Format bytes
        $ByteArray | ForEach-Object {
            [void]$stringBuilder.Append($_.ToString("x2"))
            #$stringBuilder.AppendFormat("{0:x2}", $_) | Out-Null # Alternative
        }

        # Return
        return $stringBuilder.ToString()

    }

}
