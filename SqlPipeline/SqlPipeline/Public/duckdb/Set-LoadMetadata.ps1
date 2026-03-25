function Set-LoadMetadata {
    <#
    .SYNOPSIS
        Stores the timestamp, row count, and status after a load.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)] [DuckDB.NET.Data.DuckDBConnection]$Connection = $null,
        [Parameter(Mandatory)] [string]$TableName,
        [Parameter(Mandatory)] [int]$RowsLoaded,
        [ValidateSet('success','error')]
        [string]$Status = 'success',
        [string]$ErrorMessage = ''
    )

    if ($null -eq $Connection) {
        $Connection = $Script:DefaultConnection
        if ($null -eq $Connection) { throw "No active DuckDB connection. Provide -Connection or call Initialize-SQLPipeline first." }
    }

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
