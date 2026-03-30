# ---------------------------------------------------------------------------
# DuckDB tests
# All tests use the in-memory DuckDB connection that is auto-initialized
# when the SqlPipeline module is imported.  The entire Describe block is
# skipped when DuckDB.NET is not available in the current environment.
# ---------------------------------------------------------------------------

BeforeDiscovery {
    # Probe whether DuckDB is usable so we can skip gracefully
    $script:duckDBAvailable = $false
    try {
        Import-Module "$PSScriptRoot/../SqlPipeline" -Force #-ErrorAction Stop 2>$null
        Invoke-DuckDBQuery -Query "SELECT 1" -ErrorAction Stop
        $script:duckDBAvailable = $true
    } catch {
        $script:duckDBAvailable = $false
        # Windows PowerShell 5.1 requires older pinned versions of DuckDB.NET + System.Memory
        if ($PSVersionTable.PSEdition -eq 'Desktop' -or $PSVersionTable.PSVersion.Major -le 5) {
            Install-SqlPipeline -WindowsPowerShell
        } else {
            Install-SqlPipeline
        }
    }

    # Try again, if still false
    try {
        Invoke-DuckDBQuery -Query "SELECT 1" -ErrorAction Stop
        $script:duckDBAvailable = $true
    } catch {
        $script:duckDBAvailable = $false
    }

}

Describe "Invoke-DuckDBQuery" -Skip:(-not $script:duckDBAvailable) {

    AfterEach {
        Invoke-DuckDBQuery -Query "DROP TABLE IF EXISTS dq_test" -ErrorAction SilentlyContinue
    }

    It "Executes a CREATE TABLE without throwing" {
        { Invoke-DuckDBQuery -Query "CREATE TABLE IF NOT EXISTS dq_test (id INTEGER, val VARCHAR)" } | Should -Not -Throw
    }

    It "Executes an INSERT without throwing" {
        Invoke-DuckDBQuery -Query "CREATE TABLE IF NOT EXISTS dq_test (id INTEGER, val VARCHAR)"
        { Invoke-DuckDBQuery -Query "INSERT INTO dq_test VALUES (1, 'hello')" } | Should -Not -Throw
    }

    It "Executes a DROP TABLE without throwing" {
        Invoke-DuckDBQuery -Query "CREATE TABLE IF NOT EXISTS dq_test (id INTEGER)"
        { Invoke-DuckDBQuery -Query "DROP TABLE dq_test" } | Should -Not -Throw
    }

}


Describe "Get-DuckDBData" -Skip:(-not $script:duckDBAvailable) {

    BeforeAll {
        Invoke-DuckDBQuery -Query "CREATE TABLE IF NOT EXISTS gd_test (id INTEGER, name VARCHAR)"
        Invoke-DuckDBQuery -Query "INSERT INTO gd_test VALUES (1, 'Alice'), (2, 'Bob')"
    }

    AfterAll {
        Invoke-DuckDBQuery -Query "DROP TABLE IF EXISTS gd_test"
    }

    It "Returns a DataTable" {
        $result = Get-DuckDBData -Query "SELECT * FROM gd_test"
        Should -ActualValue $result -BeOfType [System.Data.DataTable]
    }

    It "Returns the correct number of rows" {
        $result = Get-DuckDBData -Query "SELECT * FROM gd_test"
        $result.Rows.Count | Should -Be 2
    }

    It "Returns expected column names" {
        $result = Get-DuckDBData -Query "SELECT * FROM gd_test"
        $result.Columns.ColumnName | Should -Contain "id"
        $result.Columns.ColumnName | Should -Contain "name"
    }

    It "Returns correct values" {
        $result = Get-DuckDBData -Query "SELECT name FROM gd_test ORDER BY id"
        $result.Rows[0]["name"] | Should -Be "Alice"
        $result.Rows[1]["name"] | Should -Be "Bob"
    }

    It "Returns empty DataTable for a query with no results" {
        $result = Get-DuckDBData -Query "SELECT * FROM gd_test WHERE id = 9999"
        Should -ActualValue $result -BeOfType [System.Data.DataTable]
        $result.Rows.Count | Should -Be 0
    }

}


Describe "Add-RowsToDuckDB" -Skip:(-not $script:duckDBAvailable) {

    AfterEach {
        Invoke-DuckDBQuery -Query "DROP TABLE IF EXISTS ard_people"     -ErrorAction SilentlyContinue
        Invoke-DuckDBQuery -Query "DROP TABLE IF EXISTS ard_upsert"     -ErrorAction SilentlyContinue
        Invoke-DuckDBQuery -Query "DROP TABLE IF EXISTS ard_schema"     -ErrorAction SilentlyContinue
        Invoke-DuckDBQuery -Query "DROP TABLE IF EXISTS ard_tx"         -ErrorAction SilentlyContinue
    }

    It "Inserts PSCustomObject rows" {
        $rows = @(
            [PSCustomObject]@{ Name = "Alice"; Age = 30 }
            [PSCustomObject]@{ Name = "Bob";   Age = 25 }
        )
        $rows | Add-RowsToDuckDB -TableName "ard_people"

        $result = Get-DuckDBData -Query "SELECT * FROM ard_people"
        $result.Rows.Count | Should -Be 2
        $result.Rows.Name  | Should -Contain "Alice"
        $result.Rows.Name  | Should -Contain "Bob"
    }

    It "Creates the table automatically on first insert" {
        [PSCustomObject]@{ Id = 1; Label = "auto" } | Add-RowsToDuckDB -TableName "ard_people"

        $result = Get-DuckDBData -Query "SELECT * FROM ard_people"
        $result.Rows.Count | Should -BeGreaterOrEqual 1
    }

    It "Inserts rows with -UseTransaction without throwing" {
        $rows = @(
            [PSCustomObject]@{ X = 1 }
            [PSCustomObject]@{ X = 2 }
        )
        { $rows | Add-RowsToDuckDB -TableName "ard_tx" -UseTransaction } | Should -Not -Throw
    }

    It "Performs UPSERT when PKColumns are specified" {
        # Insert initial row
        [PSCustomObject]@{ Id = 1; Val = "original" } | Add-RowsToDuckDB -TableName "ard_upsert" -PKColumns "Id"
        # Upsert same PK with updated value
        [PSCustomObject]@{ Id = 1; Val = "updated" }  | Add-RowsToDuckDB -TableName "ard_upsert" -PKColumns "Id"

        $result = Get-DuckDBData -Query "SELECT * FROM ard_upsert WHERE Id = 1"
        $result.Rows.Count | Should -Be 1
        $result.Rows[0]["Val"] | Should -Be "updated"
    }

    It "Evolves schema when new columns appear in later rows" {
        [PSCustomObject]@{ Col1 = "A" } | Add-RowsToDuckDB -TableName "ard_schema"
        [PSCustomObject]@{ Col1 = "B"; Col2 = "extra" } | Add-RowsToDuckDB -TableName "ard_schema"

        $result = Get-DuckDBData -Query "SELECT Col2 FROM ard_schema WHERE Col2 IS NOT NULL"
        $result.Rows.Count | Should -BeGreaterOrEqual 1
        $result.Rows[0]["Col2"] | Should -Be "extra"
    }

    It "Inserts multiple batches without data loss" {
        $rows = 1..25 | ForEach-Object { [PSCustomObject]@{ Num = $_ } }
        $rows | Add-RowsToDuckDB -TableName "ard_people" -BatchSize 10

        $result = Get-DuckDBData -Query "SELECT COUNT(*) AS cnt FROM ard_people"
        [int]$result.Rows[0]["cnt"] | Should -Be 25
    }

}


Describe "Set-LoadMetadata and Get-LastLoadTimestamp" -Skip:(-not $script:duckDBAvailable) {

    AfterEach {
        # Clean up metadata rows written by these tests
        Invoke-DuckDBQuery -Query "DELETE FROM _load_metadata WHERE table_name LIKE 'meta_%'" -ErrorAction SilentlyContinue
    }

    It "Set-LoadMetadata does not throw" {
        { Set-LoadMetadata -TableName "meta_orders" -RowsLoaded 100 } | Should -Not -Throw
    }

    It "Get-LastLoadTimestamp returns 2000-01-01 before any load is recorded" {
        $ts = Get-LastLoadTimestamp -TableName "meta_fresh_$(Get-Random)"
        $ts | Should -Be ([datetime]"2000-01-01")
    }

    It "Get-LastLoadTimestamp returns the timestamp written by Set-LoadMetadata" {
        Set-LoadMetadata -TableName "meta_orders" -RowsLoaded 42 -Status "success"
        $ts = Get-LastLoadTimestamp -TableName "meta_orders"
        $ts | Should -BeGreaterThan ([datetime]"2000-01-01")
    }

    It "Set-LoadMetadata stores the correct row count" {
        Set-LoadMetadata -TableName "meta_counts" -RowsLoaded 999
        $result = Get-DuckDBData -Query "SELECT rows_loaded FROM _load_metadata WHERE table_name = 'meta_counts'"
        [int]$result.Rows[0]["rows_loaded"] | Should -Be 999
    }

    It "Set-LoadMetadata stores the status correctly" {
        Set-LoadMetadata -TableName "meta_status" -RowsLoaded 0 -Status "error" -ErrorMessage "Test error"
        $result = Get-DuckDBData -Query "SELECT status, error_msg FROM _load_metadata WHERE table_name = 'meta_status'"
        $result.Rows[0]["status"]    | Should -Be "error"
        $result.Rows[0]["error_msg"] | Should -Be "Test error"
    }

    It "Set-LoadMetadata upserts on second call for same table" {
        Set-LoadMetadata -TableName "meta_upsert" -RowsLoaded 10
        Set-LoadMetadata -TableName "meta_upsert" -RowsLoaded 20

        $result = Get-DuckDBData -Query "SELECT rows_loaded FROM _load_metadata WHERE table_name = 'meta_upsert'"
        $result.Rows.Count | Should -Be 1
        [int]$result.Rows[0]["rows_loaded"] | Should -Be 20
    }

}


Describe "Initialize-SQLPipeline and Close-SqlPipeline" -Skip:(-not $script:duckDBAvailable) {

    BeforeAll {
        $script:dbPath = Join-Path ([System.IO.Path]::GetTempPath()) "pester_duck_$(Get-Random).db"
    }

    AfterAll {
        Remove-Item $script:dbPath -Force -ErrorAction SilentlyContinue
    }

    It "Initialize-SQLPipeline returns a DuckDB connection object" {
        $conn = Initialize-SQLPipeline -DbPath $script:dbPath
        $conn | Should -Not -BeNullOrEmpty
        $conn.GetType().Name | Should -Be "DuckDBConnection"
        Close-SqlPipeline -Connection $conn
    }

    It "Creates the database file on disk" {
        $filePath = Join-Path ([System.IO.Path]::GetTempPath()) "pester_duck_file_$(Get-Random).db"
        $conn = Initialize-SQLPipeline -DbPath $filePath
        Test-Path $filePath | Should -Be $true
        Close-SqlPipeline -Connection $conn
        Remove-Item $filePath -Force -ErrorAction SilentlyContinue
    }

    It "Connection state is Open after Initialize-SQLPipeline" {
        $filePath = Join-Path ([System.IO.Path]::GetTempPath()) "pester_duck_open_$(Get-Random).db"
        $conn = Initialize-SQLPipeline -DbPath $filePath
        $conn.State | Should -Be "Open"
        Close-SqlPipeline -Connection $conn
        Remove-Item $filePath -Force -ErrorAction SilentlyContinue
    }

    It "Close-SqlPipeline closes the connection without throwing" {
        $filePath = Join-Path ([System.IO.Path]::GetTempPath()) "pester_duck_close_$(Get-Random).db"
        $conn = Initialize-SQLPipeline -DbPath $filePath
        { Close-SqlPipeline -Connection $conn } | Should -Not -Throw
        Remove-Item $filePath -Force -ErrorAction SilentlyContinue
    }

    It "File-based connection persists data across reconnect" {
        $filePath = Join-Path ([System.IO.Path]::GetTempPath()) "pester_duck_persist_$(Get-Random).db"

        $conn1 = Initialize-SQLPipeline -DbPath $filePath
        [PSCustomObject]@{ Id = 42; Label = "persist" } | Add-RowsToDuckDB -Connection $conn1 -TableName "persist_test"
        Close-SqlPipeline -Connection $conn1

        $conn2 = Initialize-SQLPipeline -DbPath $filePath
        $result = Get-DuckDBData -Connection $conn2 -Query "SELECT * FROM persist_test"
        Close-SqlPipeline -Connection $conn2

        $result.Rows.Count | Should -Be 1
        $result.Rows[0]["Id"] | Should -Be 42

        Remove-Item $filePath -Force -ErrorAction SilentlyContinue
    }

}


Describe "Export-DuckDBToParquet" -Skip:(-not $script:duckDBAvailable) {

    BeforeAll {
        Invoke-DuckDBQuery -Query "CREATE TABLE IF NOT EXISTS parquet_src (id INTEGER, val VARCHAR)"
        Invoke-DuckDBQuery -Query "INSERT INTO parquet_src VALUES (1,'a'), (2,'b'), (3,'c')"
        $script:parquetDir  = Join-Path ([System.IO.Path]::GetTempPath()) "pester_parquet_$(Get-Random)"
        $script:parquetFile = Join-Path $script:parquetDir "output.parquet"
    }

    AfterAll {
        Invoke-DuckDBQuery -Query "DROP TABLE IF EXISTS parquet_src"
        Remove-Item $script:parquetDir -Recurse -Force -ErrorAction SilentlyContinue
    }

    It "Creates the output file without throwing" {
        { Export-DuckDBToParquet -TableName "parquet_src" -OutputPath $script:parquetFile } | Should -Not -Throw
        Test-Path $script:parquetFile | Should -Be $true
    }

    It "Creates output directory automatically when it does not exist" {
        $newFile = Join-Path ([System.IO.Path]::GetTempPath()) "pester_parquet_newdir_$(Get-Random)/out.parquet"
        Export-DuckDBToParquet -TableName "parquet_src" -OutputPath $newFile
        Test-Path $newFile | Should -Be $true
        Remove-Item (Split-Path $newFile -Parent) -Recurse -Force -ErrorAction SilentlyContinue
    }

    It "Accepts SNAPPY compression without throwing" {
        $f = Join-Path $script:parquetDir "snappy.parquet"
        { Export-DuckDBToParquet -TableName "parquet_src" -OutputPath $f -Compression SNAPPY } | Should -Not -Throw
    }

    It "Accepts GZIP compression without throwing" {
        $f = Join-Path $script:parquetDir "gzip.parquet"
        { Export-DuckDBToParquet -TableName "parquet_src" -OutputPath $f -Compression GZIP } | Should -Not -Throw
    }

    It "Re-imports the exported Parquet file via DuckDB" {
        $data = Get-DuckDBData -Query "SELECT COUNT(*) AS cnt FROM read_parquet('$($script:parquetFile)')"
        [int]$data.Rows[0]["cnt"] | Should -Be 3
    }

}
