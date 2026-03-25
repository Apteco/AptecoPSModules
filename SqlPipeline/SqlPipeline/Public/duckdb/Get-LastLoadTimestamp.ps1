function Get-LastLoadTimestamp {
    <#
    .SYNOPSIS
        Gibt den Timestamp des letzten erfolgreichen Loads zurück.
        Fallback: 2000-01-01 (= Erstbeladung / Fullload).
    #>
    [CmdletBinding()]
    [OutputType([datetime])]
    param(
        [Parameter(Mandatory)] [DuckDB.NET.Data.DuckDBConnection]$Connection,
        [Parameter(Mandatory)] [string]$TableName
    )

    $result = Get-DuckDBData -Connection $Connection -Query @"
        SELECT last_loaded
        FROM   _load_metadata
        WHERE  table_name = '$TableName'
          AND  status = 'success'
"@

    if ($result.Rows.Count -eq 0) {
        Write-Verbose "[$TableName] Kein vorheriger Load - Erstbeladung."
        return [datetime]'2000-01-01'
    }
    #return [datetime]$result.Rows[0]['last_loaded']
    return [datetime]$result['last_loaded']
}
