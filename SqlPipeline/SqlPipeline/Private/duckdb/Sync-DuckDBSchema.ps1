function Sync-DuckDBSchema {
    <#
    .SYNOPSIS
        Vergleicht die API-Daten mit dem bestehenden Tabellenschema und fügt
        neue Spalten per ALTER TABLE ADD COLUMN hinzu.
    .DESCRIPTION
        Felder, die in der API nicht mehr geliefert werden, bleiben unverändert
        in der Tabelle (erhalten NULL-Werte beim nächsten Load).
        Neue Felder aus der API werden automatisch ergänzt.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)] [DuckDB.NET.Data.DuckDBConnection]$Connection,
        [Parameter(Mandatory)] [string]$TableName,
        [Parameter(Mandatory)] $SampleRow
    )

    $existingCols = Get-DuckDBColumns -Connection $Connection -TableName $TableName
    $incomingCols = $SampleRow.PSObject.Properties.Name

    $newCols = $incomingCols | Where-Object { $_ -notin $existingCols }

    if ($newCols.Count -eq 0) {
        Write-Verbose "[$TableName] Schema ist aktuell – keine neuen Spalten."
        return
    }

    foreach ($col in $newCols) {
        $sqlType = ConvertTo-DuckDBType -Value $SampleRow.$col
        Write-Host "[$TableName] Neue Spalte: $col ($sqlType)"
        Invoke-DuckDBQuery -Connection $Connection -Query `
            "ALTER TABLE $TableName ADD COLUMN IF NOT EXISTS $col $sqlType"
    }
}