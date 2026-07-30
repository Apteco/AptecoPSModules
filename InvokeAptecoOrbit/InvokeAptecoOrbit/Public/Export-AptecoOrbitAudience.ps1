function Export-AptecoOrbitAudience {
    [CmdletBinding()]

    <#
    .SYNOPSIS
        Exports a FastStats audience from Orbit and downloads the resulting file.

    .DESCRIPTION
        Apteco PS Modules - Orbit API audience export + download

        Mirrors a production-proven export flow: resolves the audience's export template
        columns, triggers an async export (ExportAudienceLatestUpdateSync), then polls GetFile
        until the server-side export has finished and the file is ready - retrying on both
        errors and "not ready yet" empty responses, since the export itself can take a while to
        generate.

    .PARAMETER System
        The FastStats system name the audience belongs to

    .PARAMETER AudienceId
        The id of the audience to export

    .PARAMETER WorkbookItemId
        The id of the audience's export template (workbook item) that defines which columns to export

    .PARAMETER FileName
        Name Orbit should give the export file server-side. Defaults to "export-<AudienceId>.csv"

    .PARAMETER Delimiter
        Column delimiter used in the exported file. Default is a tab character.

    .PARAMETER PollIntervalSeconds
        Seconds to wait between GetFile attempts. Default 30.

    .PARAMETER MaxPollAttempts
        Maximum number of GetFile attempts before giving up. Default 20.

    .PARAMETER OutFile
        If given, the downloaded content is saved to this path instead of being returned.

    .EXAMPLE
        Export-AptecoOrbitAudience -System "Demo" -AudienceId 246 -WorkbookItemId "7e327227-fc26-4483-b00f-1f80fa00da33" -OutFile "C:\Temp\contacts.csv"

    .EXAMPLE
        Export-AptecoOrbitAudience -System "Demo" -AudienceId 246 -WorkbookItemId "7e327227-fc26-4483-b00f-1f80fa00da33" | ConvertFrom-Csv -Delimiter "`t"

    .INPUTS
        None

    .OUTPUTS
        String - the raw exported file content (unless -OutFile is given, in which case nothing is returned)

    .NOTES
        Author:  florian.von.bracht@apteco.de

    #>

    param(
         [Parameter(Mandatory=$true)][String]$System
        ,[Parameter(Mandatory=$true)][Int]$AudienceId
        ,[Parameter(Mandatory=$true)][String]$WorkbookItemId
        ,[Parameter(Mandatory=$false)][String]$FileName = "export-$( $AudienceId ).csv"
        ,[Parameter(Mandatory=$false)][String]$Delimiter = "`t"
        ,[Parameter(Mandatory=$false)][Int]$PollIntervalSeconds = 30
        ,[Parameter(Mandatory=$false)][Int]$MaxPollAttempts = 20
        ,[Parameter(Mandatory=$false)][String]$OutFile = ""
    )

    $workbookItem = Invoke-AptecoOrbit -Key "GetAudienceWorkbookItemDetail" -PathParameters @{
        systemName             = $System
        audienceId             = $AudienceId
        audienceWorkbookItemId = $WorkbookItemId
    }

    $columns = @( $workbookItem.definition.columns | ForEach-Object {
        [PSCustomObject]@{
            id                 = $_.columnId
            variableName       = $_.scope.variableName
            columnHeader       = $_.description
            detail             = $_.exportDetail
            unclassifiedFormat = $_.exportUnclassifiedAs
            valueFormat        = $_.valueFormat
        }
    } )

    $exportBody = @{
        maximumNumberOfRowsToBrowse = 0
        returnBrowseRows            = $false
        filename                    = $FileName
        output                      = @{
            format            = "CSV"
            delimiter         = $Delimiter
            alphaEncloser     = '"'
            numericEncloser   = $null
            authorisationCode = ""
            exportExtraName   = $null
        }
        columns         = $columns
        generateUrnFile = $false
    }

    $export = Invoke-AptecoOrbit `
        -Key "ExportAudienceLatestUpdateSync" `
        -PathParameters @{ systemName = $System; audienceId = $AudienceId } `
        -ContentType "application/json-patch+json" `
        -Body $exportBody

    $content = $null

    for ( $attempt = 1; $attempt -le $MaxPollAttempts; $attempt++ ) {

        Write-Verbose "Attempt $( $attempt ) of $( $MaxPollAttempts ) to download '$( $export.filePath )'"

        try {

            $result = Invoke-AptecoOrbit -Key "GetFile" -PathParameters @{ systemName = $System; filePath = $export.filePath } -ContentType "application/octet-stream"

            if ( -not [String]::IsNullOrEmpty( "$( $result )" ) ) {
                $content = $result
                break
            }

            Write-Verbose "Export not ready yet"

        } catch {
            Write-Verbose "GetFile attempt $( $attempt ) failed: $( $_ )"
        }

        if ( $attempt -lt $MaxPollAttempts ) {
            Start-Sleep -Seconds $PollIntervalSeconds
        }

    }

    if ( $null -eq $content ) {
        throw "Export of audience $( $AudienceId ) did not produce a downloadable file after $( $MaxPollAttempts ) attempts."
    }

    if ( -not [String]::IsNullOrEmpty( $OutFile ) ) {
        Set-Content -Path $OutFile -Value $content -Encoding UTF8
        return
    }

    return $content

}
