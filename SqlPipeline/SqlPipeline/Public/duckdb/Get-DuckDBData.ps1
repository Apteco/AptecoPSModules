function Get-DuckDBData {
    <#
    .SYNOPSIS
        Führt eine SELECT-Abfrage aus und gibt die Ergebnisse als DataTable zurück.
    #>
    [CmdletBinding()]
    [OutputType([System.Data.DataTable])]
    param(
        [Parameter(Mandatory)] [DuckDB.NET.Data.DuckDBConnection]$Connection,
        [Parameter(Mandatory)] [string]$Query
    )

    $cmd = $Connection.CreateCommand()
    $cmd.CommandText = $Query
    $reader = $cmd.ExecuteReader()
    $table = [System.Data.DataTable]::new()
    $table.Load($reader)
    $table

}
