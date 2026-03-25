function Initialize-PipelineMetadata {
    <#
    .SYNOPSIS
        Erstellt die _load_metadata-Tabelle falls nicht vorhanden.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)] [DuckDB.NET.Data.DuckDBConnection]$Connection
    )

    Invoke-DuckDBQuery -Connection $Connection -Query @"
        CREATE TABLE IF NOT EXISTS _load_metadata (
            table_name   VARCHAR PRIMARY KEY,
            last_loaded  TIMESTAMP,
            rows_loaded  BIGINT,
            status       VARCHAR,
            error_msg    VARCHAR
        )
"@
    Write-Verbose 'Metadaten-Tabelle bereit.'
}
