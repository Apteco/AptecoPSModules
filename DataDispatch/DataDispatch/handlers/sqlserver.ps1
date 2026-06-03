<#
.SYNOPSIS
    SQL Server Handler — schreibt Records in eine SQL Server Tabelle
    oder führt eine Query/Stored Procedure aus.

YAML-Konfiguration (Modus 1 — Tabellen-Mapping):
    type: sqlserver
    windowsAuth: true       # oder false + user/password
    server: localhost       # optional, sonst aus .env
    database: TargetDB
    table: dbo.MyTable
    columnMapping:
      Email:      payload.email
      EventType:  payload.event
      ReceivedAt: received_at
      RawPayload: "$"

YAML-Konfiguration (Modus 2 — Query / Stored Procedure inline):
    type: sqlserver
    windowsAuth: true
    database: TargetDB
    query: "EXEC dbo.usp_Import @email, @event_type, @payload"
    parameters:
      email:       payload.email
      event_type:  payload.event
      payload:     "$"

YAML-Konfiguration (Modus 3 — SQL-Datei):
    type: sqlserver
    windowsAuth: true
    database: TargetDB
    queryFile: 'C:\Scripts\webhook-dispatcher\sql\import-brevo.sql'
    parameters:
      email:       payload.email
      event_type:  payload.event
      payload:     "$"

    Inhalt der SQL-Datei (normale @parametername Syntax):
      EXEC dbo.usp_ImportBrevoEvent
          @email      = @email,
          @event_type = @event_type,
          @payload    = @payload
#>

param(
    [object[]]  $Records,
    [hashtable] $Config,
    [string]    $Endpoint,
    [string]    $ScriptDir
)

Set-StrictMode -Version Latest

# ------------------------------------------------------------
# Verbindung aufbauen — aus Config oder Fallback auf .env
# ------------------------------------------------------------
function Get-TargetConnection([hashtable]$Cfg) {
    $server  = if ($Cfg['server'])   { $Cfg['server'] }   else { $env:SQLSERVER_HOST }
    $db      = $Cfg['database']
    $port    = if ($Cfg['port'])     { $Cfg['port'] }     else { if ($env:SQLSERVER_PORT) { $env:SQLSERVER_PORT } else { '1433' } }
    $winAuth = if ($null -ne $Cfg['windowsAuth']) { [bool]$Cfg['windowsAuth'] } else { $env:SQLSERVER_WINDOWS_AUTH -eq 'true' }

    if ($winAuth) {
        $connStr = "Server=$server,$port;Database=$db;Integrated Security=SSPI;TrustServerCertificate=True;"
    } else {
        $user = if ($Cfg['user'])     { $Cfg['user'] }     else { $env:SQLSERVER_USER }
        $pass = if ($Cfg['password']) { $Cfg['password'] } else { $env:SQLSERVER_PASS }
        $connStr = "Server=$server,$port;Database=$db;User Id=$user;Password=$pass;TrustServerCertificate=True;"
    }

    $conn = New-Object System.Data.SqlClient.SqlConnection($connStr)
    $conn.Open()
    return $conn
}

# ------------------------------------------------------------
# Query-Text ermitteln:
#   Modus 2: inline "query"
#   Modus 3: "queryFile" — Datei lesen, einmalig beim Handler-Start
# ------------------------------------------------------------
$queryText = $null
if ($Config['queryFile']) {
    $qfPath = $Config['queryFile']
    if (-not (Test-Path $qfPath)) {
        throw "queryFile nicht gefunden: $qfPath"
    }
    $queryText = Get-Content -Path $qfPath -Raw -Encoding UTF8
    Write-Log "[$Endpoint][sqlserver] Query aus Datei: $qfPath" -Level INFO
} elseif ($Config['query']) {
    $queryText = $Config['query']
}

# ------------------------------------------------------------
# Hauptlogik
# ------------------------------------------------------------
$targetConn = $null
$results    = [System.Collections.Generic.List[hashtable]]::new()

try {
    $targetConn = Get-TargetConnection -Cfg $Config
    $useQuery   = $null -ne $queryText   # Modus 2 oder 3
    $zielInfo   = if ($Config['table']) { $Config['table'] } `
                  elseif ($Config['queryFile']) { [System.IO.Path]::GetFileName($Config['queryFile']) } `
                  else { 'via query' }

    foreach ($record in $Records) {
        try {
            $cmd = $targetConn.CreateCommand()

            if ($useQuery) {
                # Modus 2 + 3: Query/SP mit Parametern
                $cmd.CommandText = $queryText
                foreach ($paramName in $Config['parameters'].Keys) {
                    $fieldExpr = $Config['parameters'][$paramName]
                    $value     = Resolve-Field -Record $record -FieldExpr $fieldExpr
                    $cmd.Parameters.AddWithValue("@$paramName", ($value ?? [DBNull]::Value)) | Out-Null
                }
            } else {
                # Modus 1: Tabellen-Mapping — INSERT generieren
                $table   = $Config['table']
                $mapping = $Config['columnMapping']
                $cols    = [string[]]$mapping.Keys
                $params  = $cols | ForEach-Object { "@p_$_" }

                $cmd.CommandText = "INSERT INTO $table ($($cols -join ', ')) VALUES ($($params -join ', '))"
                foreach ($col in $cols) {
                    $fieldExpr = $mapping[$col]
                    $value     = Resolve-Field -Record $record -FieldExpr $fieldExpr
                    $cmd.Parameters.AddWithValue("@p_$col", ($value ?? [DBNull]::Value)) | Out-Null
                }
            }

            $cmd.ExecuteNonQuery() | Out-Null
            $results.Add(@{ Id = $record['id']; Success = $true; Error = $null })

        } catch {
            $results.Add(@{ Id = $record['id']; Success = $false; Error = $_.Exception.Message })
        }
    }

} finally {
    if ($null -ne $targetConn -and $targetConn.State -eq 'Open') {
        $targetConn.Close()
    }
}

Write-Log "[$Endpoint][sqlserver] Ziel: $($Config['database']).$zielInfo" -Level INFO
return $results