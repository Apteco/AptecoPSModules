function Write-DuckDBCsv {
    <#
    .SYNOPSIS
        Writes data into a DuckDB table via a temporary CSV file and COPY FROM (fast bulk load).
    .DESCRIPTION
        Serializes PSObjects to a temp CSV file, then uses DuckDB's native COPY FROM to bulk-load
        the data. Significantly faster than the row-by-row appender for large datasets because
        DuckDB parses the CSV internally using multi-threaded C++.
        Complex objects (lists, PSCustomObject, dictionaries) are serialized to JSON strings.
        The temp file is always cleaned up, even on error.
    .PARAMETER SimpleTypesOnly
        Skip the per-cell type check for complex objects (IList, PSCustomObject, IDictionary).
        Use this when all values are guaranteed to be primitives (strings, numbers, bools, dates)
        to avoid reflection overhead at scale (N rows x M columns type checks).
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)] [DuckDB.NET.Data.DuckDBConnection]$Connection,
        [Parameter(Mandatory)] [string]$TableName,
        [Parameter(Mandatory)] $Data,
        [Parameter(Mandatory=$false)]
        [switch]$SimpleTypesOnly = $false
    )

    # Pre-serialize complex objects to JSON so Export-Csv writes them as plain strings.
    # SimpleTypesOnly: skip the loop entirely — no transformation needed.
    # Otherwise: analyse the first row to find which columns hold complex types, then
    # only run type checks + ConvertTo-Json on those columns for every subsequent row.
    if ($SimpleTypesOnly) {
        $preparedData = $Data
    } else {
        $propNames = $null
        $complexCols = $null   # HashSet of column names that need JSON serialisation
        $i = 0
        $preparedData = foreach ($row in $Data) {
            if ($null -eq $propNames) {
                $propNames = @($row.PSObject.Properties.Name)
                $complexCols = [System.Collections.Generic.HashSet[string]]::new()
                foreach ($name in $propNames) {
                    $val = $row.$name
                    if ($null -ne $val -and (
                        $val -is [System.Collections.IList] -or
                        $val -is [PSCustomObject] -or
                        $val -is [System.Collections.IDictionary])) {
                        [void]$complexCols.Add($name)
                    }
                }
            }

            if ($complexCols.Count -eq 0) {
                # No complex columns — emit the row as-is, no copy needed
                $row
            } else {
                $ht = [ordered]@{}
                foreach ($name in $propNames) {
                    $val = $row.$name
                    $ht[$name] = if ($null -ne $val -and $complexCols.Contains($name)) {
                        ConvertTo-Json -InputObject $val -Compress -Depth 10
                    } else {
                        $val
                    }
                }
                [PSCustomObject]$ht
            }
            $i++
            if ($i % 100 -eq 0) {
                Write-Verbose "[$TableName] Appender: Row $i written."
            }
        }
    }

    $tmpFile = [System.IO.Path]::Combine(
        [System.IO.Path]::GetTempPath(),
        [System.IO.Path]::GetRandomFileName() + '.csv'
    )

    try {
        Write-Verbose "[$TableName] Writing data to temporary CSV file: $tmpFile"
        $preparedData | Export-Csv -Path $tmpFile -NoTypeInformation -Encoding UTF8
        Write-Verbose "[$TableName] CSV file created. Starting COPY FROM..."
        # DuckDB requires forward slashes; NULLSTR '' maps empty strings back to NULL
        $duckPath = $tmpFile.Replace('\', '/')
        Invoke-DuckDBQuery -Connection $Connection `
            -Query "COPY $TableName FROM '$duckPath' (HEADER, NULLSTR '')"
        Write-Verbose "[$TableName] CSV COPY FROM completed: $($Data.Count) rows"
    } finally {
        if (Test-Path $tmpFile) {
            Remove-Item $tmpFile -ErrorAction SilentlyContinue
        }
    }
}
