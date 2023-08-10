
<#

This call gets the group stats by runtime filter as the normal group stats are cached

#>

function Get-GroupStats {

    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)][String] $GroupId
    )

    begin {

    }

    process {

        $groupStatsParams = [Hashtable]@{
            "Object" = "groups"
            "Path" = "/$( $GroupId )/stats"
            "Method" = "GET"
            #"Verbose" = $Verbose
        }
        $groupStats = Invoke-CR @groupStatsParams

        <#
        {
            "total_count": 4,
            "inactive_count": 0,
            "active_count": 4,
            "bounce_count": 0,
            "avg_points": 69.5,
            "quality": 3,
            "time": 1685545449,
            "order_count": 0
        }
        #>

        $groupStats


    }

    end {

    }

}



