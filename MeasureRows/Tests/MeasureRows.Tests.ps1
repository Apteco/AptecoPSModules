
BeforeDiscovery {

    # Helper to create test files
    function New-TestFile {
        param(
            [string]$Path,
            [int]$Rows,
            [switch]$Csv,
            [System.Text.Encoding]$Encoding = [System.Text.Encoding]::UTF8
        )
        $lines = @()
        if ($Csv) {
            $lines += "Header1,Header2"
            for ($i=1; $i -le $Rows; $i++) {
                $lines += "$i,Value$i"
            }
        } else {
            for ($i=1; $i -le $Rows; $i++) {
                $lines += "Line $i"
            }
        }
        [System.IO.File]::WriteAllLines($Path, $lines, $Encoding)
    }

    $TestFiles = @(
        @{ Path = "$PSScriptRoot/test10.csv"; Rows = 10; Csv = $true },
        @{ Path = "$PSScriptRoot/test100.csv"; Rows = 100; Csv = $true },
        @{ Path = "$PSScriptRoot/test10000.csv"; Rows = 10000; Csv = $true },
        @{ Path = "$PSScriptRoot/test10.txt"; Rows = 10; Csv = $false },
        @{ Path = "$PSScriptRoot/test100.txt"; Rows = 100; Csv = $false },
        @{ Path = "$PSScriptRoot/test10000.txt"; Rows = 10000; Csv = $false }
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

AfterAll {
    Remove-Module "MeasureRows" -Force
    foreach ($file in $TestFiles) {
        Remove-Item $file.Path -ErrorAction SilentlyContinue
    }
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
            Measure-Rows -Path $Path | Should -Be $expected
        }
        if ($Csv) {
            It "Counts rows correctly with -SkipFirstRow" {
                Measure-Rows -Path $Path -SkipFirstRow | Should -Be $Rows
            }
        }
        It "Works with ASCII encoding" {
            If ( $Csv ) {
                # CSV files have a header row
                $expected = $Rows + 1
            } else {
                $expected = $Rows
            }
            Measure-Rows -Path $Path -Encoding ([System.Text.Encoding]::ASCII) | Should -Be $expected
        }
        It "Works with UTF8 encoding" {
            If ( $Csv ) {
                # CSV files have a header row
                $expected = $Rows + 1
            } else {
                $expected = $Rows
            }
            Measure-Rows -Path $Path -Encoding ([System.Text.Encoding]::UTF8) | Should -Be $expected
        }
        It "Returns a [long] type" {
            $result = Measure-Rows -Path $Path
            $result.GetType().Name | Should -Be 'Int64'
        }
        It "Performance: completes under 2 seconds for up to 10000 rows" {
            $sw = [System.Diagnostics.Stopwatch]::StartNew()
            Measure-Rows -Path $Path | Out-Null
            $sw.Stop()
            $sw.Elapsed.TotalSeconds | Should -BeLessThan 2
        }
    }

    
    
}

Describe 'MeasureRows error handling' {

    Context "Error handling" {
        It "Throws error for non-existent file" {
            { Measure-Rows -Path "$PSScriptRoot/doesnotexist.txt" } | Should -Throw
        }
    }

}

Describe 'MeasureRows pipeline input' {

    Context "Pipeline input" {
        It "Counts rows from pipeline input" {
            $result = "$PSScriptRoot/test10.csv" | Measure-Rows
            $result | Should -Be 11
        }
        It "Counts rows from pipeline input with -SkipFirstRow" {
            $result = "$PSScriptRoot/test10.csv" | Measure-Rows -SkipFirstRow
            $result | Should -Be 10
        }
    }

}