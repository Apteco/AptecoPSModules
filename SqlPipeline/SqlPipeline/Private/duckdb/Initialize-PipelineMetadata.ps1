function Initialize-PipelineMetadata {
    <#
    .SYNOPSIS
        Creates the _load_metadata table if it does not already exist.
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
    Write-Verbose 'Metadata table ready.'
}
