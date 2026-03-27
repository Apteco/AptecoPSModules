function New-DuckDBConnection {
    <#
    .SYNOPSIS
        Opens a DuckDB connection to the specified database file or in-memory database.
    .PARAMETER DbPath
        Path to the .db file (created if it does not exist). Use ':memory:' for an in-memory database.
    .PARAMETER EncryptionKey
        Optional encryption key (AES-256, requires DuckDB 1.4.0 or later).
    .EXAMPLE
        $conn = New-DuckDBConnection -DbPath '.\pipeline.db'
    #>
    [CmdletBinding()]
    [OutputType([DuckDB.NET.Data.DuckDBConnection])]
    param(
        [Parameter(Mandatory)]
        [string]$DbPath,

        [string]$EncryptionKey
        #[string]$LibPath = '.\lib'
    )

    #Initialize-DuckDB -LibPath $LibPath
    If ( -not $Script:isDuckDBLoaded ) {
        throw "DuckDB.NET is not loaded. Please ensure it is installed and available in the lib folder."
    }

    $connStr = "DataSource=$DbPath"
    if ($EncryptionKey) { $connStr += ";EncryptionKey=$EncryptionKey" }

    $conn = [DuckDB.NET.Data.DuckDBConnection]::new($connStr)
    $conn.Open()
    Write-Verbose "Connection opened: $DbPath"
    $conn
    
}
