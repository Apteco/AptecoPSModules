function Test-DuckDBTableExists {
    <#
    .SYNOPSIS
        Checks whether a table exists in DuckDB.
    #>
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        [Parameter(Mandatory)] [DuckDB.NET.Data.DuckDBConnection]$Connection,
        [Parameter(Mandatory)] [string]$TableName
    )

    $result = Get-DuckDBData -Connection $Connection -Query @"
        SELECT COUNT(*) AS cnt
        FROM   information_schema.tables
        WHERE  table_name = '$TableName'
          AND  table_schema = 'main'
"@
    return ([int]$result.Rows[0]['cnt'] -gt 0)

}