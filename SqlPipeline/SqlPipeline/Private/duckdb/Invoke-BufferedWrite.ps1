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

    # Use the first 100 rows for type inference so mixed-type columns
    # (e.g. integer in one row, double in another) get the correct wider type.
    $sampleRows = $Data.GetRange(0, [Math]::Min(100, $Data.Count))

    # 1. Create table if it does not exist
    Initialize-DuckDBTable -Connection $Connection -TableName $TableName `
                           -SampleRows $sampleRows -PKColumns $PKColumns

    # 2. Extend schema with new columns
    Sync-DuckDBSchema -Connection $Connection -TableName $TableName -SampleRows $sampleRows

    # 3. Normalize missing columns
    $expectedCols   = Get-DuckDBColumns -Connection $Connection -TableName $TableName
    Write-Verbose "[$TableName] Expected columns in DuckDB: $($expectedCols -join ', ')"
    $normalizedData = $Data | ForEach-Object {
        Repair-DuckDBRow -Row $_ -ExpectedColumns $expectedCols
    }

    # 4. UPSERT or INSERT
    Invoke-DuckDBUpsert -Connection $Connection -TableName $TableName `
                        -Data $normalizedData -PKColumns $PKColumns `
                        -UseCsvImport:$UseCsvImport -SimpleTypesOnly:$SimpleTypesOnly
    # Result object (Inserts, Updates) is passed through to the caller
}
