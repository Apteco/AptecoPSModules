function ConvertTo-DuckDBValue {
    <#
    .SYNOPSIS
        Konvertiert einen PS-Wert in einen für DuckDB geeigneten Wert.
        Komplexe Objekte (Listen, PSCustomObject) werden nach JSON serialisiert.
    #>
    [CmdletBinding()]
    param($Value)

    if ($null -eq $Value) { return [DBNull]::Value }
    if ($Value -is [System.Collections.IList] -or
        $Value -is [PSCustomObject] -or
        $Value -is [System.Collections.IDictionary]) {
        return ($Value | ConvertTo-Json -Compress -Depth 10)
    }
    return $Value
}