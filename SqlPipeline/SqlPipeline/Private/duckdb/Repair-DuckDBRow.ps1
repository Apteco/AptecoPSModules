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
        foreach ($col in $ExpectedColumns) {
            if ($null -eq $Row.PSObject.Properties[$col]) {
                $Row | Add-Member -NotePropertyName $col -NotePropertyValue $null -Force
            }
        }
        # Return columns in the correct order
        $ordered = [PSCustomObject]@{}
        foreach ($col in $ExpectedColumns) {
            $ordered | Add-Member -NotePropertyName $col `
                                  -NotePropertyValue $Row.$col -Force
        }
        $ordered
    }
}