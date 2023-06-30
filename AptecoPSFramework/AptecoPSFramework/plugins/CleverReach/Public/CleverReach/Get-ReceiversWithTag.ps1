# Source is the first part of the Tag, so apteco.a1qhvh3_20230607201732 split in "apteco" as source and "a1qhvh3_20230607201732" as tag

function Get-ReceiversWithTag {

    [CmdletBinding()]
    param (
        #[Parameter(Mandatory=$false)][Hashtable] $InputHashtable
         [Parameter(Mandatory=$true)][String] $Source
        ,[Parameter(Mandatory=$true)][String] $Tag
        ,[Parameter(Mandatory=$false)][String] $Detail = 0
    )
    
    begin {
    
    }
    process {

        # TODO possibly use array rather than single tag

        # Prepare inactives query as security net
        $filterBody = [PSCustomObject]@{
            "groups" = [Array]@()
            "operator" = "AND"
            "rules" = [Array]@(,
                [PSCustomObject]@{
                    "field" = "tags"
                    "logic" = "contains"
                    "condition" = "$( $Source ).$( $Tag )"
                }
            )
            "orderby" = "activated desc"
            "detail" = 0
        }

        $receiversWithTag = [Array]@( Invoke-CR -Object "receivers" -Path "filter.json" -Method POST -Verbose -Paging -Body $filterBody ) # .PsObject.Copy() use a copy so the reference is not changed because it will used a second time

        $receiversWithTag

    }

    end {

    }

}



