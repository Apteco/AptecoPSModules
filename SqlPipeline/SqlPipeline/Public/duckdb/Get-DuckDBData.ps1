function Get-DuckDBData {
    <#
    .SYNOPSIS
        Executes a SELECT query and returns the results as a DataTable.
    #>
    [CmdletBinding()]
    [OutputType([System.Data.DataTable])]
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
    $reader = $cmd.ExecuteReader()
    $table = [System.Data.DataTable]::new()
    $table.Load($reader)
    $table

}
