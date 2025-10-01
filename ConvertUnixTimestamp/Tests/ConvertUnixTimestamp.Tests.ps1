BeforeAll {
    Import-Module "$PSScriptRoot/../ConvertUnixTimestamp" -Force
}

Describe "ConvertFrom-UnixTime" {

    It "Datetime comparison by different timezones" {
        $utcNow = [datetime]::UtcNow
        write-verbose $utcNow.ToString("yyyy-MM-ddTHH:mm:ss") -verbose
        $utcTZ = [System.TimeZoneInfo]::FindSystemTimeZoneById("UTC")
        $cetTZ = [System.TimeZoneInfo]::FindSystemTimeZoneById("Central European Standard Time")
        #$currentDateTime = [System.TimeZoneInfo]::ConvertTimeFromUtc($utcNow, $timezone)
        $currentDateTime = [System.TimeZoneInfo]::ConvertTime($utcNow, $utcTZ, $cetTZ)
        write-verbose $currentDateTime.ToString("yyyy-MM-ddTHH:mm:ss") -verbose
        write-verbose $currentDateTime.ToString("yyyy-MM-ddTHH:mm:ss").ToUniversalTime() -verbose
        $cetUnix = Get-Unixtime -Timestamp $currentDateTime
        $utcUnix = Get-Unixtime -Timestamp $utcNow
        write-verbose $cetUnix -verbose
        write-verbose $utcUnix -verbose
        $utcUnix | Should -Be $cetUnix
    }

    It "Convert Now to unix timestamp and back and compare" {
        $now = [datetime]::now
        $unixNow = Get-Unixtime -Timestamp $now
        $nowReconverted = ConvertFrom-UnixTime -Unixtime $unixNow
        $nowReconverted.ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ss") | Should -Be $now.ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ss") #10. June 2020 07:44:50
    }

    It "Convert Now to unix timestamp and back and compare with milliseconds" {
        $now = [datetime]::now
        $unixNow = Get-Unixtime -Timestamp $now -InMilliseconds
        $nowReconverted = ConvertFrom-UnixTime -Unixtime $unixNow -InMilliseconds
        $nowReconverted.ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ss.fff") | Should -Be $now.ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ss.fff") #10. June 2020 07:44:50
    }

    It "Converts a unix timestamp (seconds) to UTC DateTime" {
        $result = ConvertFrom-UnixTime -Unixtime 1591775090
        $result | Should -BeOfType 'datetime'
        $result.Kind | Should -Be 'Utc'
        $result.ToString("yyyy-MM-ddTHH:mm:ss") | Should -Be "2020-06-10T07:44:50" #10. June 2020 07:44:50
    }

    It "Converts a unix timestamp (seconds) to local DateTime" {
        $result = ConvertFrom-UnixTime -Unixtime 1591775090 -ConvertToLocalTimezone
        $result | Should -BeOfType 'datetime'
        $result.Kind | Should -Be 'Local'
        # The exact time will depend on the local timezone, so just check it's not UTC
        $result.Kind | Should -Not -Be 'Utc'
    }

    It "Converts a unix timestamp (milliseconds) to UTC DateTime" {
        $result = ConvertFrom-UnixTime -Unixtime 1591775146091 -InMilliseconds
        $result | Should -BeOfType 'datetime'
        $result.Kind | Should -Be 'Utc'
        $result.ToString("yyyy-MM-ddTHH:mm:ss.fff") | Should -Be "2020-06-10T07:45:46.091"
    }

    It "Supports pipeline input" {
        $result = 1591775090 | ConvertFrom-UnixTime
        $result | Should -BeOfType 'datetime'
        $result.ToString("yyyy-MM-ddTHH:mm:ss") | Should -Be "2020-06-10T07:44:50"
    }

    It "Returns correct ISO 8601 string" {
        $result = ConvertFrom-UnixTime -Unixtime 1591775090
        $iso = $result.ToString("yyyy-MM-ddTHH:mm:ssK")
        $iso | Should -Match "^2020-06-10T07:44:50"
    }

}


Describe "Get-Unixtime" {

    It "Returns the current unix timestamp (seconds)" {
        $now = Get-Date
        $result = Get-Unixtime -Timestamp $now
        $expected = [int][double]::Parse((Get-Date $now.ToUniversalTime() -UFormat %s))
        $result | Should -Be $expected
    }

    It "Returns the current unix timestamp (milliseconds)" {
        $now = Get-Date
        $result = Get-Unixtime -Timestamp $now -InMilliseconds
        $expected = [int][double]::Parse((Get-Date $now.ToUniversalTime() -UFormat %s)) * 1000 + $now.Millisecond
        $result | Should -Be $expected
    }

    It "Returns a unix timestamp for a specific date" {
        $dt = Get-Date "2020-06-10T13:44:50Z"
        $result = Get-Unixtime -Timestamp $dt
        $result | Should -Be 1591796690
    }

    It "Returns a unix timestamp for a specific date in milliseconds" {
        $dt = Get-Date "2020-06-10T13:44:50.123Z"
        $result = Get-Unixtime -Timestamp $dt -InMilliseconds
        $result | Should -Be 1591796690123
    }

    It "Supports pipeline input" {
        $dt = Get-Date "2020-06-10T13:44:50Z"
        $result = $dt | Get-Unixtime
        $result | Should -Be 1591796690
    }
    
}