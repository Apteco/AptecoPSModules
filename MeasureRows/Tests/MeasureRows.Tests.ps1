
BeforeDiscovery {

    # Helper to create test files
    function New-TestFile {
        param(
            [string]$Path,
            [int]$Rows,
            [switch]$Csv,
            [System.Text.Encoding]$Encoding = [System.Text.Encoding]::UTF8
        )
        $lines = [System.Collections.ArrayList]@()
        $columns = 40
        if ($Csv) {
            [void]$lines.add( (1..$columns | ForEach-Object { "Header$_" }) -join "," )
            for ($i=1; $i -le $Rows; $i++) {
                [void]$lines.add( "$i,$( (1..($columns-1) | ForEach-Object { "Value$_" }) -join "," )" )
            }
        } else {
            for ($i=1; $i -le $Rows; $i++) {
                [void]$lines.add( "Line $i" )
            }
        }
        [System.IO.File]::WriteAllLines($Path, $lines, $Encoding)
    }

    $TestFiles = @(
        @{ Path = "$PSScriptRoot/test100.csv"; Rows = 100; Csv = $true },
        @{ Path = "$PSScriptRoot/test10000.csv"; Rows = 10000; Csv = $true },
        @{ Path = "$PSScriptRoot/test100000.csv"; Rows = 100000; Csv = $true },
        @{ Path = "$PSScriptRoot/test100.txt"; Rows = 100; Csv = $false },
        @{ Path = "$PSScriptRoot/test10000.txt"; Rows = 10000; Csv = $false },
        @{ Path = "$PSScriptRoot/test100000.txt"; Rows = 100000; Csv = $false }
    )

    foreach ($file in $TestFiles) {
        New-TestFile -Path $file.Path -Rows $file.Rows -Csv:($file.Csv)
    }

}

BeforeAll {

    # .env nur laden, wenn nicht in CI
    #if (-not $env:CI) {
    #    . "$PSScriptRoot/Load-Env.ps1"
    #}

    #$baseUrl = $env:API_BASE_URL
    #$token   = $env:API_TOKEN

    # Import the module
    Import-Module $PSScriptRoot/../"MeasureRows" -Force

}

Describe 'MeasureRows' -ForEach $TestFiles {

    Context "File: $($Path)" {
        It "Counts all rows correctly" {
            If ( $Csv ) {
                # CSV files have a header row
                $expected = $Rows + 1
            } else {
                $expected = $Rows
            }
            Measure-Row -Path $Path | Should -Be $expected
        }
        if ($Csv) {
            It "Counts rows correctly with -SkipFirstRow" {
                Measure-Row -Path $Path -SkipFirstRow | Should -Be $Rows
            }
        }
        It "Works with ASCII encoding" {
            If ( $Csv ) {
                # CSV files have a header row
                $expected = $Rows + 1
            } else {
                $expected = $Rows
            }
            Measure-Row -Path $Path -Encoding ([System.Text.Encoding]::ASCII) | Should -Be $expected
        }
        It "Works with UTF8 encoding" {
            If ( $Csv ) {
                # CSV files have a header row
                $expected = $Rows + 1
            } else {
                $expected = $Rows
            }
            Measure-Row -Path $Path -Encoding ([System.Text.Encoding]::UTF8) | Should -Be $expected
        }
        It "Returns a [long] type" {
            $result = Measure-Row -Path $Path
            $result.GetType().Name | Should -Be 'Int64'
        }
        It "Performance: completes under 2 seconds for up to 100000 rows" {
            $sw = [System.Diagnostics.Stopwatch]::StartNew()
            Measure-Row -Path $Path | Out-Null
            $sw.Stop()
            $sw.Elapsed.TotalSeconds | Should -BeLessThan 2
        }
    }



}

Describe 'MeasureRows error handling' {

    Context "Error handling" {
        It "Throws error for non-existent file" {
            { Measure-Row -Path "$PSScriptRoot/doesnotexist.txt" } | Should -Throw
        }
        It "Throws error for one non-existent file" {
            { "$PSScriptRoot/test10.csv", "$PSScriptRoot/test999.csv" | Measure-Row -SkipFirstRow } | Should -Throw
        }
    }

}

Describe 'MeasureRows pipeline input' {

    Context "Pipeline input" {
        It "Counts rows from pipeline input" {
            $result = "$PSScriptRoot/test100.csv" | Measure-Row
            $result | Should -Be 101
        }
        It "Counts rows from pipeline input with -SkipFirstRow" {
            $result = "$PSScriptRoot/test100.csv" | Measure-Row -SkipFirstRow
            $result | Should -Be 100
        }
        It "Counts multiple files rows from pipeline input with -SkipFirstRow" {
            $result = "$PSScriptRoot/test100.csv", "$PSScriptRoot/test10000.csv" | Measure-Row -SkipFirstRow
            $result | Should -Be 10100
        }
    }

}

AfterAll {
    Remove-Module "MeasureRows" -Force
    "test*.csv","test*.txt" | ForEach-Object {
        Get-ChildItem $PSScriptRoot -Filter $_ | ForEach-Object {
            #Write-Host "Removing test file: $($_.FullName)"
            Remove-Item $_.FullName -Force -ErrorAction SilentlyContinue
        }
    }
}