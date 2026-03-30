function Show-DuckDBConnections {
    <#
    .SYNOPSIS
        Displays the current DuckDB connections managed by SqlPipeline.
    .DESCRIPTION
        Shows the in-memory connection and the active default connection, including
        their connection strings and current state.
    .EXAMPLE
        Show-DuckDBConnections
    #>
    [CmdletBinding()]
    param()

    [PSCustomObject]@{
        Name             = 'InMemory'
        ConnectionString = if ($null -ne $Script:InMemoryConnection) { $Script:InMemoryConnection.ConnectionString } else { $null }
        State            = if ($null -ne $Script:InMemoryConnection) { $Script:InMemoryConnection.State } else { 'Not initialized' }
        IsDefault        = [object]::ReferenceEquals($Script:DefaultConnection, $Script:InMemoryConnection)
    }

    if ($null -ne $Script:DefaultConnection -and -not [object]::ReferenceEquals($Script:DefaultConnection, $Script:InMemoryConnection)) {
        [PSCustomObject]@{
            Name             = 'Default (file-based)'
            ConnectionString = $Script:DefaultConnection.ConnectionString
            State            = $Script:DefaultConnection.State
            IsDefault        = $true
        }
    }

}
