function Get-DuckDBColumns {
    <#
    .SYNOPSIS
        Returns the column names of a DuckDB table as a string array.
    #>
    [CmdletBinding()]
    [OutputType([string[]])]
    param(
        [Parameter(Mandatory)] [DuckDB.NET.Data.DuckDBConnection]$Connection,
        [Parameter(Mandatory)] [string]$TableName
    )

    $result = Get-DuckDBData -Connection $Connection -Query "DESCRIBE '$TableName'"
    return @($result.Rows | ForEach-Object { $_['column_name'] })

}
