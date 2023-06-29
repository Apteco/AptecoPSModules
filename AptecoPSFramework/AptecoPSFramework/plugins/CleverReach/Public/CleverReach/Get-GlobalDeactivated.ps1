

function Get-GlobalDeactivated {

    [CmdletBinding()]
    param (
        #[Parameter(Mandatory=$false)][Hashtable] $InputHashtable
    )
    
    begin {
    
    }
    process {

        # Prepare inactives query as security net
        $deactivatedGlobalFilterBody = [PSCustomObject]@{
            "groups" = [Array]@()
            "operator" = "AND"
            "rules" = [Array]@(,
                [PSCustomObject]@{
                    "field" = "deactivated"
                    "logic" = "bg"
                    "condition" = "1"
                }
            )
            "orderby" = "activated desc"
            "detail" = 0
        }

        $globalDeactivated = [Array]@( Invoke-CR -Object "receivers" -Path "filter.json" -Method POST -Verbose -Paging -Body $deactivatedGlobalFilterBody ) # .PsObject.Copy() use a copy so the reference is not changed because it will used a second time

        $globalDeactivated

    }

    end {

    }

}



