function ConvertTo-DuckDBValue {
    <#
    .SYNOPSIS
        Converts a PowerShell value into a value suitable for DuckDB.
        Complex objects (lists, PSCustomObject) are serialized to JSON.
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