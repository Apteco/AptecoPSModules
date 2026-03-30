function Close-SqlPipeline {
    <#
    .SYNOPSIS
        Closes a DuckDB connection cleanly.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [DuckDB.NET.Data.DuckDBConnection]$Connection = $null
    )

    if ($null -eq $Connection) {
        $Connection = $Script:DefaultConnection
        if ($null -eq $Connection) { throw "No active DuckDB connection. Provide -Connection or call Initialize-SQLPipeline first." }
    }

    if ($Connection.State -ne [System.Data.ConnectionState]::Closed) {
        $Connection.Close()
        Write-Verbose 'DuckDB connection closed.'
    }

    # If the closed connection was the active default, restore the in-memory connection
    # so that subsequent calls without -Connection still work.
    if ([object]::ReferenceEquals($Connection, $Script:DefaultConnection)) {
        $Script:DefaultConnection = $Script:InMemoryConnection
        Write-Verbose 'Default connection restored to in-memory database.'
    }

}