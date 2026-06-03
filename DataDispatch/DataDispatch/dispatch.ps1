<#
.SYNOPSIS
    Webhook Dispatcher — liest WebhookEvents aus SQL Server und verteilt
    sie anhand von endpoints/*.yaml an konfigurierte Ziele.

.DESCRIPTION
    Wird als Scheduled Task alle N Minuten ausgeführt.
    Zustand wird in dbo.WebhookDispatchLog im SQL Server gehalten.
    Retry: fehlgeschlagene Einträge werden beim nächsten Run automatisch
    erneut verarbeitet.

.NOTES
    Benötigt: WriteLog, powershell-yaml Module
#>

[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# ------------------------------------------------------------
# Pfade
# ------------------------------------------------------------
$ScriptDir   = $PSScriptRoot
$EnvFile     = Join-Path $ScriptDir '.env'
$EndpointDir = Join-Path $ScriptDir 'endpoints'
$HandlerDir  = Join-Path $ScriptDir 'handlers'
$LogDir      = Join-Path $ScriptDir 'logs'

# ------------------------------------------------------------
# .env laden
# ------------------------------------------------------------
function Read-EnvFile([string]$Path) {
    $vars = @{}
    if (-not (Test-Path $Path)) { return $vars }
    Get-Content $Path | ForEach-Object {
        $line = $_.Trim()
        if ($line -and $line -notmatch '^#' -and $line -match '^([^=]+)=(.*)$') {
            $vars[$Matches[1].Trim()] = $Matches[2].Trim().Trim('"').Trim("'")
        }
    }
    return $vars
}

$envVars = Read-EnvFile $EnvFile
foreach ($key in $envVars.Keys) {
    Set-Item -Path "env:$key" -Value $envVars[$key]
}

# ------------------------------------------------------------
# WriteLog initialisieren
# ------------------------------------------------------------
$null = New-Item -ItemType Directory -Path $LogDir -Force
Import-Module WriteLog -ErrorAction Stop

$LogFile = Join-Path $LogDir "dispatch_$(Get-Date -Format 'yyyy-MM-dd').log"
Set-Logfile -Path $LogFile

# ------------------------------------------------------------
# powershell-yaml laden
# ------------------------------------------------------------
if (-not (Get-Module -ListAvailable -Name 'powershell-yaml')) {
    Write-Log "Installiere powershell-yaml..." -Level INFO
    Install-Module powershell-yaml -Scope CurrentUser -Force -AllowClobber
}
Import-Module powershell-yaml -ErrorAction Stop

# ------------------------------------------------------------
# SQL Server Verbindung (für WebhookEvents + DispatchLog)
# ------------------------------------------------------------
function Get-SqlConnection {
    $server  = $env:SQLSERVER_HOST
    $db      = $env:SQLSERVER_DB
    $winAuth = $env:SQLSERVER_WINDOWS_AUTH -eq 'true'
    $port    = if ($env:SQLSERVER_PORT) { $env:SQLSERVER_PORT } else { '1433' }

    if ($winAuth) {
        $connStr = "Server=$server,$port;Database=$db;Integrated Security=SSPI;TrustServerCertificate=True;"
    } else {
        $connStr = "Server=$server,$port;Database=$db;User Id=$($env:SQLSERVER_USER);Password=$($env:SQLSERVER_PASS);TrustServerCertificate=True;"
    }

    $conn = New-Object System.Data.SqlClient.SqlConnection($connStr)
    $conn.Open()
    return $conn
}

# ------------------------------------------------------------
# Feldwert aus Record auflösen
#   "id"               → direkte Spalte
#   "payload.email"    → payload-Spalte als JSON parsen, dann .email
#   "$"                → kompletter payload JSON-String
# ------------------------------------------------------------
function Resolve-Field([hashtable]$Record, [string]$FieldExpr) {
    if ($FieldExpr -eq '$') {
        return $Record['payload']
    }

    $parts = $FieldExpr -split '\.', 2

    if ($parts.Count -eq 1) {
        return $Record[$FieldExpr]
    }

    $colName  = $parts[0]
    $jsonPath = $parts[1]
    $raw      = $Record[$colName]

    if ($null -eq $raw) { return $null }

    try {
        $obj = $raw | ConvertFrom-Json -ErrorAction Stop
        $jsonPath -split '\.' | ForEach-Object {
            if ($null -ne $obj) { $obj = $obj.$_ }
        }
        return $obj
    } catch {
        return $null
    }
}

# ------------------------------------------------------------
# Pfad-Platzhalter auflösen
# {datetime}, {date}, {year}, {month}, {day}, {endpoint}, {target}
# ------------------------------------------------------------
function Resolve-PathTemplate([string]$Template, [string]$Endpoint, [string]$Target = '') {
    $now = Get-Date
    return $Template `
        -replace '\{datetime\}', ($now.ToString('yyyy-MM-dd_HHmm')) `
        -replace '\{date\}',     ($now.ToString('yyyy-MM-dd')) `
        -replace '\{year\}',     ($now.ToString('yyyy')) `
        -replace '\{month\}',    ($now.ToString('MM')) `
        -replace '\{day\}',      ($now.ToString('dd')) `
        -replace '\{endpoint\}', $Endpoint `
        -replace '\{target\}',   ($Target -replace '[\\/:*?"<>|]', '_')
}

# ------------------------------------------------------------
# Pending Records laden — Records ohne "done" Eintrag im DispatchLog
# ------------------------------------------------------------
function Get-PendingRecords {
    param(
        [System.Data.SqlClient.SqlConnection] $Conn,
        [string] $Endpoint,
        [string] $TargetName,
        [int]    $BatchSize = 100
    )

    $sql = @"
SELECT e.id, e.endpoint, e.payload, e.headers, e.source_ip,
       e.received_at, e.inserted_at
FROM   dbo.WebhookEvents e
WHERE  e.endpoint = @endpoint
  AND  NOT EXISTS (
    SELECT 1 FROM dbo.WebhookDispatchLog l
    WHERE  l.webhook_id  = e.id
      AND  l.target_name = @target_name
      AND  l.status      = 'done'
  )
ORDER  BY e.received_at ASC
OFFSET 0 ROWS FETCH NEXT @batch ROWS ONLY
"@
    $cmd = $Conn.CreateCommand()
    $cmd.CommandText = $sql
    $cmd.Parameters.AddWithValue('@endpoint',    $Endpoint)   | Out-Null
    $cmd.Parameters.AddWithValue('@target_name', $TargetName) | Out-Null
    $cmd.Parameters.AddWithValue('@batch',       $BatchSize)  | Out-Null

    $adapter = New-Object System.Data.SqlClient.SqlDataAdapter($cmd)
    $table   = New-Object System.Data.DataTable
    $adapter.Fill($table) | Out-Null

    $records = [System.Collections.Generic.List[hashtable]]::new()
    foreach ($row in $table.Rows) {
        $record = @{}
        foreach ($col in $table.Columns) {
            $record[$col.ColumnName] = if ($row[$col] -is [System.DBNull]) { $null } else { $row[$col] }
        }
        $records.Add($record)
    }
    return $records
}

# ------------------------------------------------------------
# DispatchLog Eintrag schreiben (MERGE — insert oder update)
# ------------------------------------------------------------
function Write-DispatchLog {
    param(
        [System.Data.SqlClient.SqlConnection] $Conn,
        [long]   $WebhookId,
        [string] $Endpoint,
        [string] $TargetName,
        [string] $TargetType,
        [string] $Status,
        [string] $ErrorMsg = $null
    )

    $sql = @"
MERGE dbo.WebhookDispatchLog AS t
USING (SELECT @webhook_id AS webhook_id, @target_name AS target_name) AS s
ON t.webhook_id = s.webhook_id AND t.target_name = s.target_name
WHEN MATCHED THEN
    UPDATE SET status        = @status,
               attempts      = t.attempts + 1,
               error         = @error,
               dispatched_at = SYSUTCDATETIME()
WHEN NOT MATCHED THEN
    INSERT (webhook_id, endpoint, target_name, target_type, status, attempts, error, dispatched_at)
    VALUES (@webhook_id, @endpoint, @target_name, @target_type, @status, 1, @error, SYSUTCDATETIME());
"@
    $cmd = $Conn.CreateCommand()
    $cmd.CommandText = $sql
    $cmd.Parameters.AddWithValue('@webhook_id',  $WebhookId)                              | Out-Null
    $cmd.Parameters.AddWithValue('@endpoint',    $Endpoint)                               | Out-Null
    $cmd.Parameters.AddWithValue('@target_name', $TargetName)                             | Out-Null
    $cmd.Parameters.AddWithValue('@target_type', $TargetType)                             | Out-Null
    $cmd.Parameters.AddWithValue('@status',      $Status)                                 | Out-Null
    $cmd.Parameters.AddWithValue('@error',       [object]($ErrorMsg ?? [DBNull]::Value))  | Out-Null
    $cmd.ExecuteNonQuery() | Out-Null
}

# ------------------------------------------------------------
# Hauptschleife
# ------------------------------------------------------------
Write-Log "=== Webhook Dispatcher gestartet ===" -Level INFO

$conn = $null
try {
    $conn = Get-SqlConnection
    Write-Log "Verbunden: $($env:SQLSERVER_HOST)/$($env:SQLSERVER_DB)" -Level INFO

    $yamlFiles = Get-ChildItem -Path $EndpointDir -Filter '*.yaml' -ErrorAction SilentlyContinue
    if (-not $yamlFiles) {
        Write-Log "Keine YAML-Dateien in: $EndpointDir" -Level WARN
        return
    }

    foreach ($yamlFile in $yamlFiles) {
        $cfg      = Get-Content $yamlFile.FullName -Raw | ConvertFrom-Yaml
        $endpoint = $cfg.endpoint

        if ($cfg.enabled -eq $false) {
            Write-Log "[$endpoint] Übersprungen (enabled: false)" -Level INFO
            continue
        }

        $batchSize = if ($cfg.batchSize) { [int]$cfg.batchSize } else { 100 }
        Write-Log "[$endpoint] Starte Verarbeitung..." -Level INFO

        foreach ($target in $cfg.targets) {
            $targetName = $target.name
            $targetType = $target.type

            $handlerPath = Join-Path $HandlerDir "$targetType.ps1"
            if (-not (Test-Path $handlerPath)) {
                Write-Log "[$endpoint][$targetName] Handler nicht gefunden: $handlerPath" -Level ERROR
                continue
            }

            $records = Get-PendingRecords -Conn $conn -Endpoint $endpoint `
                                          -TargetName $targetName -BatchSize $batchSize

            if ($records.Count -eq 0) {
                Write-Log "[$endpoint][$targetName] Keine neuen Records" -Level INFO
                continue
            }

            Write-Log "[$endpoint][$targetName] $($records.Count) Records" -Level INFO

            $doneCount = 0
            $failCount = 0

            try {
                # Handler aufrufen — gibt Liste von @{Id; Success; Error} zurück
                $results = & $handlerPath `
                    -Records   $records `
                    -Config    $target `
                    -Endpoint  $endpoint `
                    -ScriptDir $ScriptDir

                foreach ($result in $results) {
                    if ($result.Success) {
                        Write-DispatchLog -Conn $conn -WebhookId $result.Id `
                            -Endpoint $endpoint -TargetName $targetName `
                            -TargetType $targetType -Status 'done'
                        $doneCount++
                    } else {
                        Write-DispatchLog -Conn $conn -WebhookId $result.Id `
                            -Endpoint $endpoint -TargetName $targetName `
                            -TargetType $targetType -Status 'failed' -ErrorMsg $result.Error
                        $failCount++
                        Write-Log "[$endpoint][$targetName] ID=$($result.Id) failed: $($result.Error)" -Level WARN
                    }
                }

            } catch {
                $errMsg = $_.Exception.Message
                Write-Log "[$endpoint][$targetName] Handler-Fehler: $errMsg" -Level ERROR
                foreach ($record in $records) {
                    Write-DispatchLog -Conn $conn -WebhookId $record['id'] `
                        -Endpoint $endpoint -TargetName $targetName `
                        -TargetType $targetType -Status 'failed' -ErrorMsg $errMsg
                    $failCount++
                }
            }

            Write-Log "[$endpoint][$targetName] done=$doneCount failed=$failCount" -Level INFO
        }
    }

} catch {
    Write-Log "Kritischer Fehler: $($_.Exception.Message)" -Level ERROR
    Write-Log $_.ScriptStackTrace -Level ERROR
    exit 1
} finally {
    if ($null -ne $conn -and $conn.State -eq 'Open') { $conn.Close() }
    Write-Log "=== Dispatcher beendet ===" -Level INFO
}