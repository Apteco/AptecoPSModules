function Invoke-BufferedWrite {
    <#
    .SYNOPSIS
        Interne Hilfsfunktion: Schreibt einen Puffer in DuckDB
        (Tabellenerstellung + Schema-Sync + Repair + Upsert).
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)] [DuckDB.NET.Data.DuckDBConnection]$Connection,
        [Parameter(Mandatory)] [string]$TableName,
        [Parameter(Mandatory)] $Data,
        [string[]]$PKColumns = @()
    )

    if ($Data.Count -eq 0) { return }

    # 1. Tabelle anlegen falls nicht vorhanden
    Initialize-DuckDBTable -Connection $Connection -TableName $TableName `
                           -SampleRow $Data[0] -PKColumns $PKColumns

    # 2. Schema erweitern (neue Felder)
    Sync-DuckDBSchema -Connection $Connection -TableName $TableName -SampleRow $Data[0]

    # 3. Fehlende Felder normalisieren
    $expectedCols   = Get-DuckDBColumns -Connection $Connection -TableName $TableName
    $normalizedData = $Data | ForEach-Object {
        Repair-DuckDBRow -Row $_ -ExpectedColumns $expectedCols
    }

    # 4. UPSERT oder INSERT
    Invoke-DuckDBUpsert -Connection $Connection -TableName $TableName `
                        -Data $normalizedData -PKColumns $PKColumns
}
