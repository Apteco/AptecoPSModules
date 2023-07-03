

function Get-CRGroups {

    [CmdletBinding()]
    param (
        #[Parameter(Mandatory=$false)][Hashtable] $InputHashtable
        #[Parameter(Mandatory=$false)][String] $GroupId
    )
    
    begin {
    
    }
    process {

        $groups = Invoke-CR -Object "groups" -Method GET -Verbose

        $groups

    }

    end {

    }

}



