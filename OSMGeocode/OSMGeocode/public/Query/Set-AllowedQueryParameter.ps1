

function Set-AllowedQueryParameter {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)][String[]]$AllowedQueryParameter  # add a salt for the hash, if you wish to
    )

    begin {

    }

    process {
        $Script:allowedQueryParameters = $AllowedQueryParameter
    }

    end {

    }
}