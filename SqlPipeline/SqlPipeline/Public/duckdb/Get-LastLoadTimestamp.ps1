function Get-LastLoadTimestamp {
    <#
    .SYNOPSIS
        Returns the timestamp of the last successful load.
        Fallback: 2000-01-01 (= first load / full load).
    #>
    [CmdletBinding()]
    [OutputType([datetime])]
    param(
        [Parameter(Mandatory=$false)] [DuckDB.NET.Data.DuckDBConnection]$Connection = $null,
        [Parameter(Mandatory)] [string]$TableName
    )

    if ($null -eq $Connection) {
        $Connection = $Script:DefaultConnection
        if ($null -eq $Connection) { throw "No active DuckDB connection. Provide -Connection or call Initialize-SQLPipeline first." }
    }

    $result = Get-DuckDBData -Connection $Connection -Query @"
        SELECT last_loaded
        FROM   _load_metadata
        WHERE  table_name = '$TableName'
          AND  status = 'success'
"@

    if ($result.Rows.Count -eq 0) {
        Write-Verbose "[$TableName] No previous load found - performing full load."
        return [datetime]'2000-01-01'
    }
    return [datetime]$result.Rows[0]['last_loaded']
}
