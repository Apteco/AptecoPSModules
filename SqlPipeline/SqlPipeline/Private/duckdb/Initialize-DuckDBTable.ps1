function Initialize-DuckDBTable {
    <#
    .SYNOPSIS
        Creates a table based on a sample PSObject row if it does not already exist.
    .PARAMETER Connection
        Open DuckDB connection.
    .PARAMETER TableName
        Name of the target table.
    .PARAMETER SampleRow
        A PSObject whose properties are used as column definitions.
    .PARAMETER PKColumns
        Primary key columns (optional, recommended for UPSERT).
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)] [DuckDB.NET.Data.DuckDBConnection]$Connection,
        [Parameter(Mandatory)] [string]$TableName,
        [Parameter(Mandatory)] $SampleRow,
        [string[]]$PKColumns = @()
    )

    if (Test-DuckDBTableExists -Connection $Connection -TableName $TableName) {
        Write-Verbose "[$TableName] Table already exists."
        return
    }

    Write-Verbose "[$TableName] Creating new table..."

    $colDefs = $SampleRow.PSObject.Properties | ForEach-Object {
        $sqlType = ConvertTo-DuckDBType -Value $_.Value
        "    $($_.Name)  $sqlType"
    }

    $pkDef = if ($PKColumns.Count -gt 0) {
        ",`n    PRIMARY KEY ($($PKColumns -join ', '))"
    } else { '' }

    Invoke-DuckDBQuery -Connection $Connection -Query @"
        CREATE TABLE $TableName (
$($colDefs -join ",`n")
$pkDef
        )
"@
    Write-Verbose "[$TableName] Table created with $($colDefs.Count) columns."
}
