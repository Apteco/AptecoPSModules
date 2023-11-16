

function Set-AllowedQueryParameter {
    [CmdletBinding()]
    param (
         [Parameter(Mandatory = $true)][String[]]$AllowedQueryParameter  # add a salt for the hash, if you wish to
        ,[Parameter(Mandatory = $false)][String]$ParameterSetName = "search" # get the params for search or reverse
    )

    begin {

    }

    process {
        $Script:allowedQueryParameters.$ParameterSetName = $AllowedQueryParameter
    }

    end {

    }
}