
function Invoke-DuckDBUpsert {
    <#
    .SYNOPSIS
        Performs an UPSERT via a temporary staging table + INSERT ON CONFLICT.
    .DESCRIPTION
        1. Write data into stg_<TableName> via appender (default) or CSV COPY FROM
        2. INSERT INTO <TableName> ... ON CONFLICT (PK) DO UPDATE SET ...
        3. Drop the staging table
    .PARAMETER PKColumns
        Primary key columns for the ON CONFLICT clause.
        If empty: plain INSERT (no UPSERT).
    .PARAMETER UseCsvImport
        Use Write-DuckDBCsv (temp CSV + COPY FROM) instead of the default row-by-row appender.
        Faster for large datasets; DuckDB parses the CSV internally using multi-threaded C++.
    .PARAMETER SimpleTypesOnly
        Passed through to Write-DuckDBCsv (only relevant when -UseCsvImport is set).
        Skips per-cell complex-type checks when all values are guaranteed to be primitives.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)] [DuckDB.NET.Data.DuckDBConnection]$Connection,
        [Parameter(Mandatory)] [string]$TableName,
        [Parameter(Mandatory)] $Data,
        [string[]]$PKColumns = @(),
        [Parameter(Mandatory=$false)]
        [switch]$UseCsvImport = $false,
        [Parameter(Mandatory=$false)]
        [switch]$SimpleTypesOnly = $false
    )

    $stagingTable = "stg_$TableName"

    # Everything runs inside try/catch/finally:
    # - .NET exceptions (e.g. from ExecuteNonQuery) are only statement-terminating in PowerShell, so without
    #   this the function would just carry on with the next statement and silently lose the batch.
    #   catch { throw } turns them into terminating errors for the caller.
    # - finally always drops the staging table, so a failed batch cannot leak rows into the next one.
    try {

    # Create staging table
    Invoke-DuckDBQuery -Connection $Connection -Query @"
        CREATE TEMP TABLE IF NOT EXISTS $stagingTable
        AS SELECT * FROM $TableName WHERE 1 = 0
"@

    Write-Verbose "[$TableName] Staging table '$stagingTable' created. Starting UPSERT..."

    # Write data into staging table
    if ($UseCsvImport) {
        try {
            Write-DuckDBCsv -Connection $Connection -TableName $stagingTable -Data $Data -SimpleTypesOnly:$SimpleTypesOnly
        } catch {
            # Fall back to the appender for this batch so the data still gets loaded
            Write-Warning "[$TableName] CSV import failed, falling back to the appender for this batch of $($Data.Count) rows. Reason: $($_.Exception.Message)"
            Invoke-DuckDBQuery -Connection $Connection -Query "DELETE FROM $stagingTable"
            Write-DuckDBAppender -Connection $Connection -TableName $stagingTable -Data $Data -SimpleTypesOnly:$SimpleTypesOnly
        }
    } else {
        Write-DuckDBAppender -Connection $Connection -TableName $stagingTable -Data $Data -SimpleTypesOnly:$SimpleTypesOnly
    }

    Write-Verbose "[$TableName] Data written to staging table. Starting merge..."

    if ($PKColumns.Count -gt 0) {
        # Determine all non-PK columns for the SET clause
        $allCols  = Get-DuckDBColumns -Connection $Connection -TableName $TableName
        $setCols  = $allCols | Where-Object { $_ -notin $PKColumns }
        $setClause = ($setCols | ForEach-Object { """$_"" = excluded.""$_""" }) -join ', '
        $pkList    = $PKColumns -join ', '

        # Count inserts vs updates before the merge
        $joinClause = ($PKColumns | ForEach-Object { "t.`"$_`" = s.`"$_`"" }) -join " AND "
        $countResult = Get-DuckDBData -Connection $Connection -Query @"
            SELECT
                COUNT(*) FILTER (WHERE EXISTS     (SELECT 1 FROM $TableName t WHERE $joinClause)) AS Updates,
                COUNT(*) FILTER (WHERE NOT EXISTS (SELECT 1 FROM $TableName t WHERE $joinClause)) AS Inserts
            FROM $stagingTable s
"@
        $insertCount = [long]$countResult.Rows[0]["Inserts"]
        $updateCount = [long]$countResult.Rows[0]["Updates"]

        Write-Verbose "[$TableName] Performing UPSERT with PK columns: $pkList"
        Invoke-DuckDBQuery -Connection $Connection -Query @"
            INSERT INTO $TableName
            SELECT * FROM $stagingTable
            ON CONFLICT ($pkList) DO UPDATE SET $setClause
"@
    } else {
        # No PK defined - plain INSERT; count staging rows
        $countResult = Get-DuckDBData -Connection $Connection -Query "SELECT COUNT(*) AS cnt FROM $stagingTable"
        $insertCount = [long]$countResult.Rows[0]["cnt"]
        $updateCount = 0L

        Invoke-DuckDBQuery -Connection $Connection -Query @"
            INSERT INTO $TableName
            SELECT * FROM $stagingTable
"@
    }

    Write-Verbose "[$TableName] Merge completed. Inserts: $insertCount, Updates: $updateCount."

    } catch {
        throw
    } finally {
        # Clean up staging table
        try {
            Invoke-DuckDBQuery -Connection $Connection -Query "DROP TABLE IF EXISTS $stagingTable"
        } catch {
            Write-Warning "[$TableName] Could not drop staging table '$stagingTable': $($_.Exception.Message)"
        }
    }
    Write-Verbose "[$TableName] UPSERT completed."

    [PSCustomObject]@{
        Inserts = $insertCount
        Updates = $updateCount
    }
}
