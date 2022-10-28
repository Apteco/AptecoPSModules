
<#

Use it like

Measure-Rows -Path "C:\Users\Florian\Downloads\Data\People.csv"

# Default Encoding is utf8

#>
Function Measure-Rows {

    <#
    .SYNOPSIS
        Writing log messages into a logfile and additionally to the console output.
        The messages are also redirected to the Apteco software, if used in a custom channel

    .DESCRIPTION
        Apteco PS Modules - PowerShell file rows count

        Just use

        Measure-Rows -Path "C:\Temp\Example.csv"

        or 

        "C:\Temp\Example.csv" | Measure-Rows -SkipFirstRow

        or 

        Measure-Rows -Path "C:\Temp\Example.csv" -Encoding UTF8

        to count the rows in a csv file. It uses a .NET streamreader and is extremly fast.

        The default encoding is UTF8, but it uses the ones available in [System.Text.Encoding]

        If you want to skip the first line, just use this Switch -SkipFirstRow

    .PARAMETER Path
        Path for the file to measure

    .PARAMETER SkipFirstRow
        Skips the first row, e.g. for use with CSV files that have a header

    .PARAMETER Encoding
        Uses encodings for the file. Default is UTF8

    .EXAMPLE
        Measure-Rows -Path "C:\Temp\Example.csv"

    .EXAMPLE
        "C:\Temp\Example.csv" | Measure-Rows -SkipFirstRow

    .EXAMPLE
        Measure-Rows -Path "C:\Temp\Example.csv" -Encoding UTF8

    .EXAMPLE
        "C:\Users\Florian\Downloads\ac_adressen.csv", "C:\Users\Florian\Downloads\italian.csv" | Measure-Rows -SkipFirstRow -Encoding ([System.Text.Encoding]::UTF8) 
        
    .INPUTS
        String

    .OUTPUTS
        Long

    .NOTES
        Author:  florian.von.bracht@apteco.de

    #>


    [CmdletBinding()]
    param(
         [Parameter(Mandatory=$true,ValueFromPipeline=$true)][String]$Path
        ,[Parameter(Mandatory=$false)][switch] $SkipFirstRow = $false
        ,[Parameter(Mandatory=$false)][System.Text.Encoding] $Encoding = [System.Text.Encoding]::UTF8
    )

    Begin {

        

    }

    Process {

        # If you put this one into begin and do something like
        # "C:\Users\Florian\Downloads\adressen.csv", "C:\Users\Florian\Downloads\italian.csv" | Measure-Rows
        # the counts will be added so you will get
        # 45475
        # 45485
        # instead of
        # 45475
        # 10
        $c = [long]0
        
        # Check Path
        If ((Test-Path -Path $Path ) -eq $false ) {
            Write-Error -Message "`$Path '$( $Path )' is not valid"
            Exit
        }

        $reader = [System.IO.StreamReader]::new($Path, $Encoding)

        <#
        Get-Content -Path $Path -ReadCount 1000 | ForEach {
            $c += $_.Count
        }
        #>

        If ( $SkipFirstRow -eq $true ) {
            [void]$reader.ReadLine() # Skip first line.

        }

        # Go through all lines
        while ($reader.Peek() -ge 0) {
            [void]$reader.ReadLine()
            $c += 1
        }

        $reader.Close()

        # Return
        $c
        
    }
    
    End {

    }

}
