<#
.SYNOPSIS
    DuckDB Handler — schreibt Records in eine DuckDB-Datenbank via DuckDB.NET.
    Lädt die DLL über das ImportDependency-Modul.

YAML-Konfiguration (Modus 1 — Tabellen-Mapping):
    type: duckdb
    database: "D:\Analytics\events.duckdb"
    table: brevo_events
    columnMapping:
      email:      payload.email
      event_type: payload.event
      payload:    "$"
      received_at: received_at

YAML-Konfiguration (Modus 2 — Query):
    type: duckdb
    database: "D:\Analytics\events.duckdb"
    query: "INSERT INTO brevo_events SELECT * FROM read_json_auto(?)"
    parameters:
      - "$"       # Positionale Parameter als Liste
#>

param(
    [object[]]  $Records,
    [hashtable] $Config,
    [string]    $Endpoint,
    [string]    $ScriptDir
)

Set-StrictMode -Version Latest

# ------------------------------------------------------------
# DuckDB.NET via ImportDependency laden
# ------------------------------------------------------------
try {
    Import-Module ImportDependency -ErrorAction Stop
    $duckDbDll = Import-Dependency -Name 'DuckDB.NET.Data' -ErrorAction Stop
    Add-Type -Path $duckDbDll -ErrorAction Stop
} catch {
    throw "DuckDB.NET konnte nicht geladen werden. Bitte ImportDependency und DuckDB.NET.Data installieren. Fehler: $($_.Exception.Message)"
}

# ------------------------------------------------------------
# Verbindung öffnen
# ------------------------------------------------------------
$dbPath  = Resolve-PathTemplate -Template $Config['database'] -Endpoint $Endpoint
$dbDir   = Split-Path $dbPath -Parent
$null    = New-Item -ItemType Directory -Path $dbDir -Force

$connStr = "Data Source=$dbPath"
$conn    = [DuckDB.NET.Data.DuckDBConnection]::new($connStr)
$conn.Open()

$results  = [System.Collections.Generic.List[hashtable]]::new()
$useQuery = $null -ne $Config['query']

try {
    foreach ($record in $Records) {
        try {
            $cmd = $conn.CreateCommand()

            if ($useQuery) {
                # Modus 2: Query mit positionalen Parametern (Liste)
                $cmd.CommandText = $Config['query']
                $paramIndex = 1
                foreach ($fieldExpr in $Config['parameters']) {
                    $value = Resolve-Field -Record $record -FieldExpr $fieldExpr
                    $param = $cmd.CreateParameter()
                    $param.ParameterName = $paramIndex.ToString()
                    $param.Value         = $value ?? [DBNull]::Value
                    $cmd.Parameters.Add($param) | Out-Null
                    $paramIndex++
                }
            } else {
                # Modus 1: Tabellen-Mapping
                $table   = $Config['table']
                $mapping = $Config['columnMapping']
                $cols    = [string[]]$mapping.Keys
                $placeholders = 1..$cols.Count | ForEach-Object { "$$_" }

                $cmd.CommandText = "INSERT INTO $table ($($cols -join ', ')) VALUES ($($placeholders -join ', '))"

                $idx = 1
                foreach ($col in $cols) {
                    $value = Resolve-Field -Record $record -FieldExpr $mapping[$col]
                    $param = $cmd.CreateParameter()
                    $param.ParameterName = $idx.ToString()
                    $param.Value         = $value ?? [DBNull]::Value
                    $cmd.Parameters.Add($param) | Out-Null
                    $idx++
                }
            }

            $cmd.ExecuteNonQuery() | Out-Null
            $results.Add(@{ Id = $record['id']; Success = $true; Error = $null })

        } catch {
            $results.Add(@{ Id = $record['id']; Success = $false; Error = $_.Exception.Message })
        }
    }
} finally {
    if ($null -ne $conn -and $conn.State -eq 'Open') {
        $conn.Close()
    }
}

Write-Log "[$Endpoint][duckdb] Ziel: $dbPath :: $($Config['table'] ?? 'via query')" -Level INFO
return $results
