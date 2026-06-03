# DataDispatch

Reads processed webhook events from SQL Server (`dbo.WebhookEvents`) and distributes
them to configurable targets: SQL Server tables, stored procedures, CSV, JSON, DuckDB.

Runs as a Windows Scheduled Task (PowerShell), every N minutes.

## Quick Start (PowerShell module)

```powershell
# 1. Install the module
Install-Module DataDispatch -Scope CurrentUser

# 2. Deploy application files to the target directory
Import-Module DataDispatch
Copy-DataDispatch -Destination 'C:\FastStats\Scripts\DataDispatch'

# 3. Install PowerShell dependencies (once per machine)
Install-Module WriteLog        -Scope CurrentUser
Install-Module SimplySql       -Scope CurrentUser
Install-Module powershell-yaml -Scope CurrentUser

# 4. Configure
cd C:\FastStats\Scripts\DataDispatch
Copy-Item .env.example .env
notepad .env                             # source database connection (WebhookEvents)
notepad endpoints\brevo-marketing.yaml   # targets and SQL file paths

# 5. Register the Scheduled Task (run as Administrator)
.\setup-task.ps1 -Action install

# 6. Run once to verify
.\setup-task.ps1 -Action run
Get-Content logs\dispatch_$(Get-Date -Format 'yyyy-MM-dd').log -Tail 30
```

## How It Works

```
Scheduled Task (every 5 min)
  │
  └── dispatch.ps1
        ├── reads endpoints/*.yaml
        └── for each endpoint + target:
              ├── load pending records
              │   (WebhookEvents not yet marked "done" in the state DB)
              ├── call handler  (handlers/<type>.ps1)
              ├── success  → state DB: done
              └── failure  → state DB: failed
                             → next run = automatic retry
```

Dispatch state (which records have been processed per endpoint/target) is tracked in a
local SQLite file (`dispatch_state.db`) via the `SimplySql` module — no changes to the
source database are needed.

## File Structure

```
DataDispatch\
├── DataDispatch\                   ← PowerShell module
│   ├── DataDispatch.psd1
│   ├── DataDispatch.psm1
│   ├── Public\
│   │   └── Copy-DataDispatch.ps1  ← deploys app files to a target directory
│   ├── dispatch.ps1               ← core script — do not modify
│   ├── setup-task.ps1             ← Scheduled Task management
│   ├── .env.example
│   ├── endpoints\
│   │   └── brevo-marketing.yaml   ← one file per webhook endpoint
│   └── handlers\
│       ├── csv.ps1
│       ├── json.ps1
│       ├── sqlserver.ps1
│       ├── duckdb.ps1
│       ├── script.ps1             ← run a SQL script once (with checkpoint support)
│       └── etl.ps1                ← SQL source → SqlBulkCopy to target table
├── README.md
└── publish.ps1
```

Runtime files created in the deployment directory (not in the module):

```
<deploy-dir>\
├── .env                           ← local config (not committed)
├── dispatch_state.db              ← SQLite state tracking
└── logs\
    └── dispatch_YYYY-MM-DD.log
```

## Task Management

```powershell
.\setup-task.ps1 -Action install    # register task (run as Administrator)
.\setup-task.ps1 -Action status     # last run, next run, result
.\setup-task.ps1 -Action run        # trigger immediately (one-shot)
.\setup-task.ps1 -Action uninstall  # remove task
```

Optional parameters for `install`:

| Parameter | Default | Description |
|-----------|---------|-------------|
| `-IntervalMinutes` | `5` | How often the task runs |
| `-RunAsUser` | `SYSTEM` | Windows account (must have SQL Server access for Windows Auth) |

## endpoints/*.yaml

One YAML file per webhook endpoint. Each file can define any number of targets.

```yaml
endpoint: my-endpoint   # must match the Endpoint value in dbo.WebhookEvents
enabled: true
batchSize: 100          # records per run per target

targets:
  - name: "My Target"   # free text, used in the state DB and logs
    type: csv           # csv | json | sqlserver | duckdb | script | etl
    # ... target-specific fields
```

## Field Resolution

In `columnMapping`, `parameters`, and `fields`, record fields are referenced as:

| Expression | Description |
|---|---|
| `id` | Direct DB column |
| `received_at` | Direct DB column |
| `payload.email` | Parse payload JSON, field `.email` |
| `payload.address.city` | Nested (dot notation) |
| `$` | Full payload as a JSON string |

## Target Types

### csv

```yaml
- name: "Export"
  type: csv
  path: 'D:\Exports\{endpoint}\{datetime}.csv'
  delimiter: ";"          # default: ;
  encoding: UTF8          # UTF8 (no BOM) | UTF8BOM | ASCII | Unicode
  append: false           # true: append to existing file
  includeHeaders: true
  columns:                # optional — empty = all columns automatically
    - field: id
      header: EventId
    - field: payload.email
      header: Email
    - field: "$"
      header: RawPayload
```

### json

```yaml
- name: "Export"
  type: json
  path: 'D:\Exports\{endpoint}\{datetime}.json'
  pretty: true            # pretty-printed JSON
  mode: array             # array (default) | lines (JSONL)
  append: false           # only useful with mode: lines
  fields:                 # optional — empty = payload + metadata
    - field: payload.email
      as: email
    - field: "$"
      as: fullPayload
```

### sqlserver

```yaml
# Mode 1: table mapping
- name: "Table insert"
  type: sqlserver
  windowsAuth: true       # or false + user/password
  server: localhost       # optional — falls back to .env
  database: TargetDB
  table: dbo.MyTable
  columnMapping:
    Column1: payload.email
    Column2: received_at
    Payload: "$"

# Mode 2: query / stored procedure
- name: "Stored procedure"
  type: sqlserver
  windowsAuth: true
  database: TargetDB
  query: "EXEC dbo.usp_Import @email, @payload"
  parameters:
    email:   payload.email
    payload: "$"
```

### duckdb

```yaml
# Mode 1: table mapping
- name: "Analytics"
  type: duckdb
  database: 'D:\Analytics\events.duckdb'
  table: my_table
  columnMapping:
    email:   payload.email
    payload: "$"

# Mode 2: query (positional parameters)
- name: "Analytics query"
  type: duckdb
  database: 'D:\Analytics\events.duckdb'
  query: "INSERT INTO events SELECT * FROM read_json_auto(?)"
  parameters:
    - "$"
```

### script

Executes a SQL script (or inline query) once per dispatcher run.
Supports optional checkpoint tracking: the dispatcher remembers the last processed event ID
and on the next run only processes new records.

```yaml
- name: "Process responses"
  type: script
  windowsAuth: true
  database: TargetDB
  queryFile: 'C:\Scripts\insert_responses.sql'
  logResultSet: true

  checkpoint:
    enabled: true
    parameter: last_id        # @last_id = lower bound (exclusive)
    newIdParameter: new_id    # @new_id  = upper bound (inclusive)
    initialValue: 0
    sourceTable: dbo.WebhookEvents
    sourceIdColumn: id
```

The SQL script receives `@last_id` (last processed value) and `@new_id` (current maximum).
Typical pattern:

```sql
INSERT INTO dbo.Responses (...)
SELECT ... FROM dbo.WebhookEvents
WHERE id > @last_id AND id <= @new_id
  AND Endpoint = 'brevo-marketing'
```

### etl

Reads a result set from a SQL source and writes it via `SqlBulkCopy` to a target table —
ideal for larger data volumes.

```yaml
- name: "ETL Brevo → target table"
  type: etl
  logResultSet: true
  logPreviewRows: 5   # 0 = log all rows

  source:
    windowsAuth: true
    database: SourceDB
    queryFile: 'C:\Scripts\read_source.sql'

  target:
    windowsAuth: true
    database: TargetDB
    table: dbo.TargetTable
    batchSize: 1000
    timeout: 60
    columnMapping:        # optional — empty = column names must match
      TargetEmail: Email
      TargetName:  FullName
```

## Path Placeholders

Available in `path` and `database` values:

| Placeholder | Example |
|---|---|
| `{datetime}` | `2026-04-24_1430` |
| `{date}` | `2026-04-24` |
| `{year}` | `2026` |
| `{month}` | `04` |
| `{day}` | `24` |
| `{endpoint}` | `brevo-marketing` |
| `{target}` | `CSV-Export` |

## Retry Behaviour

Failed records are **automatically retried on the next scheduled run** — no manual
intervention needed. The `attempts` counter in the state DB increments on each attempt.

To manually retry all failed records for an endpoint:

```sql
UPDATE dispatch_log
SET    status = 'pending'
WHERE  endpoint = 'brevo-marketing'
  AND  status   = 'failed'
```

(The state DB is `dispatch_state.db` in the deployment directory, queryable with any SQLite client.)

## DuckDB.NET via ImportDependency

The DuckDB handler loads the DLL via the `ImportDependency` module:

```powershell
Import-Module ImportDependency
Import-Dependency -Name 'DuckDB.NET.Data'
```

Make sure the module is installed and `DuckDB.NET.Data` is registered as a dependency
before starting the dispatcher with DuckDB targets.

## .env Reference

| Variable | Description |
|---|---|
| `SQLSERVER_HOST` | SQL Server hostname (source database) |
| `SQLSERVER_DB` | Database name (`WebhookEvents`) |
| `SQLSERVER_WINDOWS_AUTH` | `true` / `false` |
| `SQLSERVER_USER` | SQL login (without Windows Auth) |
| `SQLSERVER_PASS` | Password (without Windows Auth) |
| `SQLSERVER_PORT` | Default: `1433` |
