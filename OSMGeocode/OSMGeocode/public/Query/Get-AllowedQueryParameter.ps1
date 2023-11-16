

function Get-AllowedQueryParameter {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)][String]$ParameterSetName = "search" # get the params for search or reverse
    )

    begin {

    }

    process {
        $Script:allowedQueryParameters.$ParameterSetName
    }

    end {

    }
}