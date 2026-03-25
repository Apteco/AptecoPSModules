function Write-DuckDBAppender {
    <#
    .SYNOPSIS
        Schreibt Daten über den DuckDB Appender in eine Tabelle (reiner INSERT, schnell).
    .DESCRIPTION
        Alle Rows müssen bereits normalisiert sein (Repair-DuckDBRow).
        Die Spaltenreihenfolge im PSObject muss der Tabellenreihenfolge entsprechen.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)] [DuckDB.NET.Data.DuckDBConnection]$Connection,
        [Parameter(Mandatory)] [string]$TableName,
        [Parameter(Mandatory)] $Data
    )

    $appender = $Connection.CreateAppender($TableName)

    foreach ($row in $Data) {
        $appenderRow = $appender.CreateRow()
        foreach ($prop in $row.PSObject.Properties) {
            $val = ConvertTo-DuckDBValue -Value $prop.Value
            [void]$appenderRow.AppendValue($val)
        }
        $appenderRow.EndRow()
    }

    $appender.Close()
    Write-Verbose "[$TableName] Appender abgeschlossen."
}
