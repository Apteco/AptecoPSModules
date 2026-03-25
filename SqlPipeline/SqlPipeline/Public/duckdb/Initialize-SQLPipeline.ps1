function Initialize-SQLPipeline {
    <#
    .SYNOPSIS
        Öffnet eine DuckDB-Verbindung und initialisiert die Metadaten-Tabelle.
        Gibt die Verbindung zurück.

    .EXAMPLE
        $conn = Initialize-SQLPipeline -DbPath '.\pipeline.db'
        # ... Loads ...
        Close-DuckDBConnection -Connection $conn
    #>
    [CmdletBinding()]
    [OutputType([DuckDB.NET.Data.DuckDBConnection])]
    param(
        [Parameter(Mandatory)] [string]$DbPath,
        [string]$EncryptionKey
        #[string]$LibPath = '.\lib'
    )

    $absolutePath = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($DbPath)
    $params = @{ DbPath = $absolutePath }
    if ($EncryptionKey) { $params['EncryptionKey'] = $EncryptionKey }

    $conn = New-DuckDBConnection @params
    Initialize-PipelineMetadata -Connection $conn
    Write-Host "SQLPipeline initialisiert: $absolutePath" -ForegroundColor Cyan
    
    # return
    $conn
    
}
