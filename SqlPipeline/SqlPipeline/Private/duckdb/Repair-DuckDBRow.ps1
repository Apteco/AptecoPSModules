function Repair-DuckDBRow {
    <#
    .SYNOPSIS
        Fills missing columns (no longer provided by the data source) with $null,
        so the appender can always populate all table columns.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, ValueFromPipeline)] $Row,
        [Parameter(Mandatory)] [string[]]$ExpectedColumns
    )

    process {
        $props = $Row.PSObject.Properties
        $ht = [ordered]@{}
        foreach ($col in $ExpectedColumns) {
            $prop = $props[$col]
            $ht[$col] = if ($null -ne $prop) { $prop.Value } else { $null }
        }
        [PSCustomObject]$ht
    }
}