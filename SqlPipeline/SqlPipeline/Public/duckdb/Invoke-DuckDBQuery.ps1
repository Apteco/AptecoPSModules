function Invoke-DuckDBQuery {
    <#
    .SYNOPSIS
        Executes a non-query SQL statement (CREATE, INSERT, ALTER, ...).
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)] [DuckDB.NET.Data.DuckDBConnection]$Connection = $null,
        [Parameter(Mandatory)] [string]$Query
    )

    if ($null -eq $Connection) {
        $Connection = $Script:DefaultConnection
        if ($null -eq $Connection) { throw "No active DuckDB connection. Provide -Connection or call Initialize-SQLPipeline first." }
    }

    $cmd = $Connection.CreateCommand()
    $cmd.CommandText = $Query
    $cmd.ExecuteNonQuery() | Out-Null
}
