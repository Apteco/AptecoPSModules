
Function Measure-Row {

    <#
    .SYNOPSIS
        Writing log messages into a logfile and additionally to the console output.
        The messages are also redirected to the Apteco software, if used in a custom channel

    .DESCRIPTION
        Apteco PS Modules - PowerShell file rows count

        Just use

        Measure-Row -Path "C:\Temp\Example.csv"

        or

        "C:\Temp\Example.csv" | Measure-Row -SkipFirstRow

        or

        Measure-Row -Path "C:\Temp\Example.csv" -Encoding UTF8

        to count the rows in a csv file. It uses a .NET streamreader and is extremly fast.

        The default encoding is UTF8, but it uses the ones available in [System.Text.Encoding]

        If you want to skip the first line, just use this Switch -SkipFirstRow

        Putting multiple files in the pipeline is also possible, it adds up the rows of all files.

    .PARAMETER Path
        Path for the file to measure

    .PARAMETER SkipFirstRow
        Skips the first row, e.g. for use with CSV files that have a header

    .PARAMETER Encoding
        Uses encodings for the file like [System.Text.Encoding]::UTF8. Default is UTF8

    .EXAMPLE
        Measure-Row -Path "C:\Temp\Example.csv"

    .EXAMPLE
        "C:\Temp\Example.csv" | Measure-Row -SkipFirstRow

    .EXAMPLE
        Measure-Row -Path "C:\Temp\Example.csv" -Encoding UTF8

    .EXAMPLE
        "C:\Users\Florian\Downloads\ac_adressen.csv", "C:\Users\Florian\Downloads\italian.csv" | Measure-Row -SkipFirstRow -Encoding ([System.Text.Encoding]::UTF8)

    .INPUTS
        String

    .OUTPUTS
        Long

    .NOTES
        Author:  florian.von.bracht@apteco.de

    #>


    [CmdletBinding()]
    [OutputType([long])]
    param(
         [Parameter(Mandatory=$true,ValueFromPipeline=$true)][String]$Path
        ,[Parameter(Mandatory=$false)][switch] $SkipFirstRow = $false
        ,[Parameter(Mandatory=$false)][System.Text.Encoding] $Encoding = [System.Text.Encoding]::UTF8
    )

    Begin {

        $c = [long]0

    }

    Process {

        # Check Path
        If ((Test-Path -Path $Path ) -eq $false ) {
            throw [System.IO.FileNotFoundException] "File '$( $Path )' not found"
        }

        $absolutePath = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($Path)
        $reader = [System.IO.StreamReader]::new($absolutePath, $Encoding)

        If ( $SkipFirstRow -eq $true ) {
            [void]$reader.ReadLine() # Skip first line.

        }

        # Go through all lines
        while ($reader.Peek() -ge 0) {
            [void]$reader.ReadLine()
            $c += 1
        }

        $reader.Close()

    }

    End {

        # Return
        $c

    }

}

