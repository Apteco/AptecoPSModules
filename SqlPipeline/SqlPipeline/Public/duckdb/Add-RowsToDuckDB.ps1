# ---------------------------------------------------------------------------
#region  Apteco SqlPipeline-kompatibler Interface-Layer
# ---------------------------------------------------------------------------
# Diese Funktionen orientieren sich an der Apteco SqlPipeline API (Add-RowsToSql)
# und ermöglichen nativen PowerShell-Pipeline-Input (|) für DuckDB.
# Kompatibel mit: Import-Module SqlPipeline, SimplySql
# ---------------------------------------------------------------------------

function Add-RowsToDuckDB {
    <#
    .SYNOPSIS
        Fügt PSObjects per PowerShell-Pipeline direkt in eine DuckDB-Tabelle ein.
        Kompatibel mit dem Apteco SqlPipeline-Interface (Add-RowsToSql).

    .DESCRIPTION
        Puffert die Pipeline-Objekte intern und führt den eigentlichen Write
        in DuckDB aus, sobald die Pipeline abgeschlossen ist (End-Block).
        Unterstützt:
        - Automatische Tabellenerstellung
        - Schema-Evolution (neue Felder)
        - UPSERT (PKColumns angegeben) oder reiner INSERT
        - Transaktions-ähnliches Batching via -UseTransaction (Staging)

    .PARAMETER InputObject
        PSObject aus der Pipeline.

    .PARAMETER Connection
        Offene DuckDB-Verbindung.

    .PARAMETER TableName
        Zieltabelle in DuckDB.

    .PARAMETER PKColumns
        Primärschlüssel für UPSERT. Leer = reiner INSERT.

    .PARAMETER UseTransaction
        Puffert alle Rows und schreibt erst am Ende via Staging-Tabelle (sicherer,
        etwas langsamer). Ohne Flag: Appender direkt nach Puffer-Befüllung.

    .PARAMETER BatchSize
        Anzahl Rows pro Staging-Batch (Standard: 10000). Nur relevant ohne -UseTransaction.

    .EXAMPLE
        # Apteco-Stil: Pipeline-Input
        Import-Csv '.\orders.csv' | Add-RowsToDuckDB -Connection $conn -TableName 'orders' -PKColumns 'order_id' -UseTransaction -Verbose

    .EXAMPLE
        # API-Daten direkt pipen
        (Invoke-RestMethod 'https://api.example.com/orders').items |
            Add-RowsToDuckDB -Connection $conn -TableName 'orders' -PKColumns @('order_id')
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, ValueFromPipeline)]
        [PSObject]$InputObject,

        [Parameter(Mandatory)]
        [DuckDB.NET.Data.DuckDBConnection]$Connection,

        [Parameter(Mandatory)]
        [string]$TableName,

        [string[]]$PKColumns = @(),

        [switch]$UseTransaction,

        [int]$BatchSize = 10000
    )

    begin {
        $buffer = [System.Collections.Generic.List[PSObject]]::new()
        $rowCount = 0
        Write-Verbose "[$TableName] Add-RowsToDuckDB gestartet (UseTransaction=$UseTransaction, BatchSize=$BatchSize)"
    }

    process {
        $buffer.Add($InputObject)
        $rowCount++

        # Ohne UseTransaction: Batch-weise schreiben sobald BatchSize erreicht
        if (-not $UseTransaction -and $buffer.Count -ge $BatchSize) {
            Write-Verbose "[$TableName] Batch-Write: $($buffer.Count) Rows"
            Invoke-BufferedWrite -Connection $Connection -TableName $TableName `
                                 -Data $buffer -PKColumns $PKColumns
            $buffer.Clear()
        }
    }

    end {
        if ($buffer.Count -eq 0) {
            Write-Verbose "[$TableName] Keine Daten in Pipeline."
            return
        }

        Write-Verbose "[$TableName] Finaler Write: $($buffer.Count) Rows (gesamt: $rowCount)"
        Invoke-BufferedWrite -Connection $Connection -TableName $TableName `
                             -Data $buffer -PKColumns $PKColumns
        Write-Information "[$TableName] ✓ $rowCount Zeilen via Pipeline eingefügt." #-ForegroundColor Green
    }
}
#endregion