function Initialize-DuckDBTable {
    <#
    .SYNOPSIS
        Legt eine Tabelle anhand eines PSObject-Beispieldatensatzes an, falls sie noch nicht existiert.
    .PARAMETER Connection
        Offene DuckDB-Verbindung.
    .PARAMETER TableName
        Name der Zieltabelle.
    .PARAMETER SampleRow
        Ein PSObject, dessen Properties als Spalten verwendet werden.
    .PARAMETER PKColumns
        Primärschlüssel-Spalten (optional, aber für UPSERT empfohlen).
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)] [DuckDB.NET.Data.DuckDBConnection]$Connection,
        [Parameter(Mandatory)] [string]$TableName,
        [Parameter(Mandatory)] $SampleRow,
        [string[]]$PKColumns = @()
    )

    if (Test-DuckDBTableExists -Connection $Connection -TableName $TableName) {
        Write-Verbose "[$TableName] Tabelle bereits vorhanden."
        return
    }

    Write-Host "[$TableName] Tabelle wird neu angelegt..."

    $colDefs = $SampleRow.PSObject.Properties | ForEach-Object {
        $sqlType = ConvertTo-DuckDBType -Value $_.Value
        "    $($_.Name)  $sqlType"
    }

    $pkDef = if ($PKColumns.Count -gt 0) {
        ",`n    PRIMARY KEY ($($PKColumns -join ', '))"
    } else { '' }

    Invoke-DuckDBQuery -Connection $Connection -Query @"
        CREATE TABLE $TableName (
$($colDefs -join ",`n")
$pkDef
        )
"@
    Write-Host "[$TableName] Tabelle angelegt mit $($colDefs.Count) Spalten."
}
