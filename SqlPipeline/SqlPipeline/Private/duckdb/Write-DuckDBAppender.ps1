function Write-DuckDBAppender {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)] [DuckDB.NET.Data.DuckDBConnection]$Connection,
        [Parameter(Mandatory)] [string]$TableName,
        [Parameter(Mandatory)] $Data,
        [Parameter(Mandatory=$false)]
        [switch]$SimpleTypesOnly = $false
    )

    $appender = $Connection.CreateAppender($TableName)
    $propNames = $null  # cached once from first row

    $i = 0
    foreach ($row in $Data) {
        $i++

        # Cache property names from first row only
        if ($null -eq $propNames) {
            $propNames = @($row.PSObject.Properties.Name)
        }

        $appenderRow = $appender.CreateRow()
        foreach ($name in $propNames) {
            $val = $row.$name
            # Normalize integer subtypes to Int64 before any other check,
            # because DuckDB.NET appender has no Int32 overload and PowerShell
            # would otherwise fall back to AppendValue(string).
            if ($val -is [int] -or $val -is [System.Int16] -or $val -is [byte] -or $val -is [uint16] -or $val -is [uint32]) {
                $val = [long]$val
            } elseif ($val -is [float]) {
                $val = [double]$val
            }
            # Inlined ConvertTo-DuckDBValue
            if ($null -eq $val) {
                [void]$appenderRow.AppendValue([DBNull]::Value)
            } elseif (-not $SimpleTypesOnly -and (
                      $val -is [System.Collections.IList] -or
                      $val -is [PSCustomObject] -or
                      $val -is [System.Collections.IDictionary])) {
                [void]$appenderRow.AppendValue((ConvertTo-Json -InputObject $val -Compress -Depth 10))
            } else {
                [void]$appenderRow.AppendValue($val)
            }
        }
        $appenderRow.EndRow()

        If ( $i % 10000 -eq 0 ) {
            Write-Verbose "[$TableName] Appender: Row $i written."
        }
    }

    $appender.Close()
    $appender.Dispose()
    Write-Verbose "[$TableName] Appender finished."
}
