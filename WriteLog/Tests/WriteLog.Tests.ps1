BeforeAll {
    Import-Module "$PSScriptRoot/../WriteLog" -Force
}

Describe "Set-Logfile / Get-Logfile" {

    BeforeEach {
        $script:testLogfile = Join-Path -Path ([System.IO.Path]::GetTempPath()) -ChildPath "$([guid]::NewGuid()).log"
    }

    AfterEach {
        if (Test-Path $script:testLogfile) {
            Remove-Item $script:testLogfile -Force
        }
    }

    It "Sets a valid logfile path and Get-Logfile returns it" {
        Set-Logfile -Path $script:testLogfile
        Get-Logfile | Should -Be $script:testLogfile
    }

    It "Sets logfileOverride to true by default" {
        Set-Logfile -Path $script:testLogfile
        Get-LogfileOverride | Should -BeTrue
    }

    It "Sets logfileOverride to false when -DisableOverride is used" {
        Set-Logfile -Path $script:testLogfile -DisableOverride
        Get-LogfileOverride | Should -BeFalse
    }

    It "Get-Logfile returns a non-null value after module import" {
        # Module initialises logfile to a temp path on import
        Get-Logfile | Should -Not -BeNullOrEmpty
    }

    It "Get-Logfile returns a string" {
        Set-Logfile -Path $script:testLogfile
        Get-Logfile | Should -BeOfType [String]
    }

}

Describe "Get-LogfileOverride" {

    BeforeEach {
        $script:testLogfile = Join-Path -Path ([System.IO.Path]::GetTempPath()) -ChildPath "$([guid]::NewGuid()).log"
    }

    AfterEach {
        if (Test-Path $script:testLogfile) {
            Remove-Item $script:testLogfile -Force
        }
    }

    It "Returns false before any override has been set" {
        # Re-import to reset state
        Import-Module "$PSScriptRoot/../WriteLog" -Force
        Get-LogfileOverride | Should -BeFalse
    }

    It "Returns true after Set-Logfile is called without -DisableOverride" {
        Set-Logfile -Path $script:testLogfile
        Get-LogfileOverride | Should -BeTrue
    }

    It "Returns false after Set-Logfile is called with -DisableOverride" {
        Set-Logfile -Path $script:testLogfile -DisableOverride
        Get-LogfileOverride | Should -BeFalse
    }

}

Describe "Set-ProcessId / Get-ProcessId" {

    It "Sets the process ID and Get-ProcessId returns it" {
        $id = "test-process-id-123"
        Set-ProcessId -Id $id
        Get-ProcessId | Should -Be $id
    }

    It "Sets processIdOverride to true after Set-ProcessId" {
        Set-ProcessId -Id "any-id"
        Get-ProcessIdOverride | Should -BeTrue
    }

    It "Get-ProcessId returns a non-null value after module import" {
        Import-Module "$PSScriptRoot/../WriteLog" -Force
        Get-ProcessId | Should -Not -BeNullOrEmpty
    }

    It "Default process ID is a valid GUID" {
        Import-Module "$PSScriptRoot/../WriteLog" -Force
        $id = Get-ProcessId
        $parsed = [System.Guid]::Empty
        [System.Guid]::TryParse($id, [ref]$parsed) | Should -BeTrue
    }

}

Describe "Get-ProcessIdOverride" {

    It "Returns false before any override has been set" {
        Import-Module "$PSScriptRoot/../WriteLog" -Force
        Get-ProcessIdOverride | Should -BeFalse
    }

    It "Returns true after Set-ProcessId is called" {
        Set-ProcessId -Id "override-id"
        Get-ProcessIdOverride | Should -BeTrue
    }

}

Describe "Set-TimestampFormat / Get-TimestampFormat" {

    AfterEach {
        # Restore default
        Set-TimestampFormat -Format "yyyyMMddHHmmss"
    }

    It "Returns the default format after import" {
        Import-Module "$PSScriptRoot/../WriteLog" -Force
        Get-TimestampFormat | Should -Be "yyyyMMddHHmmss"
    }

    It "Sets a custom timestamp format and returns it" {
        Set-TimestampFormat -Format "yyyy-MM-dd HH:mm:ss"
        Get-TimestampFormat | Should -Be "yyyy-MM-dd HH:mm:ss"
    }

    It "Returns the format string from Set-TimestampFormat" {
        $result = Set-TimestampFormat -Format "dd/MM/yyyy"
        $result | Should -Be "dd/MM/yyyy"
    }

    It "Throws on an invalid format string" {
        { Set-TimestampFormat -Format "NOT_A_%VALID_FORMAT_@@@@" } | Should -Throw
    }

    It "Accepts ISO 8601 format" {
        { Set-TimestampFormat -Format "yyyy-MM-ddTHH:mm:ssZ" } | Should -Not -Throw
        Get-TimestampFormat | Should -Be "yyyy-MM-ddTHH:mm:ssZ"
    }

}

Describe "Set-LogFormat / Get-LogFormat" {

    AfterEach {
        Set-LogFormat -Format "TIMESTAMP`tPROCESSID`tSEVERITY`tMESSAGE"
    }

    It "Returns the default format after import" {
        Import-Module "$PSScriptRoot/../WriteLog" -Force
        Get-LogFormat | Should -Be "TIMESTAMP`tPROCESSID`tSEVERITY`tMESSAGE"
    }

    It "Sets a custom log format and returns it via Get-LogFormat" {
        Set-LogFormat -Format "TIMESTAMP MESSAGE"
        Get-LogFormat | Should -Be "TIMESTAMP MESSAGE"
    }

    It "Accepts a format with all supported tokens" {
        $fmt = "TIMESTAMP`tPROCESSID`tSEVERITY`tMESSAGE`tUSER`tMACHINE"
        Set-LogFormat -Format $fmt
        Get-LogFormat | Should -Be $fmt
    }

}

Describe "Write-Log" {

    BeforeEach {
        Import-Module "$PSScriptRoot/../WriteLog" -Force
        $script:testLogfile = Join-Path -Path ([System.IO.Path]::GetTempPath()) -ChildPath "$([guid]::NewGuid()).log"
        Set-Logfile -Path $script:testLogfile
    }

    AfterEach {
        if (Test-Path $script:testLogfile) {
            Remove-Item $script:testLogfile -Force
        }
    }

    It "Creates the logfile when a message is written" {
        Write-Log -Message "Hello World"
        Test-Path $script:testLogfile | Should -BeTrue
    }

    It "Writes the message content to the logfile" {
        Write-Log -Message "Hello World"
        $content = Get-Content -Path $script:testLogfile -Raw
        $content | Should -Match "Hello World"
    }

    It "Writes the severity INFO to the logfile" {
        Write-Log -Message "Info message" -Severity ([LogSeverity]::INFO)
        $content = Get-Content -Path $script:testLogfile -Raw
        $content | Should -Match "INFO"
    }

    It "Writes the severity WARNING to the logfile" {
        Write-Log -Message "Warning message" -Severity ([LogSeverity]::WARNING) -WriteToHostToo $false
        $content = Get-Content -Path $script:testLogfile -Raw
        $content | Should -Match "WARNING"
    }

    It "Writes the severity ERROR to the logfile" {
        Write-Log -Message "Error message" -Severity ([LogSeverity]::ERROR) -WriteToHostToo $false -ErrorAction SilentlyContinue
        $content = Get-Content -Path $script:testLogfile -Raw
        $content | Should -Match "ERROR"
    }

    It "Writes the severity VERBOSE to the logfile" {
        Write-Log -Message "Verbose message" -Severity ([LogSeverity]::VERBOSE)
        $content = Get-Content -Path $script:testLogfile -Raw
        $content | Should -Match "VERBOSE"
    }

    It "Supports pipeline input" {
        "Pipeline message" | Write-Log
        $content = Get-Content -Path $script:testLogfile -Raw
        $content | Should -Match "Pipeline message"
    }

    It "Writes multiple pipeline messages" {
        "First", "Second", "Third" | Write-Log
        $lines = Get-Content -Path $script:testLogfile
        $lines.Count | Should -Be 3
    }

    It "Includes the process ID in the log entry" {
        $pid = "my-test-pid"
        Set-ProcessId -Id $pid
        Write-Log -Message "Check PID"
        $content = Get-Content -Path $script:testLogfile -Raw
        $content | Should -Match $pid
    }

    It "Includes the timestamp in the log entry" {
        Write-Log -Message "Timestamp check"
        $content = Get-Content -Path $script:testLogfile -Raw
        # Default format is yyyyMMddHHmmss — 14 digits
        $content | Should -Match "\d{14}"
    }

    It "Appends multiple log entries to the same file" {
        Write-Log -Message "Line one"
        Write-Log -Message "Line two"
        $lines = Get-Content -Path $script:testLogfile
        $lines.Count | Should -Be 2
    }

    It "Writes to an additional logfile when one is configured" {
        $addLog = Join-Path -Path ([System.IO.Path]::GetTempPath()) -ChildPath "$([guid]::NewGuid()).log"
        try {
            Add-AdditionalLogfile -Path $addLog
            Write-Log -Message "Additional log test"
            $content = Get-Content -Path $addLog -Raw
            $content | Should -Match "Additional log test"
        } finally {
            if (Test-Path $addLog) { Remove-Item $addLog -Force }
        }
    }

    It "UtcTimestamp switch uses a UTC timestamp" {
        # Capture the local time and UTC time around the write
        $before = [datetime]::UtcNow.AddSeconds(-2)
        Write-Log -Message "UTC test" -UtcTimestamp
        $after = [datetime]::UtcNow.AddSeconds(2)
        $line = Get-Content -Path $script:testLogfile | Select-Object -First 1
        $timestampStr = ($line -split "`t")[0]
        $ts = [datetime]::ParseExact($timestampStr, "yyyyMMddHHmmss", $null)
        $ts | Should -BeGreaterOrEqual $before
        $ts | Should -BeLessOrEqual $after
    }

}

Describe "Add-AdditionalLogfile / Remove-AdditionalLogfile / Get-AdditionalLog" {

    BeforeEach {
        Import-Module "$PSScriptRoot/../WriteLog" -Force
        $script:addLog1 = Join-Path -Path ([System.IO.Path]::GetTempPath()) -ChildPath "$([guid]::NewGuid()).log"
        $script:addLog2 = Join-Path -Path ([System.IO.Path]::GetTempPath()) -ChildPath "$([guid]::NewGuid()).log"
    }

    AfterEach {
        foreach ($f in @($script:addLog1, $script:addLog2)) {
            if ($f -and (Test-Path $f)) { Remove-Item $f -Force }
        }
    }

    It "Returns an empty list before any additional logs are added" {
        Get-AdditionalLog | Should -BeNullOrEmpty
    }

    It "Adds an additional logfile and Get-AdditionalLog returns it" {
        Add-AdditionalLogfile -Path $script:addLog1
        $logs = Get-AdditionalLog
        $logs.Count | Should -Be 1
        $logs[0].Options.Path | Should -Be $script:addLog1
    }

    It "Auto-generates a name when none is provided" {
        Add-AdditionalLogfile -Path $script:addLog1
        $logs = Get-AdditionalLog
        $logs[0].Name | Should -Match "^Textfile_"
    }

    It "Uses the provided name when specified" {
        Add-AdditionalLogfile -Path $script:addLog1 -Name "MyCustomLog"
        $logs = Get-AdditionalLog
        $logs[0].Name | Should -Be "MyCustomLog"
    }

    It "Sets the type to 'textfile'" {
        Add-AdditionalLogfile -Path $script:addLog1
        $logs = Get-AdditionalLog
        $logs[0].Type | Should -Be "textfile"
    }

    It "Can add multiple additional logfiles" {
        Add-AdditionalLogfile -Path $script:addLog1 -Name "Log1"
        Add-AdditionalLogfile -Path $script:addLog2 -Name "Log2"
        $logs = Get-AdditionalLog
        $logs.Count | Should -Be 2
    }

    It "Removes an additional logfile by name" {
        Add-AdditionalLogfile -Path $script:addLog1 -Name "ToRemove"
        Remove-AdditionalLogfile -Name "ToRemove"
        $logs = Get-AdditionalLog
        $logs | Where-Object { $_.Name -eq "ToRemove" } | Should -BeNullOrEmpty
    }

    It "Removes an additional logfile by path" {
        Add-AdditionalLogfile -Path $script:addLog1 -Name "ByPath"
        Remove-AdditionalLogfile -Path $script:addLog1
        $logs = Get-AdditionalLog
        $logs | Where-Object { $_.Options.Path -eq $script:addLog1 } | Should -BeNullOrEmpty
    }

    It "Writes an error when removing a non-existent log by name" {
        { Remove-AdditionalLogfile -Name "DoesNotExist" -ErrorAction Stop } | Should -Throw
    }

    It "Auto-increments textfile names correctly" {
        Add-AdditionalLogfile -Path $script:addLog1
        Add-AdditionalLogfile -Path $script:addLog2
        $logs = Get-AdditionalLog
        $logs[0].Name | Should -Be "Textfile_1"
        $logs[1].Name | Should -Be "Textfile_2"
    }

}

Describe "Resize-Logfile" {

    BeforeEach {
        Import-Module "$PSScriptRoot/../WriteLog" -Force
        $script:testLogfile = Join-Path -Path ([System.IO.Path]::GetTempPath()) -ChildPath "$([guid]::NewGuid()).log"
        Set-Logfile -Path $script:testLogfile
    }

    AfterEach {
        if (Test-Path $script:testLogfile) {
            Remove-Item $script:testLogfile -Force
        }
    }

    It "Keeps only the specified number of rows" {
        1..10 | ForEach-Object { Write-Log -Message "Line $_" }
        Resize-Logfile -RowsToKeep 5
        $lines = Get-Content -Path $script:testLogfile
        $lines.Count | Should -Be 5
    }

    It "Keeps all rows when RowsToKeep exceeds the total line count" {
        1..3 | ForEach-Object { Write-Log -Message "Line $_" }
        Resize-Logfile -RowsToKeep 100
        $lines = Get-Content -Path $script:testLogfile
        $lines.Count | Should -Be 3
    }

    It "Retains the most recent lines" {
        1..5 | ForEach-Object { Write-Log -Message "Line $_" }
        Resize-Logfile -RowsToKeep 2
        $lines = Get-Content -Path $script:testLogfile
        $lines[-1] | Should -Match "Line 5"
    }

    It "Logfile still exists after resize" {
        1..5 | ForEach-Object { Write-Log -Message "Entry $_" }
        Resize-Logfile -RowsToKeep 3
        Test-Path $script:testLogfile | Should -BeTrue
    }

}
