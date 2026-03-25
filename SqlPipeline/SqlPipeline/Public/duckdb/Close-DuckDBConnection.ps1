function Close-DuckDBConnection {
    <#
    .SYNOPSIS
        Closes a DuckDB connection cleanly.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [DuckDB.NET.Data.DuckDBConnection]$Connection
    )
    if ($Connection.State -ne [System.Data.ConnectionState]::Closed) {
        $Connection.Close()
        Write-Verbose 'DuckDB connection closed.'
    }
}