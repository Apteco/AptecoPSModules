function Repair-DuckDBRow {
    <#
    .SYNOPSIS
        Füllt fehlende Spalten (nicht mehr von der API geliefert) mit $null auf,
        sodass der Appender immer alle Tabellenspalten befüllen kann.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, ValueFromPipeline)] $Row,
        [Parameter(Mandatory)] [string[]]$ExpectedColumns
    )

    process {
        foreach ($col in $ExpectedColumns) {
            if ($null -eq $Row.PSObject.Properties[$col]) {
                $Row | Add-Member -NotePropertyName $col -NotePropertyValue $null -Force
            }
        }
        # Spalten in der richtigen Reihenfolge zurückgeben
        $ordered = [PSCustomObject]@{}
        foreach ($col in $ExpectedColumns) {
            $ordered | Add-Member -NotePropertyName $col `
                                  -NotePropertyValue $Row.$col -Force
        }
        $ordered
    }
}