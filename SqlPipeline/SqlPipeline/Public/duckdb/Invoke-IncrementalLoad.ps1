function Invoke-IncrementalLoad {
    <#
    .SYNOPSIS
        Runs a full incremental API load into a DuckDB table.
    .DESCRIPTION
        End-to-end orchestration of an incremental load:
        1. Read the last successful load timestamp from _load_metadata
        2. Call the API (via a ScriptBlock that accepts -Since)
        3. Create the table if it doesn't exist yet (from the fetched rows)
        4. Extend the schema if the API returned new fields
        5. Fill in fields no longer returned by the API with $null
        6. UPSERT via a staging table + appender
        7. Store the timestamp and status in _load_metadata
    .PARAMETER Connection
        Open DuckDB connection. Defaults to $Script:DefaultConnection (set via Initialize-SQLPipeline).
    .PARAMETER TableName
        Name of the target table in DuckDB.
    .PARAMETER PKColumns
        Primary key columns for the UPSERT. Empty = plain INSERT.
    .PARAMETER ApiFetcher
        ScriptBlock that calls the API. Receives -Since [datetime] and must return an array of PSObjects.
    .EXAMPLE
        Invoke-IncrementalLoad -TableName 'orders' -PKColumns @('order_id') -ApiFetcher {
            param($Since)
            Invoke-RestMethod "https://api.example.com/orders?since=$Since"
        }
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)] [DuckDB.NET.Data.DuckDBConnection]$Connection = $null,
        [Parameter(Mandatory)] [string]$TableName,
        [string[]]$PKColumns = @(),
        [Parameter(Mandatory)] [scriptblock]$ApiFetcher
    )

    if ($null -eq $Connection) {
        $Connection = $Script:DefaultConnection
        if ($null -eq $Connection) { throw "No active DuckDB connection. Provide -Connection or call Initialize-SQLPipeline first." }
    }

    Write-Verbose "[$TableName] Starting incremental load..."

    try {

        # 1. Get last load timestamp
        $since = Get-LastLoadTimestamp -Connection $Connection -TableName $TableName
        Write-Verbose "[$TableName] Loading data since: $since"

        # 2. Call the API
        $data = & $ApiFetcher -Since $since

        if ($null -eq $data) { $data = @() }
        if ($data -isnot [array]) { $data = @($data) }

        if ($data.Count -eq 0) {
            Write-Verbose "[$TableName] No new data."
            Set-LoadMetadata -Connection $Connection -TableName $TableName -RowsLoaded 0 -Status 'success'
            return
        }

        Write-Verbose "[$TableName] Received $($data.Count) records."

        # 3. Create table if it doesn't exist yet
        Initialize-DuckDBTable -Connection $Connection -TableName $TableName -SampleRows $data -PKColumns $PKColumns

        # 4. Extend schema (new fields)
        Sync-DuckDBSchema -Connection $Connection -TableName $TableName -SampleRows $data

        # 5. Normalize missing fields (columns no longer returned by the API)
        $expectedCols = Get-DuckDBColumns -Connection $Connection -TableName $TableName

        $normalizedData = $data | ForEach-Object {
            Repair-DuckDBRow -Row $_ -ExpectedColumns $expectedCols
        }

        # 6. UPSERT
        $result = Invoke-DuckDBUpsert -Connection $Connection -TableName $TableName -Data $normalizedData -PKColumns $PKColumns

        # 7. Store success
        Set-LoadMetadata -Connection $Connection -TableName $TableName -RowsLoaded $data.Count -Status 'success'

        Write-Verbose "[$TableName] Loaded $($data.Count) rows successfully (Inserts: $($result.Inserts), Updates: $($result.Updates))."

    } catch {

        $errMsg = $_.Exception.Message
        Write-Warning "[$TableName] Error: $errMsg"

        try {
            Set-LoadMetadata -Connection $Connection -TableName $TableName -RowsLoaded 0 -Status 'error' -ErrorMessage $errMsg
        } catch {
            Write-Warning "[$TableName] Error while saving error status: $_"
        }

        throw

    }

}
