function Write-DuckDBAppender {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)] [DuckDB.NET.Data.DuckDBConnection]$Connection,
        [Parameter(Mandatory)] [string]$TableName,
        [Parameter(Mandatory)] $Data,
        [Parameter(Mandatory=$false)]
        [switch]$SimpleTypesOnly = $false
    )

    # Read column types from schema so we can cast numeric values correctly.
    # DuckDB.NET's AppendValue reinterprets bytes rather than converting when
    # the .NET type does not match the column type (e.g. Int64 into a DOUBLE
    # column yields 7.4e-323 instead of 15).
    $columnTypes = @{}
    $schemaCmd = $Connection.CreateCommand()
    $schemaCmd.CommandText = "DESCRIBE ""$TableName"""
    $schemaReader = $schemaCmd.ExecuteReader()
    while ($schemaReader.Read()) {
        $columnTypes[$schemaReader.GetString(0)] = $schemaReader.GetString(1)
    }
    $schemaReader.Close()
    $schemaCmd.Dispose()

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

            # Cast values to the declared column type so DuckDB.NET picks the
            # correct AppendValue overload. Without this:
            #   [long] → DOUBLE   reinterprets raw bytes (15 becomes 7.4e-323)
            #   [bool] → BIGINT   throws "Cannot write Boolean to BigInt column"
            #   [long] → VARCHAR  throws "Cannot write Int64 to Varchar column"
            if ($null -ne $val -and $columnTypes.ContainsKey($name)) {
                $colType  = $columnTypes[$name]
                $isFloat  = $colType -eq 'DOUBLE'  -or $colType -eq 'FLOAT' -or
                            $colType -eq 'REAL'    -or $colType -eq 'FLOAT4' -or $colType -eq 'FLOAT8'
                $isInt    = $colType -eq 'BIGINT'  -or $colType -eq 'INTEGER' -or
                            $colType -eq 'HUGEINT' -or $colType -eq 'INT8'   -or $colType -eq 'INT4'

                if ($val -is [bool] -and $colType -ne 'BOOLEAN') {
                    # bool cannot be appended to non-BOOLEAN columns
                    if     ($isFloat) { $val = [double][int]$val }
                    elseif ($isInt)   { $val = [long][int]$val }
                    else              { $val = [string]$val }
                } elseif ($val -is [long] -and $isFloat) {
                    $val = [double]$val
                } elseif ($val -is [double] -and $isInt) {
                    $val = [long]$val
                } elseif ($colType -eq 'VARCHAR' -and ($val -is [long] -or $val -is [double])) {
                    $val = [string]$val
                }
            }
            # Inlined ConvertTo-DuckDBValue
            if ($null -eq $val) {
                # AppendValue([DBNull]::Value) has wrong overload resolution on typed
                # columns (e.g. resolves to AppendValue(bool) for DOUBLE). Use the
                # dedicated AppendNullValue() method instead.
                [void]$appenderRow.AppendNullValue()
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
