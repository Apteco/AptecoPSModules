function Get-AptecoOrbitPagedData {
    [CmdletBinding()]

    <#
    .SYNOPSIS
        Downloads all pages of a paginated Orbit API endpoint.

    .DESCRIPTION
        Apteco PS Modules - generic Orbit API pagination / download

        Many Orbit API list endpoints return { list = [...]; totalCount = N } and expect
        offset/count query parameters for paging. This repeatedly calls Invoke-AptecoOrbit,
        advancing the offset, until every item has been collected.

    .PARAMETER Key
        The endpoint key to page through

    .PARAMETER PathParameters
        Values to substitute into the endpoint's url template

    .PARAMETER QueryParameters
        Additional, fixed query parameters to send with every page (e.g. filter/orderBy).
        Do not include the offset/count parameters here - those are managed by this function.

    .PARAMETER PageSize
        How many items to request per page. Default from module settings (100).

    .PARAMETER OffsetParameterName
        Name of the query parameter used for the paging offset. Default "offset".

    .PARAMETER CountParameterName
        Name of the query parameter used for the page size. Default "count".

    .PARAMETER ListProperty
        Name of the response property holding a page's items. Default "list".

    .PARAMETER TotalCountProperty
        Name of the response property holding the total item count. Default "totalCount".

    .EXAMPLE
        Get-AptecoOrbitPagedData -Key "GetElementStatusForDescendants" -PathParameters @{ systemName = "Demo"; elementId = 12 } -QueryParameters @{ orderBy = "-LastRan"; filter = "Type eq 'Campaign'" }

    .INPUTS
        None

    .OUTPUTS
        Array of items collected across all pages

    .NOTES
        Author:  florian.von.bracht@apteco.de

    #>

    param(
         [Parameter(Mandatory=$true)][String]$Key
        ,[Parameter(Mandatory=$false)][Hashtable]$PathParameters = @{}
        ,[Parameter(Mandatory=$false)][Hashtable]$QueryParameters = @{}
        ,[Parameter(Mandatory=$false)][Int]$PageSize = $Script:settings.pageSize
        ,[Parameter(Mandatory=$false)][String]$OffsetParameterName = "offset"
        ,[Parameter(Mandatory=$false)][String]$CountParameterName = "count"
        ,[Parameter(Mandatory=$false)][String]$ListProperty = "list"
        ,[Parameter(Mandatory=$false)][String]$TotalCountProperty = "totalCount"
    )

    $items = [System.Collections.ArrayList]@()
    $offset = 0
    $totalCount = $null

    do {

        $pageQuery = $QueryParameters.Clone()
        $pageQuery[$OffsetParameterName] = $offset
        $pageQuery[$CountParameterName] = $PageSize

        $response = Invoke-AptecoOrbit -Key $Key -PathParameters $PathParameters -QueryParameters $pageQuery

        if ( $null -eq $totalCount ) {
            $totalCount = [int]$response.$TotalCountProperty
        }

        $page = @( $response.$ListProperty )
        [void]$items.AddRange( $page )
        $offset += $PageSize

    } until ( $totalCount -eq 0 -or $offset -ge $totalCount -or $page.Count -eq 0 )

    return ,$items.ToArray()

}
