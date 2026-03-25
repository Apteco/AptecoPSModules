function Export-DuckDBToParquet {
    <#
    .SYNOPSIS
        Exportiert eine DuckDB-Tabelle als Parquet-Datei (z.B. für externe Tools).
    .PARAMETER Compression
        Kompressionsalgorithmus: SNAPPY (Standard), ZSTD, GZIP, NONE
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)] [DuckDB.NET.Data.DuckDBConnection]$Connection,
        [Parameter(Mandatory)] [string]$TableName,
        [Parameter(Mandatory)] [string]$OutputPath,
        [ValidateSet('SNAPPY','ZSTD','GZIP','NONE')]
        [string]$Compression = 'ZSTD'
    )

    $dir = Split-Path $OutputPath -Parent
    if ($dir -and -not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir | Out-Null }

    Invoke-DuckDBQuery -Connection $Connection -Query @"
        COPY $TableName TO '$OutputPath'
        (FORMAT PARQUET, COMPRESSION $Compression)
"@
    Write-Host "[$TableName] Parquet exportiert: $OutputPath" -ForegroundColor Green
}
