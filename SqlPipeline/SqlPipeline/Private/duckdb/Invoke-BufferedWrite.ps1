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

    # 1. Create table if it does not exist
    Initialize-DuckDBTable -Connection $Connection -TableName $TableName `
                           -SampleRow $Data[0] -PKColumns $PKColumns

    # 2. Extend schema with new columns
    Sync-DuckDBSchema -Connection $Connection -TableName $TableName -SampleRow $Data[0]

    # 3. Normalize missing columns
    $expectedCols   = Get-DuckDBColumns -Connection $Connection -TableName $TableName
    $normalizedData = $Data | ForEach-Object {
        Repair-DuckDBRow -Row $_ -ExpectedColumns $expectedCols
    }

    # 4. UPSERT or INSERT
    Invoke-DuckDBUpsert -Connection $Connection -TableName $TableName `
                        -Data $normalizedData -PKColumns $PKColumns `
                        -UseCsvImport:$UseCsvImport -SimpleTypesOnly:$SimpleTypesOnly
}
