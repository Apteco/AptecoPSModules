

function Register-NewTokenViaApi {

    [CmdletBinding()]
    param (
        #[Parameter(Mandatory=$false)][Hashtable] $InputHashtable
        #[Parameter(Mandatory=$false)][String] $GroupId
    )

    begin {

    }
    process {

        $newToken = Invoke-CR -Object "debug" -Path "exchange.json" -Method GET -Verbose

        $newToken

    }

    end {

    }

}



