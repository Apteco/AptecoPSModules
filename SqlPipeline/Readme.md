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
Install-SqlPipeline
```

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

Close-DuckDBConnection
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
| `EncryptionKey` | string | Optional AES-256 encryption key. |

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

### `Close-DuckDBConnection`

Closes a DuckDB connection cleanly. Use this when working with file-based databases opened via `Initialize-SQLPipeline`.

```PowerShell
# Close an explicit connection
Close-DuckDBConnection -Connection $conn

# Close the default connection
Close-DuckDBConnection -Connection (Initialize-SQLPipeline -DbPath '.\pipeline.db')
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

Close-DuckDBConnection
```

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