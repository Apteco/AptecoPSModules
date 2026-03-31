function Sync-DuckDBSchema {
    <#
    .SYNOPSIS
        Compares incoming data with the existing table schema and adds new columns
        via ALTER TABLE ADD COLUMN.
    .DESCRIPTION
        Columns that are no longer present in the incoming data remain unchanged in
        the table (they will receive NULL values on the next load).
        New columns from the incoming data are added automatically.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)] [DuckDB.NET.Data.DuckDBConnection]$Connection,
        [Parameter(Mandatory)] [string]$TableName,
        [Parameter(Mandatory)] $SampleRows
    )

    $existingCols = Get-DuckDBColumns -Connection $Connection -TableName $TableName
    $incomingCols = $SampleRows[0].PSObject.Properties.Name

    $newCols = $incomingCols | Where-Object { $_ -notin $existingCols }

    if ($newCols.Count -eq 0) {
        Write-Verbose "[$TableName] Schema is up to date - no new columns."
        return
    }

    foreach ($col in $newCols) {
        $values  = $SampleRows | ForEach-Object { $_.$col }
        $sqlType = Get-DuckDBBestType -Values $values
        Write-Verbose "[$TableName] New column: $col ($sqlType)"
        Invoke-DuckDBQuery -Connection $Connection -Query `
            "ALTER TABLE $TableName ADD COLUMN IF NOT EXISTS $col $sqlType"
    }
}
