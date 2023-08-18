

function Get-GroupSegments {

    [CmdletBinding()]
    param (
        #[Parameter(Mandatory=$false)][Hashtable] $InputHashtable
        [Parameter(Mandatory=$true)][String] $GroupId
    )

    begin {

    }
    process {

        $filters = Invoke-CR -Object "groups" -Path "/$( $GroupId )/filters" -Method GET -Verbose

        $filters

    }

    end {

    }

}



