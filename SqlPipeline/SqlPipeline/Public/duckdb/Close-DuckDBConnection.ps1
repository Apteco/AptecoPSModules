function Close-DuckDBConnection {
    <#
    .SYNOPSIS
        Schließt eine DuckDB-Verbindung sauber.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [DuckDB.NET.Data.DuckDBConnection]$Connection
    )
    if ($Connection.State -ne [System.Data.ConnectionState]::Closed) {
        $Connection.Close()
        Write-Verbose 'DuckDB-Verbindung geschlossen.'
    }
}