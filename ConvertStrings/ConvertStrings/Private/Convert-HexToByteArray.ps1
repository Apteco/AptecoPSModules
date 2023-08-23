
Function Convert-HexToByteArray {

    <#
    .SYNOPSIS
        Converts a hex string into its bytes representation

    .DESCRIPTION
        Apteco PS Modules - Transform hexadecimal string into bytes

        So e.g. if you have a hexadecimal string like
        $str = "48656c6c6f20576f726c64"

        and call

        $bytes = Convert-HexToByteArray -HexString $str

        you get the byte representation like

        72
        101
        108
        108
        111
        32
        87
        111
        114
        108
        100

        which can be converted back into string like

        [System.Text.Encoding]::Default.GetString($bytes)

        which then results into

        Hello World

    .PARAMETER HexString
        Hexadecimal string

    .EXAMPLE
        Convert-HexToByteArray -HexString "48656c6c6f20576f726c64"

    .INPUTS
        String

    .OUTPUTS
        Byte[]

    .NOTES
        Author:  florian.von.bracht@apteco.de

    #>

    [cmdletbinding()]
    param(
        [parameter(Mandatory=$true)][String]$HexString
    )

    Process {

        $Bytes = [Byte[]]::new($HexString.Length / 2)

        For($i=0; $i -lt $HexString.Length; $i+=2){
            $Bytes[$i/2] = [System.Convert]::ToByte($HexString.Substring($i, 2), 16)
        }

        # Return
        $Bytes

    }




}
