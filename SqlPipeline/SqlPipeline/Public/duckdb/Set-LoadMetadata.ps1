function Set-LoadMetadata {
    <#
    .SYNOPSIS
        Speichert Timestamp, Zeilenzahl und Status nach einem Load.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)] [DuckDB.NET.Data.DuckDBConnection]$Connection,
        [Parameter(Mandatory)] [string]$TableName,
        [Parameter(Mandatory)] [int]$RowsLoaded,
        [ValidateSet('success','error')]
        [string]$Status = 'success',
        [string]$ErrorMessage = ''
    )

    $ts  = (Get-Date).ToString('yyyy-MM-dd HH:mm:ss')
    $err = $ErrorMessage -replace "'", "''"

    Invoke-DuckDBQuery -Connection $Connection -Query @"
        INSERT INTO _load_metadata (table_name, last_loaded, rows_loaded, status, error_msg)
        VALUES ('$TableName', TIMESTAMP '$ts', $RowsLoaded, '$Status', '$err')
        ON CONFLICT (table_name) DO UPDATE SET
            last_loaded = excluded.last_loaded,
            rows_loaded = excluded.rows_loaded,
            status      = excluded.status,
            error_msg   = excluded.error_msg
"@
}