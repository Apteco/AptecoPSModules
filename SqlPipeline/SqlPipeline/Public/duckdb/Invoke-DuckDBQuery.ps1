function Invoke-DuckDBQuery {
    <#
    .SYNOPSIS
        Führt eine Non-Query SQL-Anweisung aus (CREATE, INSERT, ALTER, …).
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)] [DuckDB.NET.Data.DuckDBConnection]$Connection,
        [Parameter(Mandatory)] [string]$Query
    )

    $cmd = $Connection.CreateCommand()
    $cmd.CommandText = $Query
    $cmd.ExecuteNonQuery() | Out-Null
}
