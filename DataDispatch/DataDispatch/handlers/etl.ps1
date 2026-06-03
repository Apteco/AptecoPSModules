<#
.SYNOPSIS
    ETL Handler — liest aus einer beliebigen SQL-Quelle und schreibt
    das Resultset via SqlBulkCopy in eine Zieltabelle.

YAML-Konfiguration:
    type: etl
    logResultSet: true
    logPreviewRows: 0     # 0 = alle Zeilen, N = nur erste N

    source:
      windowsAuth: true
      server: localhost   # optional
      database: SourceDB
      queryFile: 'C:\Scripts\sql\read-source.sql'
      # oder: query: "SELECT ..."
      parameters:
        cutoff: "2026-01-01"

    target:
      windowsAuth: true
      server: localhost   # optional
      database: ZielDB
      table: dbo.ZielTabelle
      batchSize: 1000
      timeout: 60
      columnMapping:      # optional — leer = Spaltennamen müssen übereinstimmen
        ZielEmail:   Email
        ZielName:    FullName
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

# Konfiguration
$sourceCfg      = $Config['source']
$targetCfg      = $Config['target']
$logResultSet   = if ($null -ne $Config['logResultSet'])   { [bool]$Config['logResultSet'] }   else { $true }
$logPreviewRows = if ($Config['logPreviewRows'])            { [int]$Config['logPreviewRows'] }   else { 0 }
$bulkBatchSize  = if ($targetCfg['batchSize'])              { [int]$targetCfg['batchSize'] }     else { 1000 }
$bulkTimeout    = if ($targetCfg['timeout'])                { [int]$targetCfg['timeout'] }       else { 60 }

if (-not $sourceCfg) { throw "ETL: 'source' fehlt in der YAML-Konfiguration." }
if (-not $targetCfg) { throw "ETL: 'target' fehlt in der YAML-Konfiguration." }
if (-not $targetCfg['table']) { throw "ETL: 'target.table' fehlt." }

$srcConn = "etl_src_$([guid]::NewGuid().ToString('N').Substring(0,8))"
$tgtConn = "etl_tgt_$([guid]::NewGuid().ToString('N').Substring(0,8))"

try {
    # ------------------------------------------------------------
    # 1. Source Query ausführen
    # ------------------------------------------------------------
    Open-TargetConnection -Cfg $sourceCfg -ConnName $srcConn

    if ($sourceCfg['queryFile']) {
        $qfPath = $sourceCfg['queryFile']
        if (-not (Test-Path $qfPath)) { throw "source.queryFile nicht gefunden: $qfPath" }
        $sourceQuery = Get-Content -Path $qfPath -Raw -Encoding UTF8
        Write-Log "[$Endpoint][etl] Source query aus Datei: $qfPath" -Severity INFO
    } elseif ($sourceCfg['query']) {
        $sourceQuery = $sourceCfg['query']
    } else {
        throw "ETL: Weder 'source.query' noch 'source.queryFile' konfiguriert."
    }

    $srcParams = @{}
    if ($sourceCfg['parameters']) {
        foreach ($pName in $sourceCfg['parameters'].Keys) {
            $srcParams[$pName] = $sourceCfg['parameters'][$pName]
        }
    }

    $rows     = Invoke-SqlQuery -ConnectionName $srcConn -Query $sourceQuery -Parameters $srcParams
    $rowCount = @($rows).Count

    if ($rowCount -eq 0) {
        Write-Log "[$Endpoint][etl] Keine Zeilen in Source — nichts zu schreiben." -Severity INFO
        return @(@{ Id = 0; Success = $true; Error = $null; RowCount = 0 })
    }

    $colNames = $rows[0].PSObject.Properties.Name
    Write-Log "[$Endpoint][etl] Source: $rowCount Zeilen, Spalten: $($colNames -join ', ')" -Severity INFO

    # ------------------------------------------------------------
    # 2. Resultset loggen
    # ------------------------------------------------------------
    if ($logResultSet) {
        $rowsToLog = if ($logPreviewRows -gt 0) { @($rows) | Select-Object -First $logPreviewRows } else { $rows }
        $logObjects = $rowsToLog | ForEach-Object {
            $obj = [ordered]@{}
            $_.PSObject.Properties | ForEach-Object { $obj[$_.Name] = $_.Value }
            $obj
        }
        $preview = if ($logPreviewRows -gt 0 -and $rowCount -gt $logPreviewRows) {
            " (Vorschau: erste $logPreviewRows von $rowCount)"
        } else { "" }
        $jsonLog = $logObjects | ConvertTo-Json -Depth 5 -Compress:($rowCount -gt 100)
        Write-Log "[$Endpoint][etl] Resultset$preview`: $jsonLog" -Severity INFO
    }

    # ------------------------------------------------------------
    # 3. DataTable aufbauen (mit optionalem Spalten-Mapping)
    # ------------------------------------------------------------
    $dataTable = New-Object System.Data.DataTable
    $mapping   = $targetCfg['columnMapping']

    if ($mapping -and $mapping.Count -gt 0) {
        foreach ($zielSpalte in $mapping.Keys) {
            $dataTable.Columns.Add($zielSpalte) | Out-Null
        }
        foreach ($row in $rows) {
            $newRow = $dataTable.NewRow()
            foreach ($zielSpalte in $mapping.Keys) {
                $quellSpalte = $mapping[$zielSpalte]
                $val = $row.PSObject.Properties[$quellSpalte]?.Value
                $newRow[$zielSpalte] = if ($null -ne $val) { $val } else { [DBNull]::Value }
            }
            $dataTable.Rows.Add($newRow)
        }
        Write-Log "[$Endpoint][etl] Spalten-Mapping: $($mapping.Keys -join ', ')" -Severity INFO
    } else {
        foreach ($col in $colNames) { $dataTable.Columns.Add($col) | Out-Null }
        foreach ($row in $rows) {
            $newRow = $dataTable.NewRow()
            foreach ($col in $colNames) {
                $val = $row.PSObject.Properties[$col]?.Value
                $newRow[$col] = if ($null -ne $val) { $val } else { [DBNull]::Value }
            }
            $dataTable.Rows.Add($newRow)
        }
    }

    # ------------------------------------------------------------
    # 4. SqlBulkCopy in Ziel
    # ------------------------------------------------------------
    Open-TargetConnection -Cfg $targetCfg -ConnName $tgtConn
    $tgtSqlConn = (Get-SqlConnection -ConnectionName $tgtConn).SqlConnection

    $bulk = New-Object System.Data.SqlClient.SqlBulkCopy($tgtSqlConn)
    $bulk.DestinationTableName = $targetCfg['table']
    $bulk.BatchSize            = $bulkBatchSize
    $bulk.BulkCopyTimeout      = $bulkTimeout

    foreach ($col in $dataTable.Columns) {
        $bulk.ColumnMappings.Add($col.ColumnName, $col.ColumnName) | Out-Null
    }

    $bulk.WriteToServer($dataTable)
    $bulk.Close()

    Write-Log "[$Endpoint][etl] $rowCount Zeilen nach $($targetCfg['table']) geschrieben." -Severity INFO
    return @(@{ Id = 0; Success = $true; Error = $null; RowCount = $rowCount })

} catch {
    $errMsg = $_.Exception.Message
    Write-Log "[$Endpoint][etl] Fehler: $errMsg" -Severity ERROR
    return @(@{ Id = 0; Success = $false; Error = $errMsg; RowCount = 0 })

} finally {
    Close-SqlConnection -ConnectionName $srcConn -ErrorAction SilentlyContinue
    Close-SqlConnection -ConnectionName $tgtConn -ErrorAction SilentlyContinue
}
