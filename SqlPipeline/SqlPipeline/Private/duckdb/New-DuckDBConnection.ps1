function New-DuckDBConnection {
    <#
    .SYNOPSIS
        Opens a DuckDB connection to the specified database file or in-memory database.
    .PARAMETER DbPath
        Path to the .db file (created if it does not exist). Use ':memory:' for an in-memory database.
    .PARAMETER EncryptionKey
        Optional encryption key (AES-256, requires DuckDB 1.4.0 or later).
        When provided the database is attached via ATTACH ... (ENCRYPTION_KEY '...') and
        set as the default catalog with USE, so all subsequent queries are transparent.
    .PARAMETER EncryptionCipher
        Cipher to use when EncryptionKey is set. 'GCM' (default, authenticated) or 'CTR' (faster, no integrity check).
    .EXAMPLE
        $conn = New-DuckDBConnection -DbPath '.\pipeline.db'
    .EXAMPLE
        $conn = New-DuckDBConnection -DbPath '.\pipeline.db' -EncryptionKey 'mysecretkey'
    #>
    [CmdletBinding()]
    [OutputType([DuckDB.NET.Data.DuckDBConnection])]
    param(
        [Parameter(Mandatory)]
        [string]$DbPath,

        [string]$EncryptionKey,

        [ValidateSet('GCM', 'CTR')]
        [string]$EncryptionCipher = 'GCM'
    )

    If ( -not $Script:isDuckDBLoaded ) {
        throw "DuckDB.NET is not loaded. Please ensure it is installed and available in the lib folder."
    }

    if ($EncryptionKey -and $DbPath -ne ':memory:') {
        # DuckDB encryption is configured via ATTACH, not via connection string.
        # Open a plain in-memory bootstrap connection, attach the encrypted file,
        # then make it the default catalog so all subsequent queries are transparent.
        $conn = [DuckDB.NET.Data.DuckDBConnection]::new('DataSource=:memory:')
        $conn.Open()

        # Escape single quotes in path and key to prevent SQL injection
        $escapedPath = $DbPath    -replace "'", "''"
        $escapedKey  = $EncryptionKey -replace "'", "''"

        $cmd = $conn.CreateCommand()
        try {
            # DuckDB 1.4.1+ requires OpenSSL (via httpfs) for writes to encrypted databases.
            $cmd.CommandText = 'INSTALL httpfs'
            $null = $cmd.ExecuteNonQuery()
            $cmd.CommandText = 'LOAD httpfs'
            $null = $cmd.ExecuteNonQuery()

            $cmd.CommandText = "ATTACH '$escapedPath' AS encrypted_db (ENCRYPTION_KEY '$escapedKey', ENCRYPTION_CIPHER '$EncryptionCipher')"
            $null = $cmd.ExecuteNonQuery()

            $cmd.CommandText = 'USE encrypted_db'
            $null = $cmd.ExecuteNonQuery()
        } finally {
            $cmd.Dispose()
        }

        Write-Verbose "Encrypted connection opened: $DbPath"
    } else {
        $conn = [DuckDB.NET.Data.DuckDBConnection]::new("DataSource=$DbPath")
        $conn.Open()
        Write-Verbose "Connection opened: $DbPath"
    }

    $conn

}
