Function Add-BomIfMissing {

    <#
    .SYNOPSIS
        Adds a UTF-8 byte order mark (BOM) to a file if it does not already have one.

    .DESCRIPTION
        Apteco PS Modules - Add BOM If Missing

        Reads the first bytes of a file and checks for the UTF-8 BOM (0xEF, 0xBB, 0xBF).
        If it is missing, the BOM is prepended to the file so that tools relying on the
        BOM to detect UTF-8 encoding will read the file correctly.

    .PARAMETER FilePath
        Path to the file that should be checked and, if needed, updated with a UTF-8 BOM

    .EXAMPLE
        Add-BomIfMissing -FilePath "C:\temp\export.csv"

    .EXAMPLE
        Get-ChildItem "C:\temp\*.csv" | Select-Object -ExpandProperty FullName | Add-BomIfMissing

    .INPUTS
        String

    .OUTPUTS
        None

    .NOTES
        Author:  florian.von.bracht@apteco.de

    #>

    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true,ValueFromPipeline=$true)][String]$FilePath
    )

    Process {

        $bytes = [System.IO.File]::ReadAllBytes($FilePath)
        $bom = [Byte[]]@(0xEF, 0xBB, 0xBF)

        # Check if BOM already present
        if ( $bytes.Length -ge 3 -and $bytes[0] -eq $bom[0] -and $bytes[1] -eq $bom[1] -and $bytes[2] -eq $bom[2] ) {
            Write-Verbose "BOM already present, skipping: $FilePath"
            return
        }

        # Prepend BOM and write back to the file
        $withBom = $bom + $bytes
        [System.IO.File]::WriteAllBytes($FilePath, $withBom)
        Write-Verbose "BOM added to: $FilePath"

    }

}
