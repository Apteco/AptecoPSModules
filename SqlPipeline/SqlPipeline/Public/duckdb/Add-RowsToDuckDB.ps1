# ---------------------------------------------------------------------------
#region  Apteco SqlPipeline-compatible Interface Layer
# ---------------------------------------------------------------------------
# These functions follow the Apteco SqlPipeline API (Add-RowsToSql)
# and enable native PowerShell pipeline input (|) for DuckDB.
# Compatible with: Import-Module SqlPipeline, SimplySql
# ---------------------------------------------------------------------------

function Add-RowsToDuckDB {
    <#
    .SYNOPSIS
        Inserts PSObjects directly into a DuckDB table via the PowerShell pipeline.
        Compatible with the Apteco SqlPipeline interface (Add-RowsToSql).

    .DESCRIPTION
        Buffers the pipeline objects internally and performs the actual write
        to DuckDB once the pipeline is complete (End block).
        Supports:
        - Automatic table creation
        - Schema evolution (new columns)
        - UPSERT (when PKColumns are specified) or plain INSERT
        - Transaction-like batching via -UseTransaction (staging)

    .PARAMETER InputObject
        PSObject from the pipeline.

    .PARAMETER Connection
        Open DuckDB connection. If omitted, the default in-memory connection is used.

    .PARAMETER TableName
        Target table in DuckDB.

    .PARAMETER PKColumns
        Primary key columns for UPSERT. Empty = plain INSERT.

    .PARAMETER UseTransaction
        Buffers all rows and writes them at the end via a staging table (safer,
        slightly slower). Without this flag: appender is used directly after the buffer is filled.

    .PARAMETER BatchSize
        Number of rows per staging batch (default: 10000). Only relevant without -UseTransaction.

    .EXAMPLE
        # Apteco style: pipeline input
        Import-Csv '.\orders.csv' | Add-RowsToDuckDB -TableName 'orders' -PKColumns 'order_id' -UseTransaction -Verbose

    .EXAMPLE
        # Pipe API data directly (explicit connection)
        (Invoke-RestMethod 'https://api.example.com/orders').items |
            Add-RowsToDuckDB -Connection $conn -TableName 'orders' -PKColumns @('order_id')
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, ValueFromPipeline)]
        [PSObject]$InputObject,

        [Parameter(Mandatory=$false)]
        [DuckDB.NET.Data.DuckDBConnection]$Connection = $null,

        [Parameter(Mandatory)]
        [string]$TableName,

        [string[]]$PKColumns = @(),

        [switch]$UseTransaction,

        [int]$BatchSize = 10000
    )

    begin {
        if ($null -eq $Connection) {
            $Connection = $Script:DefaultConnection
            if ($null -eq $Connection) { throw "No active DuckDB connection. Provide -Connection or call Initialize-SQLPipeline first." }
        }
        $buffer = [System.Collections.Generic.List[PSObject]]::new()
        $rowCount = 0
        Write-Verbose "[$TableName] Add-RowsToDuckDB started (UseTransaction=$UseTransaction, BatchSize=$BatchSize)"
    }

    process {
        $buffer.Add($InputObject)
        $rowCount++

        # Without UseTransaction: write in batches once BatchSize is reached
        if (-not $UseTransaction -and $buffer.Count -ge $BatchSize) {
            Write-Verbose "[$TableName] Batch write: $($buffer.Count) rows"
            Invoke-BufferedWrite -Connection $Connection -TableName $TableName `
                                 -Data $buffer -PKColumns $PKColumns
            $buffer.Clear()
        }
    }

    end {
        if ($buffer.Count -eq 0) {
            Write-Verbose "[$TableName] No data in pipeline."
            return
        }

        Write-Verbose "[$TableName] Final write: $($buffer.Count) rows (total: $rowCount)"
        Invoke-BufferedWrite -Connection $Connection -TableName $TableName `
                             -Data $buffer -PKColumns $PKColumns
        Write-Information "[$TableName] $rowCount rows inserted via pipeline."
    }
}
#endregion
