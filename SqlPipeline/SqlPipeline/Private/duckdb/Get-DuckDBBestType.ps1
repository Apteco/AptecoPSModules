function Get-DuckDBBestType {
    <#
    .SYNOPSIS
        Returns the widest DuckDB SQL type that can represent all non-null values
        in $Values. Used for multi-row type inference.
    .DESCRIPTION
        Iterates over the values and widens the inferred type whenever a conflict
        is detected:
          BOOLEAN  + BIGINT  → BIGINT
          BOOLEAN  + DOUBLE  → DOUBLE
          BIGINT   + DOUBLE  → DOUBLE
          All other conflicts → VARCHAR
        Null values are skipped. Returns VARCHAR when all values are null.
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory)] $Values
    )

    $current = $null

    foreach ($v in $Values) {
        if ($null -eq $v) { continue }

        $t = ConvertTo-DuckDBType -Value $v

        if ($null -eq $current) {
            $current = $t
            continue
        }
        if ($current -eq $t) { continue }

        # Determine the wider of the two types.
        # Sort alphabetically so the switch key is order-independent.
        $a, $b = ($current, $t) | Sort-Object
        $current = switch ("$a+$b") {
            'BIGINT+BOOLEAN'   { 'BIGINT';  break }
            'BIGINT+DOUBLE'    { 'DOUBLE';  break }
            'BOOLEAN+DOUBLE'   { 'DOUBLE';  break }
            default            { 'VARCHAR'; break }
        }

        if ($current -eq 'VARCHAR') { break }   # Can't get wider — exit early
    }

    if ($null -eq $current) { return 'VARCHAR' }
    return $current
}
