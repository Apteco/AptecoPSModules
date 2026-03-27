
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

    # Create staging table
    Invoke-DuckDBQuery -Connection $Connection -Query @"
        CREATE TEMP TABLE IF NOT EXISTS $stagingTable
        AS SELECT * FROM $TableName WHERE 1 = 0
"@


    # Write data into staging table
    if ($UseCsvImport) {
        Write-DuckDBCsv -Connection $Connection -TableName $stagingTable -Data $Data -SimpleTypesOnly:$SimpleTypesOnly
    } else {
        Write-DuckDBAppender -Connection $Connection -TableName $stagingTable -Data $Data -SimpleTypesOnly:$SimpleTypesOnly
    }


    if ($PKColumns.Count -gt 0) {
        # Determine all non-PK columns for the SET clause
        $allCols  = Get-DuckDBColumns -Connection $Connection -TableName $TableName
        $setCols  = $allCols | Where-Object { $_ -notin $PKColumns }
        $setClause = ($setCols | ForEach-Object { """$_"" = excluded.""$_""" }) -join ', '
        $pkList    = $PKColumns -join ', '

        Invoke-DuckDBQuery -Connection $Connection -Query @"
            INSERT INTO $TableName
            SELECT * FROM $stagingTable
            ON CONFLICT ($pkList) DO UPDATE SET $setClause
"@
    } else {
        # No PK defined - plain INSERT
        Invoke-DuckDBQuery -Connection $Connection -Query @"
            INSERT INTO $TableName
            SELECT * FROM $stagingTable
"@
    }

    # Clean up staging table
    Invoke-DuckDBQuery -Connection $Connection -Query "DROP TABLE IF EXISTS $stagingTable"
    Write-Verbose "[$TableName] UPSERT completed."
}
