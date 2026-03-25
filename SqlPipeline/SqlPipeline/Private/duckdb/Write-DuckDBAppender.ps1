function Write-DuckDBAppender {
    <#
    .SYNOPSIS
        Writes data into a table using the DuckDB Appender (plain INSERT, fast).
    .DESCRIPTION
        All rows must already be normalized (Repair-DuckDBRow).
        The property order in the PSObject must match the column order in the table.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)] [DuckDB.NET.Data.DuckDBConnection]$Connection,
        [Parameter(Mandatory)] [string]$TableName,
        [Parameter(Mandatory)] $Data
    )

    $appender = $Connection.CreateAppender($TableName)

    foreach ($row in $Data) {
        $appenderRow = $appender.CreateRow()
        foreach ($prop in $row.PSObject.Properties) {
            $val = ConvertTo-DuckDBValue -Value $prop.Value
            [void]$appenderRow.AppendValue($val)
        }
        $appenderRow.EndRow()
    }

    $appender.Close()
    Write-Verbose "[$TableName] Appender finished."
}
