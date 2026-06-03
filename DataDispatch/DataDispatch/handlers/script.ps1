<#
.SYNOPSIS
    Script Handler — führt ein eigenständiges SQL-Script einmal pro
    Dispatcher-Run aus. Unterstützt Checkpoint-Tracking via SQLite.

YAML-Konfiguration:
    type: script
    windowsAuth: true
    server: localhost       # optional, sonst aus .env
    database: ZielDB
    queryFile: 'C:\Scripts\webhook-dispatcher\sql\merge.sql'
    logResultSet: true

    checkpoint:
      enabled: true
      parameter: last_id      # @last_id = untere Grenze (exklusiv)
      newIdParameter: new_id  # @new_id  = obere Grenze (inklusiv), default: new_id
      initialValue: 0
      sourceTable: dbo.WebhookEvents
      sourceIdColumn: id
#>

# Password is read from an environment variable and must be converted for SimplySql credential auth.
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingConvertToSecureStringWithPlainText', '')]
param(
    [object[]]  $Records,
    [hashtable] $Config,
    [string]    $Endpoint,
    [string]    $ScriptDir
)

Set-StrictMode -Version Latest

# ------------------------------------------------------------
# Verbindung via SimplySql öffnen
# ------------------------------------------------------------
function Open-TargetConnection([hashtable]$Cfg, [string]$ConnName) {
    $server  = if ($Cfg['server'])   { $Cfg['server'] }   else { $env:SQLSERVER_HOST }
    $db      = $Cfg['database']
    $port    = if ($Cfg['port'])     { $Cfg['port'] }     else { if ($env:SQLSERVER_PORT) { $env:SQLSERVER_PORT } else { '1433' } }
    $winAuth = if ($null -ne $Cfg['windowsAuth']) { [bool]$Cfg['windowsAuth'] } else { $env:SQLSERVER_WINDOWS_AUTH -eq 'true' }
    $serverStr = if ($port -ne '1433') { "$server,$port" } else { $server }

    if ($winAuth) {
        Open-SQLConnection -Server $serverStr -Database $db -ConnectionName $ConnName
    } else {
        $user    = if ($Cfg['user'])     { $Cfg['user'] }     else { $env:SQLSERVER_USER }
        $pass    = if ($Cfg['password']) { $Cfg['password'] } else { $env:SQLSERVER_PASS }
        $secPass = ConvertTo-SecureString $pass -AsPlainText -Force
        $cred    = New-Object System.Management.Automation.PSCredential($user, $secPass)
        Open-SQLConnection -Server $serverStr -Database $db -Credential $cred -ConnectionName $ConnName
    }
}

# ------------------------------------------------------------
# Konfiguration
# ------------------------------------------------------------
$logResultSet  = if ($null -ne $Config['logResultSet']) { [bool]$Config['logResultSet'] } else { $true }
$checkpointCfg = $Config['checkpoint']
$useCheckpoint = $checkpointCfg -and [bool]$checkpointCfg['enabled']
$targetName    = $Config['name']

# Query laden
if ($Config['queryFile']) {
    $qfPath = $Config['queryFile']
    if (-not (Test-Path $qfPath)) { throw "queryFile nicht gefunden: $qfPath" }
    $queryText = Get-Content -Path $qfPath -Raw -Encoding UTF8
    Write-Log "[$Endpoint][script] Query aus Datei: $qfPath" -Severity INFO
} elseif ($Config['query']) {
    $queryText = $Config['query']
} else {
    throw "[$Endpoint][script] Weder 'query' noch 'queryFile' konfiguriert."
}

$connName = "script_$([guid]::NewGuid().ToString('N').Substring(0,8))"

try {
    Open-TargetConnection -Cfg $Config -ConnName $connName

    # ------------------------------------------------------------
    # 1. Checkpoint laden
    # ------------------------------------------------------------
    $lastId = 0
    $newCheckpoint = 0

    if ($useCheckpoint) {
        $paramName      = $checkpointCfg['parameter']      ?? 'last_id'
        $newIdParamName = $checkpointCfg['newIdParameter'] ?? 'new_id'
        $initialValue   = $checkpointCfg['initialValue']   ?? 0
        $sourceTable    = $checkpointCfg['sourceTable']    ?? 'dbo.WebhookEvents'
        $sourceIdCol    = $checkpointCfg['sourceIdColumn'] ?? 'id'

        $cpRow = Invoke-SqlQuery -ConnectionName 'state' -Query @"
            SELECT checkpoint FROM dispatch_checkpoints
            WHERE  endpoint    = @endpoint
              AND  target_name = @target
"@ -Parameters @{ endpoint = $Endpoint; target = $targetName } -ErrorAction SilentlyContinue

        $lastId = if ($cpRow -and $cpRow.PSObject.Properties['checkpoint'] -and $null -ne $cpRow.checkpoint) {
            [long]$cpRow.checkpoint
        } else {
            [long]$initialValue
        }

        # ------------------------------------------------------------
        # 2. MAX(id) VOR dem Script ermitteln
        # ------------------------------------------------------------
        $maxRow        = Invoke-SqlQuery -ConnectionName $connName -Query "SELECT ISNULL(MAX($sourceIdCol), 0) AS maxid FROM $sourceTable"
        $newCheckpoint = [long]$maxRow.maxid

        Write-Log "[$Endpoint][script] Checkpoint-Fenster: @$paramName=$lastId → @$newIdParamName=$newCheckpoint" -Severity INFO
    }

    # ------------------------------------------------------------
    # 3. Script ausführen
    # ------------------------------------------------------------
    $params = @{}
    if ($useCheckpoint) {
        $params[$paramName]      = $lastId
        $params[$newIdParamName] = $newCheckpoint
    }
    if ($Config['parameters']) {
        foreach ($pName in $Config['parameters'].Keys) {
            $params[$pName] = $Config['parameters'][$pName]
        }
    }

    $rows     = Invoke-SqlQuery -ConnectionName $connName -Query $queryText -Parameters $params -ErrorAction SilentlyContinue
    $rowsArray = @($rows | Where-Object { $null -ne $_ -and $_.PSObject -ne $null })
    $rowCount  = $rowsArray.Count

    $colNames = '—'
    $dataRows = @()
    if ($rowCount -gt 0) {
        $dataRows = [System.Collections.Generic.List[object]]::new()
        foreach ($row in $rowsArray) {
            $flat = [ordered]@{}
            try {
                if ($row.PSObject.Properties['Table'] -and $row.Table -and $row.Table.Columns) {
                    foreach ($col in $row.Table.Columns) {
                        $flat[$col.ColumnName] = $row[$col.ColumnName]
                    }
                } else {
                    $row.PSObject.Properties | Where-Object {
                        $_.Value -isnot [System.Data.DataTable] -and
                        $_.Value -isnot [System.Data.DataSet] -and
                        $_.Value -isnot [System.Type] -and
                        $_.Value -isnot [System.Data.DataRowCollection]
                    } | ForEach-Object { $flat[$_.Name] = $_.Value }
                }
            } catch {
                $flat['raw'] = $row.ToString()
            }
            $dataRows.Add($flat)
        }
        try { $colNames = ($dataRows[0].Keys) -join ', ' } catch { $colNames = '(unbekannt)' }
    }

    Write-Log "[$Endpoint][script] Ausgeführt — Resultset: $rowCount Zeile(n), Spalten: $colNames" -Severity INFO

    # ------------------------------------------------------------
    # 4. Resultset loggen
    # ------------------------------------------------------------
    if ($logResultSet -and $dataRows.Count -gt 0) {
        $jsonLog = $dataRows | ConvertTo-Json -Depth 2 -Compress:($dataRows.Count -gt 50)
        Write-Log "[$Endpoint][script] Resultset: $jsonLog" -Severity INFO
    }

    # ------------------------------------------------------------
    # 5. Checkpoint speichern
    # ------------------------------------------------------------
    if ($useCheckpoint) {
        Invoke-SqlUpdate -ConnectionName 'state' -Query @"
            INSERT INTO dispatch_checkpoints (endpoint, target_name, checkpoint)
            VALUES (@endpoint, @target, @checkpoint)
            ON CONFLICT(endpoint, target_name) DO UPDATE SET
                checkpoint = excluded.checkpoint,
                updated_at = strftime('%Y-%m-%dT%H:%M:%fZ','now')
"@ -Parameters @{ endpoint = $Endpoint; target = $targetName; checkpoint = $newCheckpoint }

        Write-Log "[$Endpoint][script] Checkpoint gespeichert: $paramName = $newCheckpoint" -Severity INFO
    }

    return ,[PSCustomObject]@{ Id = 0; Success = $true; Error = $null; RowCount = $rowCount }

} catch {
    $errMsg = $_.Exception.Message
    Write-Log "[$Endpoint][script] Fehler: $errMsg" -Severity ERROR
    return ,[PSCustomObject]@{ Id = 0; Success = $false; Error = $errMsg; RowCount = 0 }

} finally {
    Close-SqlConnection -ConnectionName $connName -ErrorAction SilentlyContinue
}
