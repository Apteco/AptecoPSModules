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
    $propNames  = $null   # column names, cached from first row
    $colAction  = $null   # [int[]] per-column action: 0=passthrough 1=float-col 2=int-col 3=varchar-col
    $complexCols = $null  # HashSet of columns that hold complex types (null when SimpleTypesOnly)

    $i = 0
    foreach ($row in $Data) {
        $i++

        # On the first row: cache propNames, pre-compute per-column schema actions,
        # and (unless SimpleTypesOnly) scan for complex-typed columns.
        # This moves all hashtable lookups and string comparisons out of the hot path.
        if ($null -eq $propNames) {
            $propNames = @($row.PSObject.Properties.Name)

            # Encode schema coercion rules as integers so the inner loop only needs
            # an array index + switch(int) — no hashtable lookups or string compares.
            #   0 = no schema entry / BOOLEAN / other  → passthrough
            #   1 = float column  (DOUBLE / FLOAT / REAL / FLOAT4 / FLOAT8)
            #   2 = int column    (BIGINT / INTEGER / HUGEINT / INT8 / INT4)
            #   3 = varchar column (VARCHAR)
            $colAction = [int[]]::new($propNames.Count)
            for ($ci = 0; $ci -lt $propNames.Count; $ci++) {
                $ct = $columnTypes[$propNames[$ci]]
                if ($null -ne $ct) {
                    if ($ct -eq 'DOUBLE' -or $ct -eq 'FLOAT' -or $ct -eq 'REAL' -or $ct -eq 'FLOAT4' -or $ct -eq 'FLOAT8') {
                        $colAction[$ci] = 1
                    } elseif ($ct -eq 'BIGINT' -or $ct -eq 'INTEGER' -or $ct -eq 'HUGEINT' -or $ct -eq 'INT8' -or $ct -eq 'INT4') {
                        $colAction[$ci] = 2
                    } elseif ($ct -eq 'VARCHAR') {
                        $colAction[$ci] = 3
                    }
                }
            }

            # For non-SimpleTypesOnly: record which columns carry complex objects on
            # the first row so subsequent rows only call -is/ConvertTo-Json on those.
            if (-not $SimpleTypesOnly) {
                $complexCols = [System.Collections.Generic.HashSet[string]]::new()
                foreach ($name in $propNames) {
                    $v = $row.$name
                    if ($null -ne $v -and (
                        $v -is [System.Collections.IList] -or
                        $v -is [PSCustomObject] -or
                        $v -is [System.Collections.IDictionary])) {
                        [void]$complexCols.Add($name)
                    }
                }
            }
        }

        $appenderRow = $appender.CreateRow()
        for ($ci = 0; $ci -lt $propNames.Count; $ci++) {
            $val = $row.($propNames[$ci])

            if ($null -eq $val) {
                # AppendValue([DBNull]::Value) has wrong overload resolution on typed
                # columns (e.g. resolves to AppendValue(bool) for DOUBLE). Use the
                # dedicated AppendNullValue() method instead.
                [void]$appenderRow.AppendNullValue()
                continue
            }

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
            switch ($colAction[$ci]) {
                1 { # float column
                    if     ($val -is [bool]) { $val = [double][int]$val }
                    elseif ($val -is [long]) { $val = [double]$val }
                }
                2 { # int column
                    if     ($val -is [bool])   { $val = [long][int]$val }
                    elseif ($val -is [double]) { $val = [long]$val }
                }
                3 { # varchar column
                    if ($val -is [long] -or $val -is [double]) { $val = [string]$val }
                }
            }

            if ($null -ne $complexCols -and $complexCols.Contains($propNames[$ci]) -and (
                $val -is [System.Collections.IList] -or
                $val -is [PSCustomObject] -or
                $val -is [System.Collections.IDictionary])) {
                [void]$appenderRow.AppendValue((ConvertTo-Json -InputObject $val -Compress -Depth 10))
            } else {
                [void]$appenderRow.AppendValue($val)
            }
        }
        $appenderRow.EndRow()

        if ($i % 100 -eq 0) {
            Write-Verbose "[$TableName] Appender: Row $i written."
        }
    }

    $appender.Close()
    $appender.Dispose()
    Write-Verbose "[$TableName] Appender finished."
}
