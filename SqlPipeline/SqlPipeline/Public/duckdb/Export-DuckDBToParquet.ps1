function Export-DuckDBToParquet {
    <#
    .SYNOPSIS
        Exports a DuckDB table as a Parquet file (e.g. for use with external tools).
    .PARAMETER Compression
        Compression algorithm: SNAPPY (default), ZSTD, GZIP, NONE
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)] [DuckDB.NET.Data.DuckDBConnection]$Connection = $null,
        [Parameter(Mandatory)] [string]$TableName,
        [Parameter(Mandatory)] [string]$OutputPath,
        [ValidateSet('SNAPPY','ZSTD','GZIP','NONE')]
        [string]$Compression = 'ZSTD'
    )

    if ($null -eq $Connection) {
        $Connection = $Script:DefaultConnection
        if ($null -eq $Connection) { throw "No active DuckDB connection. Provide -Connection or call Initialize-SQLPipeline first." }
    }

    $dir = Split-Path $OutputPath -Parent
    if ($dir -and -not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir | Out-Null }

    Invoke-DuckDBQuery -Connection $Connection -Query @"
        COPY $TableName TO '$OutputPath'
        (FORMAT PARQUET, COMPRESSION $Compression)
"@
    Write-Information "[$TableName] Parquet exported: $OutputPath"
}
