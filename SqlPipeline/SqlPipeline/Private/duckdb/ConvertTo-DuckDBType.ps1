function ConvertTo-DuckDBType {
    <#
    .SYNOPSIS
        Leitet den DuckDB-SQL-Typ aus einem PowerShell-Wert ab.
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param($Value)

    if ($null -eq $Value)                                    { return 'VARCHAR' }
    if ($Value -is [bool])                                   { return 'BOOLEAN' }
    if ($Value -is [int] -or $Value -is [long])              { return 'BIGINT'  }
    if ($Value -is [double] -or $Value -is [float] -or
        $Value -is [decimal])                                { return 'DOUBLE'  }
    if ($Value -is [datetime])                               { return 'TIMESTAMP' }
    if ($Value -is [System.Collections.IList])               { return 'JSON'    }
    if ($Value -is [PSCustomObject] -or
        $Value -is [System.Collections.IDictionary])         { return 'JSON'    }
    # ISO-Datumsstring erkennen
    if ($Value -is [string] -and
        $Value -match '^\d{4}-\d{2}-\d{2}(T|\s)\d{2}:\d{2}') { return 'TIMESTAMP' }
    return 'VARCHAR'
}