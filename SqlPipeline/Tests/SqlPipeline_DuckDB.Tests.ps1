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
        # Re-import so the psm1 re-runs and creates $Script:DefaultConnection
        # with the newly installed packages.
        Import-Module "$PSScriptRoot/../SqlPipeline" -Force
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
        Invoke-DuckDBQuery -Query "DROP TABLE IF EXISTS ard_result"     -ErrorAction SilentlyContinue
        Invoke-DuckDBQuery -Query "DROP TABLE IF EXISTS ard_multi_pk"   -ErrorAction SilentlyContinue
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

    # ---------------------------------------------------------------------------
    # Result object (RowsInserted / RowsUpdated / RowsTotal)
    # ---------------------------------------------------------------------------

    It "Returns a result object with TableName, RowsInserted, RowsUpdated and RowsTotal properties" {
        $result = [PSCustomObject]@{ Id = 1; Val = "a" } | Add-RowsToDuckDB -TableName "ard_result" -PKColumns "Id"
        $result                                   | Should -Not -BeNullOrEmpty
        $result.PSObject.Properties.Name          | Should -Contain "TableName"
        $result.PSObject.Properties.Name          | Should -Contain "RowsInserted"
        $result.PSObject.Properties.Name          | Should -Contain "RowsUpdated"
        $result.PSObject.Properties.Name          | Should -Contain "RowsTotal"
    }

    It "TableName in result matches the target table" {
        $result = [PSCustomObject]@{ Id = 1 } | Add-RowsToDuckDB -TableName "ard_result"
        $result.TableName | Should -Be "ard_result"
    }

    It "Reports all rows as inserts and zero updates on plain INSERT (no PKColumns)" {
        $rows = @(
            [PSCustomObject]@{ Id = 1; Val = "a" }
            [PSCustomObject]@{ Id = 2; Val = "b" }
            [PSCustomObject]@{ Id = 3; Val = "c" }
        )
        $result = $rows | Add-RowsToDuckDB -TableName "ard_result"
        $result.RowsInserted | Should -Be 3
        $result.RowsUpdated  | Should -Be 0
        $result.RowsTotal    | Should -Be 3
    }

    It "Reports all rows as inserts and zero updates on first UPSERT load" {
        $rows = @(
            [PSCustomObject]@{ Id = 1; Val = "first" }
            [PSCustomObject]@{ Id = 2; Val = "first" }
        )
        $result = $rows | Add-RowsToDuckDB -TableName "ard_upsert" -PKColumns "Id"
        $result.RowsInserted | Should -Be 2
        $result.RowsUpdated  | Should -Be 0
        $result.RowsTotal    | Should -Be 2
    }

    It "Reports all rows as updates and zero inserts when every PK already exists" {
        @(
            [PSCustomObject]@{ Id = 1; Val = "original" }
            [PSCustomObject]@{ Id = 2; Val = "original" }
        ) | Add-RowsToDuckDB -TableName "ard_upsert" -PKColumns "Id" | Out-Null

        $result = @(
            [PSCustomObject]@{ Id = 1; Val = "updated" }
            [PSCustomObject]@{ Id = 2; Val = "updated" }
        ) | Add-RowsToDuckDB -TableName "ard_upsert" -PKColumns "Id"

        $result.RowsInserted | Should -Be 0
        $result.RowsUpdated  | Should -Be 2
        $result.RowsTotal    | Should -Be 2
    }

    It "Reports correct split when some rows are inserts and some are updates" {
        @(
            [PSCustomObject]@{ Id = 1; Val = "original" }
            [PSCustomObject]@{ Id = 2; Val = "original" }
        ) | Add-RowsToDuckDB -TableName "ard_upsert" -PKColumns "Id" | Out-Null

        $result = @(
            [PSCustomObject]@{ Id = 2; Val = "updated" }   # existing -> update
            [PSCustomObject]@{ Id = 3; Val = "new" }       # new -> insert
            [PSCustomObject]@{ Id = 4; Val = "new" }       # new -> insert
        ) | Add-RowsToDuckDB -TableName "ard_upsert" -PKColumns "Id"

        $result.RowsInserted | Should -Be 2
        $result.RowsUpdated  | Should -Be 1
        $result.RowsTotal    | Should -Be 3
    }

    It "Accumulates insert counts correctly across multiple batches" {
        $rows = 1..25 | ForEach-Object { [PSCustomObject]@{ Num = $_ } }
        $result = $rows | Add-RowsToDuckDB -TableName "ard_result" -BatchSize 10
        $result.RowsInserted | Should -Be 25
        $result.RowsUpdated  | Should -Be 0
        $result.RowsTotal    | Should -Be 25
    }

    It "Accumulates update counts correctly across multiple batches" {
        # Pre-load 25 rows
        1..25 | ForEach-Object { [PSCustomObject]@{ Id = $_; Val = "old" } } |
            Add-RowsToDuckDB -TableName "ard_upsert" -PKColumns "Id" | Out-Null

        # Re-load same 25 rows (all updates) in small batches
        $result = 1..25 | ForEach-Object { [PSCustomObject]@{ Id = $_; Val = "new" } } |
            Add-RowsToDuckDB -TableName "ard_upsert" -PKColumns "Id" -BatchSize 10

        $result.RowsInserted | Should -Be 0
        $result.RowsUpdated  | Should -Be 25
        $result.RowsTotal    | Should -Be 25
    }

    It "Reports correct counts with a composite (multi-column) primary key" {
        @(
            [PSCustomObject]@{ RegionId = 1; ProductId = 10; Sales = 100 }
            [PSCustomObject]@{ RegionId = 1; ProductId = 20; Sales = 200 }
        ) | Add-RowsToDuckDB -TableName "ard_multi_pk" -PKColumns "RegionId","ProductId" | Out-Null

        $result = @(
            [PSCustomObject]@{ RegionId = 1; ProductId = 10; Sales = 999 }   # update
            [PSCustomObject]@{ RegionId = 2; ProductId = 10; Sales = 50  }   # insert
        ) | Add-RowsToDuckDB -TableName "ard_multi_pk" -PKColumns "RegionId","ProductId"

        $result.RowsInserted | Should -Be 1
        $result.RowsUpdated  | Should -Be 1
        $result.RowsTotal    | Should -Be 2
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


Describe "Encryption (Initialize-SQLPipeline -EncryptionKey)" -Skip:(-not $script:duckDBAvailable) {

    BeforeAll {
        $script:encKey = 'pester-test-secret-key-32chars!!'
    }

    It "Returns a DuckDB connection object when -EncryptionKey is supplied" {
        $filePath = Join-Path ([System.IO.Path]::GetTempPath()) "pester_enc_$(Get-Random).db"
        $conn = Initialize-SQLPipeline -DbPath $filePath -EncryptionKey $script:encKey
        $conn | Should -Not -BeNullOrEmpty
        $conn.GetType().Name | Should -Be "DuckDBConnection"
        Close-SqlPipeline -Connection $conn
        Remove-Item $filePath     -Force -ErrorAction SilentlyContinue
        Remove-Item "$filePath.wal" -Force -ErrorAction SilentlyContinue
    }

    It "Creates the encrypted database file on disk" {
        $filePath = Join-Path ([System.IO.Path]::GetTempPath()) "pester_enc_$(Get-Random).db"
        $conn = Initialize-SQLPipeline -DbPath $filePath -EncryptionKey $script:encKey
        Test-Path $filePath | Should -Be $true
        Close-SqlPipeline -Connection $conn
        Remove-Item $filePath     -Force -ErrorAction SilentlyContinue
        Remove-Item "$filePath.wal" -Force -ErrorAction SilentlyContinue
    }

    It "Connection state is Open after Initialize-SQLPipeline with encryption" {
        $filePath = Join-Path ([System.IO.Path]::GetTempPath()) "pester_enc_$(Get-Random).db"
        $conn = Initialize-SQLPipeline -DbPath $filePath -EncryptionKey $script:encKey
        $conn.State | Should -Be "Open"
        Close-SqlPipeline -Connection $conn
        Remove-Item $filePath     -Force -ErrorAction SilentlyContinue
        Remove-Item "$filePath.wal" -Force -ErrorAction SilentlyContinue
    }

    It "Can write and read data from an encrypted database" {
        $filePath = Join-Path ([System.IO.Path]::GetTempPath()) "pester_enc_$(Get-Random).db"
        $conn = Initialize-SQLPipeline -DbPath $filePath -EncryptionKey $script:encKey
        [PSCustomObject]@{ Id = 1; Secret = "classified" } | Add-RowsToDuckDB -Connection $conn -TableName "enc_rw"
        $result = Get-DuckDBData -Connection $conn -Query "SELECT * FROM enc_rw"
        Close-SqlPipeline -Connection $conn
        Remove-Item $filePath     -Force -ErrorAction SilentlyContinue
        Remove-Item "$filePath.wal" -Force -ErrorAction SilentlyContinue

        $result.Rows.Count         | Should -Be 1
        $result.Rows[0]["Secret"]  | Should -Be "classified"
    }

    It "Encrypted data persists across reconnect with the correct key" {
        $filePath = Join-Path ([System.IO.Path]::GetTempPath()) "pester_enc_$(Get-Random).db"

        $conn1 = Initialize-SQLPipeline -DbPath $filePath -EncryptionKey $script:encKey
        [PSCustomObject]@{ Id = 42; Val = "encrypted-persist" } |
            Add-RowsToDuckDB -Connection $conn1 -TableName "enc_persist"
        Close-SqlPipeline -Connection $conn1

        $conn2  = Initialize-SQLPipeline -DbPath $filePath -EncryptionKey $script:encKey
        $result = Get-DuckDBData -Connection $conn2 -Query "SELECT * FROM enc_persist"
        Close-SqlPipeline -Connection $conn2
        Remove-Item $filePath     -Force -ErrorAction SilentlyContinue
        Remove-Item "$filePath.wal" -Force -ErrorAction SilentlyContinue

        $result.Rows.Count        | Should -Be 1
        $result.Rows[0]["Val"]    | Should -Be "encrypted-persist"
    }

    It "Opening an encrypted database with the wrong key throws" {
        $filePath = Join-Path ([System.IO.Path]::GetTempPath()) "pester_enc_$(Get-Random).db"
        $conn = Initialize-SQLPipeline -DbPath $filePath -EncryptionKey $script:encKey
        Close-SqlPipeline -Connection $conn

        { Initialize-SQLPipeline -DbPath $filePath -EncryptionKey "definitely-wrong-key" } | Should -Throw

        Remove-Item $filePath     -Force -ErrorAction SilentlyContinue
        Remove-Item "$filePath.wal" -Force -ErrorAction SilentlyContinue
    }

    It "Uses CTR cipher without throwing when -EncryptionCipher CTR is specified" {
        $filePath = Join-Path ([System.IO.Path]::GetTempPath()) "pester_enc_$(Get-Random).db"
        {
            $conn = Initialize-SQLPipeline -DbPath $filePath -EncryptionKey $script:encKey -EncryptionCipher CTR
            Close-SqlPipeline -Connection $conn
        } | Should -Not -Throw
        Remove-Item $filePath     -Force -ErrorAction SilentlyContinue
        Remove-Item "$filePath.wal" -Force -ErrorAction SilentlyContinue
    }

    It "CTR-encrypted data can be read back with the same key and cipher" {
        $filePath = Join-Path ([System.IO.Path]::GetTempPath()) "pester_enc_$(Get-Random).db"

        $conn1 = Initialize-SQLPipeline -DbPath $filePath -EncryptionKey $script:encKey -EncryptionCipher CTR
        [PSCustomObject]@{ Id = 1; Val = "ctr-value" } |
            Add-RowsToDuckDB -Connection $conn1 -TableName "enc_ctr"
        Close-SqlPipeline -Connection $conn1

        $conn2  = Initialize-SQLPipeline -DbPath $filePath -EncryptionKey $script:encKey -EncryptionCipher CTR
        $result = Get-DuckDBData -Connection $conn2 -Query "SELECT * FROM enc_ctr"
        Close-SqlPipeline -Connection $conn2
        Remove-Item $filePath     -Force -ErrorAction SilentlyContinue
        Remove-Item "$filePath.wal" -Force -ErrorAction SilentlyContinue

        $result.Rows.Count       | Should -Be 1
        $result.Rows[0]["Val"]   | Should -Be "ctr-value"
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


Describe "Get-DuckDBBestType - multi-row type inference" -Skip:(-not $script:duckDBAvailable) {
    # Get-DuckDBBestType is private, so all assertions go through Add-RowsToDuckDB
    # and the resulting DuckDB column type (read back via DESCRIBE).

    AfterEach {
        "typ_int","typ_double","typ_mixed","typ_null","typ_bool_int",
        "typ_bool_double","typ_incompat" | ForEach-Object {
            Invoke-DuckDBQuery -Query "DROP TABLE IF EXISTS $_" -ErrorAction SilentlyContinue
        }
    }

    It "Creates BIGINT column when all sampled rows are integer" {
        1..20 | ForEach-Object { [PSCustomObject]@{ Val = [int]$_ } } |
            Add-RowsToDuckDB -TableName "typ_int"

        $colType = (Get-DuckDBData -Query "DESCRIBE typ_int").Rows |
            Where-Object { $_["column_name"] -eq "Val" } | Select-Object -First 1
        $colType["column_type"] | Should -Be "BIGINT"
    }

    It "Creates DOUBLE column when all sampled rows are double" {
        1..20 | ForEach-Object { [PSCustomObject]@{ Val = [double]($_ + 0.1) } } |
            Add-RowsToDuckDB -TableName "typ_double"

        $colType = (Get-DuckDBData -Query "DESCRIBE typ_double").Rows |
            Where-Object { $_["column_name"] -eq "Val" } | Select-Object -First 1
        $colType["column_type"] | Should -Be "DOUBLE"
    }

    It "Widens to DOUBLE when first rows are int but later rows are double" {
        # Old single-row detection would create BIGINT; multi-row sampling creates DOUBLE.
        $rows = @(
            1..10  | ForEach-Object { [PSCustomObject]@{ Val = [int]$_ } }
            11..15 | ForEach-Object { [PSCustomObject]@{ Val = [double]($_ + 0.5) } }
        )
        $rows | Add-RowsToDuckDB -TableName "typ_mixed"

        $colType = (Get-DuckDBData -Query "DESCRIBE typ_mixed").Rows |
            Where-Object { $_["column_name"] -eq "Val" } | Select-Object -First 1
        $colType["column_type"] | Should -Be "DOUBLE"
    }

    It "Skips null values and still infers DOUBLE from the non-null rows" {
        $rows = @(
            1..5  | ForEach-Object { [PSCustomObject]@{ Val = $null } }
            6..15 | ForEach-Object { [PSCustomObject]@{ Val = [double]($_ * 1.5) } }
        )
        $rows | Add-RowsToDuckDB -TableName "typ_null"

        $colType = (Get-DuckDBData -Query "DESCRIBE typ_null").Rows |
            Where-Object { $_["column_name"] -eq "Val" } | Select-Object -First 1
        $colType["column_type"] | Should -Be "DOUBLE"
    }

    It "Widens BOOLEAN+int to BIGINT" {
        $rows = @(
            [PSCustomObject]@{ Flag = $true }
            [PSCustomObject]@{ Flag = $false }
            [PSCustomObject]@{ Flag = [int]42 }
        )
        $rows | Add-RowsToDuckDB -TableName "typ_bool_int"

        $colType = (Get-DuckDBData -Query "DESCRIBE typ_bool_int").Rows |
            Where-Object { $_["column_name"] -eq "Flag" } | Select-Object -First 1
        $colType["column_type"] | Should -Be "BIGINT"
    }

    It "Widens BOOLEAN+double to DOUBLE" {
        $rows = @(
            [PSCustomObject]@{ Flag = $true }
            [PSCustomObject]@{ Flag = [double]3.14 }
        )
        $rows | Add-RowsToDuckDB -TableName "typ_bool_double"

        $colType = (Get-DuckDBData -Query "DESCRIBE typ_bool_double").Rows |
            Where-Object { $_["column_name"] -eq "Flag" } | Select-Object -First 1
        $colType["column_type"] | Should -Be "DOUBLE"
    }

    It "Falls back to VARCHAR for incompatible types (string + int)" {
        $rows = @(
            [PSCustomObject]@{ Val = "hello" }
            [PSCustomObject]@{ Val = [int]42 }
        )
        $rows | Add-RowsToDuckDB -TableName "typ_incompat"

        $colType = (Get-DuckDBData -Query "DESCRIBE typ_incompat").Rows |
            Where-Object { $_["column_name"] -eq "Val" } | Select-Object -First 1
        $colType["column_type"] | Should -Be "VARCHAR"
    }

}


Describe "Write-DuckDBAppender - numeric type correctness (byte-reinterpretation fix)" -Skip:(-not $script:duckDBAvailable) {
    # Before the fix, DuckDB.NET's AppendValue(Int64) on a DOUBLE column reinterpreted
    # the 8 raw bytes of the long as a double, turning 15 into ~7.4e-323.

    AfterEach {
        "apr_int_in_double","apr_many_mixed","apr_double_in_bigint" | ForEach-Object {
            Invoke-DuckDBQuery -Query "DROP TABLE IF EXISTS $_" -ErrorAction SilentlyContinue
        }
    }

    It "Stores integer value correctly in a DOUBLE column (not as ~7.4e-323)" {
        # First row establishes the column as DOUBLE; second row supplies an int.
        $rows = @(
            [PSCustomObject]@{ Val = [double]1.5 }
            [PSCustomObject]@{ Val = [int]15 }
        )
        $rows | Add-RowsToDuckDB -TableName "apr_int_in_double"

        $result = Get-DuckDBData -Query "SELECT Val FROM apr_int_in_double ORDER BY Val"
        [double]$result.Rows[0]["Val"] | Should -Be 1.5
        [double]$result.Rows[1]["Val"] | Should -Be 15.0
    }

    It "Integer 15 in a DOUBLE column is greater than 10 (not a subnormal ~7.4e-323)" {
        $rows = @(
            [PSCustomObject]@{ Val = [double]1.0 }
            [PSCustomObject]@{ Val = [int]15 }
        )
        $rows | Add-RowsToDuckDB -TableName "apr_int_in_double"

        $result = Get-DuckDBData -Query "SELECT Val FROM apr_int_in_double WHERE Val > 10"
        $result.Rows.Count | Should -Be 1
        [double]$result.Rows[0]["Val"] | Should -Be 15.0
    }

    It "All mixed int/double values are stored correctly in a DOUBLE column" {
        # Multi-row sampling widens the column to DOUBLE from the start,
        # then the appender must still cast each int correctly.
        $rows = @(
            1..5  | ForEach-Object { [PSCustomObject]@{ Score = [double]($_ * 1.5) } }   # 1.5 3.0 4.5 6.0 7.5
            6..10 | ForEach-Object { [PSCustomObject]@{ Score = [int]($_ * 10) } }        # 60 70 80 90 100
        )
        $rows | Add-RowsToDuckDB -TableName "apr_many_mixed"

        $result = Get-DuckDBData -Query "SELECT Score FROM apr_many_mixed ORDER BY Score"
        $result.Rows.Count | Should -Be 10

        # All stored values must be sensible positive numbers (rules out subnormal garbage)
        foreach ($row in $result.Rows) {
            [double]$row["Score"] | Should -BeGreaterThan 0
            [double]$row["Score"] | Should -BeLessOrEqual 100
        }
    }

    It "Stores double value correctly in a BIGINT column" {
        # Column created as BIGINT; a double like 3.0 should be stored as 3 (truncated).
        $rows = @(
            [PSCustomObject]@{ Val = [int]10 }
            [PSCustomObject]@{ Val = [double]3.0 }
        )
        $rows | Add-RowsToDuckDB -TableName "apr_double_in_bigint"

        $result = Get-DuckDBData -Query "SELECT Val FROM apr_double_in_bigint ORDER BY Val"
        $result.Rows.Count | Should -Be 2
        [long]$result.Rows[0]["Val"] | Should -Be 3
        [long]$result.Rows[1]["Val"] | Should -Be 10
    }

}
