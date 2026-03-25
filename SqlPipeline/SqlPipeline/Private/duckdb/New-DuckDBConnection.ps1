function New-DuckDBConnection {
    <#
    .SYNOPSIS
        Öffnet eine DuckDB-Verbindung zur angegebenen Datenbankdatei.
    .PARAMETER DbPath
        Pfad zur .db-Datei (wird angelegt falls nicht vorhanden).
    .PARAMETER EncryptionKey
        Optionaler Verschlüsselungsschlüssel (AES-256, ab DuckDB 1.4.0).
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
    Write-Verbose "Verbindung geöffnet: $DbPath"
    $conn
    
}
