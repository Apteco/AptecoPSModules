
function Invoke-DuckDBUpsert {
    <#
    .SYNOPSIS
        Führt einen UPSERT via temporärer Staging-Tabelle + INSERT ON CONFLICT durch.
    .DESCRIPTION
        1. Daten per Appender in stg_<TableName> schreiben (schnell)
        2. INSERT INTO <TableName> … ON CONFLICT (PK) DO UPDATE SET …
        3. Staging-Tabelle droppen
    .PARAMETER PKColumns
        Primärschlüssel-Spalten für die ON CONFLICT-Klausel.
        Falls leer: reiner INSERT (kein UPSERT).
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)] [DuckDB.NET.Data.DuckDBConnection]$Connection,
        [Parameter(Mandatory)] [string]$TableName,
        [Parameter(Mandatory)] $Data,
        [string[]]$PKColumns = @()
    )

    $stagingTable = "stg_$TableName"

    # Staging anlegen
    Invoke-DuckDBQuery -Connection $Connection -Query @"
        CREATE TEMP TABLE IF NOT EXISTS $stagingTable
        AS SELECT * FROM $TableName WHERE 1 = 0
"@

    # Daten per Appender in Staging schreiben
    Write-DuckDBAppender -Connection $Connection -TableName $stagingTable -Data $Data

    if ($PKColumns.Count -gt 0) {
        # Alle Nicht-PK-Spalten für SET-Klausel ermitteln
        $allCols  = Get-DuckDBColumns -Connection $Connection -TableName $TableName
        $setCols  = $allCols | Where-Object { $_ -notin $PKColumns }
        $setClause = ($setCols | ForEach-Object { "$_ = excluded.$_" }) -join ', '
        $pkList    = $PKColumns -join ', '

        Invoke-DuckDBQuery -Connection $Connection -Query @"
            INSERT INTO $TableName
            SELECT * FROM $stagingTable
            ON CONFLICT ($pkList) DO UPDATE SET $setClause
"@
    } else {
        # Kein PK definiert – einfacher INSERT
        Invoke-DuckDBQuery -Connection $Connection -Query @"
            INSERT INTO $TableName
            SELECT * FROM $stagingTable
"@
    }

    # Staging aufräumen
    Invoke-DuckDBQuery -Connection $Connection -Query "DROP TABLE IF EXISTS $stagingTable"
    Write-Verbose "[$TableName] UPSERT abgeschlossen."
}