

function Get-LocalDeactivated {

    [CmdletBinding()]
    param (
        #[Parameter(Mandatory=$false)][Hashtable] $InputHashtable
        [Parameter(Mandatory=$false)][String] $GroupId
    )
    
    begin {
    
    }
    process {

        # Prepare inactives query as security net
        $deactivatedLocalFilterBody = [PSCustomObject]@{
            "groups" = [Array]@(,$GroupId)
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

        $localDeactivated = @( Invoke-CR -Object "receivers" -Path "filter.json" -Method POST -Verbose -Paging -Body $deactivatedLocalFilterBody.PsObject.Copy() ) # use a copy so the reference is not changed because it will used a second time

        $localDeactivated

    }

    end {

    }

}



