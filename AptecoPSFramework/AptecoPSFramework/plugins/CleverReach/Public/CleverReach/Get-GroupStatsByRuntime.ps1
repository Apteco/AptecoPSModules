
<#

This call gets the group stats by runtime filter as the normal group stats are cached

#>

function Get-GroupStatsByRuntime {

    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)][String] $GroupId                               # Group ID
        , [Parameter(Mandatory=$false)][Switch] $IncludeMetrics = $false            # Add avg points and quality(stars)
        , [Parameter(Mandatory=$false)][Switch] $IncludeLastChanged = $false        # Add last groups changed date
    )

    begin {

    }

    process {


        #-----------------------------------------------
        # GET GROUP DETAILS
        #-----------------------------------------------

        # TODO [ ] put the verbose flag also on other public functions
        If ( $IncludeLastChanged -eq $true ) {
            $groupDetailParams = [Hashtable]@{
                "Object" = "groups"
                "Path" = "/$( $GroupId )"
                "Method" = "GET"
                #"Verbose" = $Verbose
            }
            $groupDetail = Invoke-CR @groupDetailParams
        }

        <#
        {
            "id": "1155236",
            "name": "Demo_Bestellungsbestätigung_20230221-101731",
            "locked": false,
            "backup": true,
            "receiver_info": "",
            "stamp": 1676971052,
            "last_mailing": 1676971142,
            "last_changed": 1676971052
        }
        #>


        #-----------------------------------------------
        # PREPARE FILTER TEMPLATE
        #-----------------------------------------------

        $filterBodyTemplate = [PSCustomObject]@{
            "groups" = [Array]@(,$GroupId)
            "operator" = "AND"
            "activeonly" = $false
            "rules" = [Array]@()
            "orderby" = "activated desc"
            "detail" = 0
        }


        #-----------------------------------------------
        # TOTAL RECEIVERS
        #-----------------------------------------------

        $totalFilterBody = $filterBodyTemplate.PsObject.Copy()
        $totalParams = [Hashtable]@{
            "Object" = "receivers"
            "Path" = "filter.json"
            "Method" = "POST"
            "Paging" = $true
            "Body" = $totalFilterBody
            #"Verbose" = $Verbose
        }
        $total = [Array]@( Invoke-CR @totalParams ) # -Verbose .PsObject.Copy() use a copy so the reference is not changed because it will used a second time


        #-----------------------------------------------
        # ACTIVE RECEIVERS
        #-----------------------------------------------

        # $activatedFilterBody = $filterBodyTemplate.PsObject.Copy()
        # $activatedFilterBody.activeonly = $true

        # $activated = [Array]@( Invoke-CR -Object "receivers" -Path "filter.json" -Method POST -Verbose -Paging -Body $activatedFilterBody ) # .PsObject.Copy() use a copy so the reference is not changed because it will used a second time
        $activated = [Array]@( $total | where-object { $_.active -eq $true } )


        #-----------------------------------------------
        # INACTIVE RECEIVERS
        #-----------------------------------------------

        # $deactivedFilterBody = $filterBodyTemplate.PsObject.Copy()
        # $deactivedFilterBody.rules = [Array]@(,
        #     [PSCustomObject]@{
        #         "field" = "deactivated"
        #         "logic" = "bg"
        #         "condition" = "1"
        #     }
        # )

        # $deactivated = [Array]@( Invoke-CR -Object "receivers" -Path "filter.json" -Method POST -Verbose -Paging -Body $deactivedFilterBody ) # .PsObject.Copy() use a copy so the reference is not changed because it will used a second time
        $deactivated = [Array]@( $total | where-object { $_.active -eq $false -and $_.deactivated -gt 1 } )


        #-----------------------------------------------
        # BOUNCED RECEIVERS
        #-----------------------------------------------

        # $bouncedFilterBody = $filterBodyTemplate.PsObject.Copy()
        # $bouncedFilterBody.rules = [Array]@(,
        #     [PSCustomObject]@{
        #         "field" = "bounced"
        #         "logic" = "bg"
        #         "condition" = "1"
        #     }
        # )

        # $bounced = [Array]@( Invoke-CR -Object "receivers" -Path "filter.json" -Method POST -Verbose -Paging -Body $bouncedFilterBody ) # .PsObject.Copy() use a copy so the reference is not changed because it will used a second time
        $bounced = [Array]@( $total | where-object { $_.active -eq $false -and $_.bounced -gt 1 } )


        #-----------------------------------------------
        # BRING STATS TOGETHER
        #-----------------------------------------------

        $stats = [PSCustomObject]@{
            "total_count" = $total.count
            "inactive_count" = $deactivated.count
            "active_count" = $activated.count
            "bounce_count" = $bounced.count
            #"order_count" = 0
        }

        If ( $IncludeMetrics -eq $true ) {
            $stats | Add-Member -MemberType NoteProperty -Name "avg_points" -Value ([math]::floor(($total.points | Measure-Object -Average).Average))
            $stats | Add-Member -MemberType NoteProperty -Name "quality" -Value ([math]::floor(($total.stars | Measure-Object -Average).Average))
        }

        If ( $IncludeLastChanged -eq $true ) {
            $stats | Add-Member -MemberType NoteProperty -Name "time" -Value $groupDetail.last_changed
        }


        #-----------------------------------------------
        # RETURN
        #-----------------------------------------------

        $stats


    }

    end {

    }

}



