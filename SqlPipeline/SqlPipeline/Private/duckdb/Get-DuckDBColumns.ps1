function Get-DuckDBColumns {
    <#
    .SYNOPSIS
        Gibt die Spaltennamen einer DuckDB-Tabelle als String-Array zurück.
    #>
    [CmdletBinding()]
    [OutputType([string[]])]
    param(
        [Parameter(Mandatory)] [DuckDB.NET.Data.DuckDBConnection]$Connection,
        [Parameter(Mandatory)] [string]$TableName
    )

    $result = Get-DuckDBData -Connection $Connection -Query "DESCRIBE '$TableName'"
    #return @($result.Rows | ForEach-Object { $_['column_name'] })
    
    # return
    $result.column_name

}
