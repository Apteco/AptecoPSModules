

function Get-Campaigns {

    [CmdletBinding()]

    # Add additional parameters to this function
    param (

    )

    Begin {

        # Get PeopleStage system
        $peopleStage = Invoke-Apteco -key "GetPeopleStageSystem" -additional @{systemName=$system} -query @{}

        # Set the starting parameters
        $campaigns = [System.Collections.ArrayList]@()
        $pageSize = 100
        $offset = 0
        $totalCampaignsCount = 0

    }

    Process {

        # Load all campaigns
        Do {

            # Do the call so in case it creates an error, jump to the next page url
            $res = Invoke-Apteco -Key "GetElementStatusForDescendants" -PathParam @{systemName=$system;elementId=$peopleStage.diagramId} -QueryParam @{offset=$offset;count=$pageSize;orderBy="-LastRan";filter="Type eq 'Campaign'"}

            # Save number of campaigns in the first call
            If ( $totalCampaignsCount -eq 0 ) {
                $totalCampaignsCount = $res.totalCount
            }

            # Prepare for the next call
            $Script:endpoints += $res.list
            $offset += $pageSize

            $campaigns.AddRange( $res.list )

        } Until ( $offset -ge $totalCampaignsCount ) 

        # Enrich campaigns list
        $campaigns | ForEach {
            $campaign = $_
            $path = $campaign.path[-1].description
            #$campaign.path
            For ( $i = ($campaign.path.count - 2); $i -ge 0 ; $i-- ) {
                $path += " >> $( $campaign.path[$i].description )"
            }
            $campaign | Add-Member -MemberType NoteProperty -Name "PathString" -Value $path
        }

    }

    end {

        # return
        $campaigns

    }

}


