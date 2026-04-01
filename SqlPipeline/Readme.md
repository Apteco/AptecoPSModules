# Introduction

Wrapper for [SimplySql](https://github.com/mithrandyr/SimplySql/) and DuckDB to allow pipeline input and set the parameters automatically and it accepts also PSCustomObject input. It supports all the supported databases from SimplySql, but examples here are made with SQLite.

> **Note:** To use DuckDB, run `Install-SqlPipeline` first to install the required dependencies.

# DuckDB Integration

The module includes a native DuckDB pipeline that works independently of SimplySql. An **in-memory DuckDB database is initialized automatically** when the module is imported — no setup required for quick analysis or temporary storage.

Current functionality:

- DuckDB connection management
- Automatic table creation from PSObject data
- Schema evolution (new fields via ALTER TABLE)
- Normalization of missing fields (columns no longer provided)
- Bulk insert via Appender (fast) and temporary CSV import (even faster)
- UPSERT via staging table + INSERT ON CONFLICT
- Metadata management (last load timestamp per table)


## Installation

Install the required DuckDB.NET NuGet packages into a `./lib` subfolder:

```PowerShell
# PowerShell 7+ (latest DuckDB.NET)
Install-SqlPipeline

# Windows PowerShell 5.1 (pinned compatible versions)
Install-SqlPipeline -WindowsPowerShell
```

## PowerShell Version Compatibility

| Feature | PowerShell 7+ | Windows PowerShell 5.1 |
|---|---|---|
| DuckDB.NET version | latest | 1.4.4 (maximum) |
| Extra dependencies | none | `System.Memory` 4.6.0 |

**Windows PowerShell 5.1** runs on .NET Framework 4.x, which is missing some APIs that newer DuckDB.NET versions require. Use the `-WindowsPowerShell` switch when installing on Windows PowerShell 5.1:

```PowerShell
Install-SqlPipeline -WindowsPowerShell
```

This installs:
- `DuckDB.NET.Bindings.Full` 1.4.4
- `DuckDB.NET.Data.Full` 1.4.4
- `System.Memory` 4.6.0 (required polyfill not included in .NET Framework)

## Quick Start (in-memory, no setup needed)

```PowerShell
Import-Module SqlPipeline

# Data is written to an in-memory DuckDB database automatically
Import-Csv '.\orders.csv' | Add-RowsToDuckDB -TableName 'orders' -PKColumns 'order_id' -Verbose

# Query back the data
Get-DuckDBData -Query "SELECT COUNT(*) AS total FROM orders"
```

## File-based Database

Call `Initialize-SQLPipeline` to switch from the default in-memory database to a persistent file. All subsequent DuckDB functions will use the file-based connection automatically.

```PowerShell
Import-Module SqlPipeline

Initialize-SQLPipeline -DbPath '.\pipeline.db'

Import-Csv '.\orders.csv' | Add-RowsToDuckDB -TableName 'orders' -PKColumns 'order_id' -UseTransaction -Verbose

Close-SqlPipeline
```

## Public Functions

### `Initialize-SQLPipeline`

Opens a persistent file-based DuckDB database and sets it as the default connection. Only needed when you want to persist data to a file — the in-memory database is initialized automatically on module import.

```PowerShell
# Switch to a file-based database
Initialize-SQLPipeline -DbPath '.\pipeline.db'

# With AES-256 encryption (requires DuckDB 1.4.0+)
$conn = Initialize-SQLPipeline -DbPath '.\pipeline.db' -EncryptionKey 'my-secret-key'
```

| Parameter | Type | Description |
|---|---|---|
| `DbPath` | string (mandatory) | Path to the `.db` file. Created if it does not exist. |
| `EncryptionKey` | string | Optional AES-256 encryption key. Encryption is applied via `ATTACH ... (ENCRYPTION_KEY '...')`. |
| `EncryptionCipher` | string | `GCM` (default, authenticated) or `CTR` (faster, no integrity check). Only used when `EncryptionKey` is set. |

Returns the `DuckDBConnection` object. Also sets `$Script:DefaultConnection` so all functions work without `-Connection`.

---

### `Add-RowsToDuckDB`

Inserts PSObjects into a DuckDB table via the PowerShell pipeline. Compatible with the `Add-RowsToSql` interface. Creates the table automatically on the first insert and evolves the schema when new columns appear.

```PowerShell
# Plain INSERT (in-memory, no connection needed)
Import-Csv '.\orders.csv' | Add-RowsToDuckDB -TableName 'orders'

# UPSERT with primary key
Import-Csv '.\orders.csv' | Add-RowsToDuckDB -TableName 'orders' -PKColumns 'order_id'

# Transaction-style batching for large datasets
Import-Csv '.\orders.csv' | Add-RowsToDuckDB -TableName 'orders' -PKColumns 'order_id' -UseTransaction

# Explicit connection
Import-Csv '.\orders.csv' | Add-RowsToDuckDB -Connection $conn -TableName 'orders'
```

| Parameter | Type | Description |
|---|---|---|
| `InputObject` | PSObject (pipeline) | Row to insert. |
| `Connection` | DuckDBConnection | Connection to use. Defaults to the module's default connection. |
| `TableName` | string (mandatory) | Target table name. Created automatically if it does not exist. |
| `PKColumns` | string[] | Primary key columns for UPSERT. Empty = plain INSERT. |
| `UseTransaction` | switch | Buffers all rows and writes via staging table (safer for large loads). |
| `BatchSize` | int | Rows per batch when not using `-UseTransaction`. Default: 10000. |

---

### `Get-DuckDBData`

Executes a SELECT query and returns a `DataTable`.

```PowerShell
# Using the default connection
Get-DuckDBData -Query "SELECT * FROM orders WHERE status = 'open'"

# With explicit connection
Get-DuckDBData -Connection $conn -Query "SELECT COUNT(*) AS cnt FROM orders"
```

| Parameter | Type | Description |
|---|---|---|
| `Connection` | DuckDBConnection | Connection to use. Defaults to the module's default connection. |
| `Query` | string (mandatory) | SQL SELECT statement to execute. |

---

### `Invoke-DuckDBQuery`

Executes a non-query SQL statement (CREATE, INSERT, ALTER, DROP, ...).

```PowerShell
Invoke-DuckDBQuery -Query "DELETE FROM orders WHERE status = 'cancelled'"
Invoke-DuckDBQuery -Query "ALTER TABLE orders ADD COLUMN discount DOUBLE"
```

| Parameter | Type | Description |
|---|---|---|
| `Connection` | DuckDBConnection | Connection to use. Defaults to the module's default connection. |
| `Query` | string (mandatory) | SQL statement to execute. |

---

### `Get-LastLoadTimestamp`

Returns the timestamp of the last successful load for a table. Returns `2000-01-01` if no previous load is recorded (signals a full load). Used for incremental loading patterns.

```PowerShell
$since = Get-LastLoadTimestamp -TableName 'orders'
$newOrders = Get-ApiData -ModifiedAfter $since
$newOrders | Add-RowsToDuckDB -TableName 'orders' -PKColumns 'order_id'
Set-LoadMetadata -TableName 'orders' -RowsLoaded $newOrders.Count
```

| Parameter | Type | Description |
|---|---|---|
| `Connection` | DuckDBConnection | Connection to use. Defaults to the module's default connection. |
| `TableName` | string (mandatory) | Table name to look up. |

---

### `Set-LoadMetadata`

Stores the timestamp, row count, and status of a completed load in the `_load_metadata` table. Used together with `Get-LastLoadTimestamp` to implement incremental loads.

```PowerShell
Set-LoadMetadata -TableName 'orders' -RowsLoaded 1500
Set-LoadMetadata -TableName 'orders' -RowsLoaded 0 -Status 'error' -ErrorMessage 'API timeout'
```

| Parameter | Type | Description |
|---|---|---|
| `Connection` | DuckDBConnection | Connection to use. Defaults to the module's default connection. |
| `TableName` | string (mandatory) | Name of the loaded table. |
| `RowsLoaded` | int (mandatory) | Number of rows loaded. |
| `Status` | string | `'success'` (default) or `'error'`. |
| `ErrorMessage` | string | Optional error description when `Status = 'error'`. |

---

### `Export-DuckDBToParquet`

Exports a DuckDB table to a Parquet file. The output directory is created automatically if it does not exist.

```PowerShell
Export-DuckDBToParquet -TableName 'orders' -OutputPath '.\export\orders.parquet'
Export-DuckDBToParquet -TableName 'orders' -OutputPath '.\export\orders.parquet' -Compression ZSTD
```

| Parameter | Type | Description |
|---|---|---|
| `Connection` | DuckDBConnection | Connection to use. Defaults to the module's default connection. |
| `TableName` | string (mandatory) | Table to export. |
| `OutputPath` | string (mandatory) | Path for the output `.parquet` file. |
| `Compression` | string | `SNAPPY`, `ZSTD` (default), `GZIP`, or `NONE`. |

---

### `Close-SqlPipeline`

Closes a DuckDB connection cleanly. Use this when working with file-based databases opened via `Initialize-SQLPipeline`.

```PowerShell
# Close an explicit connection
Close-SqlPipeline -Connection $conn

# Close the default connection
Close-SqlPipeline
```

| Parameter | Type | Description |
|---|---|---|
| `Connection` | DuckDBConnection (mandatory) | The connection to close. |

---

## Full Incremental Load Example

```PowerShell
Import-Module SqlPipeline

# Switch to a persistent database
Initialize-SQLPipeline -DbPath '.\crm.db'

# Find out when we last loaded successfully
$since = Get-LastLoadTimestamp -TableName 'contacts'

# Fetch only records modified since the last load
$contacts = Invoke-RestMethod "https://api.crm.example/contacts?modifiedAfter=$since"

# Upsert into DuckDB
$contacts.items | Add-RowsToDuckDB -TableName 'contacts' -PKColumns 'id' -UseTransaction -Verbose

# Record success
Set-LoadMetadata -TableName 'contacts' -RowsLoaded $contacts.items.Count

# Export for downstream consumption
Export-DuckDBToParquet -TableName 'contacts' -OutputPath '.\export\contacts.parquet'

Close-SqlPipeline
```

## Database Encryption

SqlPipeline supports AES-256 encrypted DuckDB databases (requires DuckDB 1.4.0 or later). Pass `-EncryptionKey` to `Initialize-SQLPipeline` — everything else works identically to an unencrypted database.

```PowerShell
Import-Module SqlPipeline

# Open (or create) an encrypted file-based database
Initialize-SQLPipeline -DbPath '.\pipeline.db' -EncryptionKey 'my-secret-key'

Import-Csv '.\orders.csv' | Add-RowsToDuckDB -TableName 'orders' -PKColumns 'order_id'

Close-SqlPipeline
```

By default AES-GCM-256 is used (authenticated encryption). To use AES-CTR-256 instead (faster, no integrity check):

```PowerShell
Initialize-SQLPipeline -DbPath '.\pipeline.db' -EncryptionKey 'my-secret-key' -EncryptionCipher CTR
```

> **Note:** DuckDB 1.4.1+ requires the `httpfs` extension (OpenSSL) for writes to encrypted databases. SqlPipeline installs and loads it automatically when `-EncryptionKey` is provided.

### Migrating an Existing Unencrypted Database to an Encrypted One

The module's default in-memory connection can be used as a bridge to attach both the source and destination databases simultaneously and copy all tables in one step.

```PowerShell
Import-Module SqlPipeline

# DuckDB 1.4.1+ requires httpfs (OpenSSL) for writes to encrypted databases.
Invoke-DuckDBQuery -Query "INSTALL httpfs"
Invoke-DuckDBQuery -Query "LOAD httpfs"

# Attach the existing unencrypted database as the source.
Invoke-DuckDBQuery -Query "ATTACH '.\pipeline.db' AS src"

# Attach the new encrypted database as the destination (created automatically).
Invoke-DuckDBQuery -Query "ATTACH '.\pipeline_encrypted.db' AS dst (ENCRYPTION_KEY 'my-secret-key', ENCRYPTION_CIPHER 'GCM')"

# Copy all tables and their data from source to destination in one step.
Invoke-DuckDBQuery -Query "COPY FROM DATABASE src TO dst"

# Detach both databases cleanly.
Invoke-DuckDBQuery -Query "DETACH src"
Invoke-DuckDBQuery -Query "DETACH dst"
```

After verifying the encrypted database works correctly, replace the original file:

```PowerShell
Remove-Item      '.\pipeline.db'
Rename-Item      '.\pipeline_encrypted.db' '.\pipeline.db'
```

From this point on open the database with `-EncryptionKey`:

```PowerShell
Initialize-SQLPipeline -DbPath '.\pipeline.db' -EncryptionKey 'my-secret-key'
```

---

# SimplySQL Integration

To use the SimplySQL integration that allows connections to SQLServer, sqlite, postgresql and more, follow these steps.

## Performance

Please think about using the `-UseTransaction` flag. E.g. for a Sqlite import and a file of around 45k rows you can see the difference here. I have measured it like in this command:

```PowerShell
Import-Module SqlPipeline, SimplySql
Open-SQLiteConnection -DataSource ".\db.sqlite"
Measure-Command {
    import-csv -Path '.ac_adressen.csv' -Encoding UTF8 -Delimiter "," | Add-RowsToSql -TableName "addresses" -UseTransaction -Verbose
}
Close-SqlConnection
```

And you can see the difference, it is around 10x times faster to use a transaction when inserting data

Type|Time
-|-
Without transaction|596s
With transaction|20s

You can influence the number of records per transaction via the `-CommitEvery` parameter where the default is 10.000.

Btw. opening a temporary in-memory database like

```PowerShell
Open-SQLiteConnection -DataSource ":memory:"
```

made my import then in 18 seconds, which is still a nice improvement!

I have imported another file with the size of 1.5GB and 300k rows in 216 seconds. Every line consists of columns with a total line length of (including tabs as delimiter).

## Examples

All the examples are done with SQLite, but are also valid for all other databases that are supported in SimplySql.

### Close the connection after everything is done

With the `-CloseConnection` you can close the connection automatically after the import is done:

```PowerShell
Open-SQLiteConnection -DataSource ":memory:"
import-csv -Path '.ac_adressen.csv' -Encoding UTF8 -Delimiter "," | Select-Object -first 100 | Add-RowsToSql -verbose -TableName "addresses" -UseTransaction -CloseConnection
```

So then `Test-SqlConnection` should be false

### Use the input data from csv and in further steps in pipeline

Use the `-PassThru` parameter switch to forward the input object to the next pipeline step, so this could be something like showing the first 100 records and output it in a table

```PowerShell
Open-SQLiteConnection -DataSource ".\addresses.sqlite"
import-csv -Path '.ac_adressen.csv' -Encoding UTF8 -Delimiter "," | Select-Object -first 100 | Add-RowsToSql -TableName "addresses" -PassThru | Out-GridView
```

## Using in-memory database

This is also supported with SQLite, which can be done through SimplySql. So just open the database connection like

```PowerShell
Open-SQLiteConnection -DataSource ":memory:"
```

and it will be automatically used

## Input objects directly

So you can create objects like you want and store them in the database like in here. This example shows a lot of different
use cases, so it can look like a bit mixed up, but shows you the flexibility.

```PowerShell

$psCustoms1 = @(
    [PSCustomObject]@{
        "firstname" = "Florian"
        "lastname" = "von Bracht"
        "score" = 10
        "object" = [PSCustomObject]@{
            
        }
    }
    [PSCustomObject]@{
        "firstname" = "Florian"
        #"lastname" = "von Bracht"
        "score" = 10
        "object" = [Hashtable]@{
            
        }
    }
)

$psCustoms2 = @(
    [Hashtable]@{
        "first name" = "Bat"
        "lastname" = "Man"
        "score" = 11
        "object" = [PSCustomObject]@{
            "street" = "Kaiserstrasse 35"
            "city" = "Frankfurt"
        }
        "active" = "true" # test $true
    }
)

Import-Module SqlPipeline
Open-SQLiteConnection -DataSource ":memory:"
Add-RowsToSql -InputObjects $psCustoms1 -TableName pscustoms -UseTransaction -FormatObjectAsJson -verbose
$psCustoms2 | Add-RowsToSql -TableName pscustoms -UseTransaction -FormatObjectAsJson -verbose -CreateColumnsInExistingTable
Invoke-SqlQuery -Query "Select * from pscustoms" | Format-Table
Close-SqlConnection
```

## Input other objects than Hashtable or PSCustomObject

You can deactivate the input validation with the `-IgnoreInputValidation` flag, e.g. if you are reading some systeminfo.
But please be beware, this can cause that something isn't working as expected.

```PowerShell
Get-ChildItem "*.*" | Add-RowsToSql -TableName "childitem" -UseTransaction -IgnoreInputValidation -verbose
```