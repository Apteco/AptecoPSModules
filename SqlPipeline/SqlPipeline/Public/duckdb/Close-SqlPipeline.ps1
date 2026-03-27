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
    
}