function Invoke-BufferedWrite {
    <#
    .SYNOPSIS
        Internal helper: writes a buffer to DuckDB
        (table creation + schema sync + repair + upsert).
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)] [DuckDB.NET.Data.DuckDBConnection]$Connection,
        [Parameter(Mandatory)] [string]$TableName,
        [Parameter(Mandatory)] $Data,
        [string[]]$PKColumns = @(),
        [Parameter(Mandatory=$false)]
        [switch]$UseCsvImport = $false,
        [Parameter(Mandatory=$false)]
        [switch]$SimpleTypesOnly = $false
    )

    if ($Data.Count -eq 0) { return }

    # try/catch { throw }: .NET exceptions from DuckDB are only statement-terminating in PowerShell.
    # Rethrowing makes them terminating so Add-RowsToDuckDB and the calling script stop instead of continuing silently.
    try {

    # Use the first 100 rows for type inference so mixed-type columns
    # (e.g. integer in one row, double in another) get the correct wider type.
    $sampleRows = $Data.GetRange(0, [Math]::Min(100, $Data.Count))

    # 1. Create table if it does not exist
    Initialize-DuckDBTable -Connection $Connection -TableName $TableName `
                           -SampleRows $sampleRows -PKColumns $PKColumns

    # 2. Extend schema with new columns
    Sync-DuckDBSchema -Connection $Connection -TableName $TableName -SampleRows $sampleRows

    # 3. Normalize missing columns
    # The compiled appender looks up every table column by name on each row (missing -> NULL), so it needs no
    # normalization. Repair-DuckDBRow costs a function call plus a rebuilt object per row, which adds up on wide tables.
    # The CSV import (Export-Csv takes the columns from the first row) and the PowerShell appender still need it.
    if ($Script:isFastAppenderLoaded -and -not $UseCsvImport) {
        $normalizedData = $Data
    } else {
        $expectedCols   = Get-DuckDBColumns -Connection $Connection -TableName $TableName
        Write-Verbose "[$TableName] No of expected columns in DuckDB: $( $expectedCols.Count )" #$($expectedCols -join ', ')"
        $normalizedData = $Data | ForEach-Object {
            Repair-DuckDBRow -Row $_ -ExpectedColumns $expectedCols
        }
    }

    # 4. UPSERT or INSERT
    Invoke-DuckDBUpsert -Connection $Connection -TableName $TableName `
                        -Data $normalizedData -PKColumns $PKColumns `
                        -UseCsvImport:$UseCsvImport -SimpleTypesOnly:$SimpleTypesOnly
    # Result object (Inserts, Updates) is passed through to the caller

    } catch {
        throw
    }
}
