function Initialize-SQLPipeline {
    <#
    .SYNOPSIS
        Opens a file-based DuckDB connection, initializes the metadata table, and sets
        it as the default connection for all subsequent DuckDB functions.

    .DESCRIPTION
        This function is only required when you want to use a persistent file-based
        DuckDB database. An in-memory database is initialized automatically when the
        module is imported, so calling this function is optional for in-memory use.

        After this call all DuckDB functions (Add-RowsToDuckDB, Get-DuckDBData, etc.)
        will use the file-based connection by default unless -Connection is specified explicitly.

    .PARAMETER DbPath
        Path to the DuckDB database file. The file is created if it does not exist.

    .PARAMETER EncryptionKey
        Optional encryption key (AES-256, requires DuckDB 1.4.0 or later).

    .EXAMPLE
        # File-based database
        Initialize-SQLPipeline -DbPath '.\pipeline.db'
        Import-Csv '.\orders.csv' | Add-RowsToDuckDB -TableName 'orders'
        Close-DuckDBConnection

    .EXAMPLE
        # Capture connection for explicit use
        $conn = Initialize-SQLPipeline -DbPath '.\pipeline.db'
        Import-Csv '.\orders.csv' | Add-RowsToDuckDB -Connection $conn -TableName 'orders'
        Close-DuckDBConnection -Connection $conn
    #>
    [CmdletBinding()]
    [OutputType([DuckDB.NET.Data.DuckDBConnection])]
    param(
        [Parameter(Mandatory)] [string]$DbPath,
        [string]$EncryptionKey
    )

    $absolutePath = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($DbPath)
    $params = @{ DbPath = $absolutePath }
    if ($EncryptionKey) { $params['EncryptionKey'] = $EncryptionKey }

    $conn = New-DuckDBConnection @params
    Initialize-PipelineMetadata -Connection $conn
    $Script:DefaultConnection = $conn
    Write-Information "SQLPipeline initialized: $absolutePath"

    # return
    $conn

}
