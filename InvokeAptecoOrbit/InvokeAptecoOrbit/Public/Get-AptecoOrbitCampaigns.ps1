function Get-AptecoOrbitCampaigns {
    [CmdletBinding()]

    <#
    .SYNOPSIS
        Downloads the full campaign list of a PeopleStage system, including its folder path.

    .DESCRIPTION
        Apteco PS Modules - Orbit API campaign download

        Resolves the PeopleStage system's diagram, then downloads every campaign element under
        it (paged via Get-AptecoOrbitPagedData) and adds a human readable "PathString" property
        built from each campaign's folder path.

    .PARAMETER System
        The PeopleStage system name to list campaigns for

    .PARAMETER PageSize
        Page size used for the underlying paged download. Default from module settings (100).

    .EXAMPLE
        Get-AptecoOrbitCampaigns -System "Demo"

    .INPUTS
        None

    .OUTPUTS
        Array of campaign objects, each with an added PathString property

    .NOTES
        Author:  florian.von.bracht@apteco.de

    #>

    param(
         [Parameter(Mandatory=$true)][String]$System
        ,[Parameter(Mandatory=$false)][Int]$PageSize = $Script:settings.pageSize
    )

    $peopleStage = Invoke-AptecoOrbit -Key "GetPeopleStageSystem" -QueryParameters @{ systemName = $System }

    $campaigns = Get-AptecoOrbitPagedData `
        -Key "GetElementStatusForDescendants" `
        -PathParameters @{ systemName = $System; elementId = $peopleStage.diagramId } `
        -QueryParameters @{ orderBy = "-LastRan"; filter = "Type eq 'Campaign'" } `
        -PageSize $PageSize

    foreach ( $campaign in $campaigns ) {

        $path = $campaign.path[-1].description
        for ( $i = $campaign.path.Count - 2; $i -ge 0; $i-- ) {
            $path += " >> $( $campaign.path[$i].description )"
        }
        $campaign | Add-Member -MemberType NoteProperty -Name "PathString" -Value $path -Force

    }

    return $campaigns

}
