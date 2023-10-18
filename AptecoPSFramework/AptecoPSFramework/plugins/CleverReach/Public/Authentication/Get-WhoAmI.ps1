

function Get-WhoAmI {

    [CmdletBinding()]
    param (
        #[Parameter(Mandatory=$false)][Hashtable] $InputHashtable
        #[Parameter(Mandatory=$false)][String] $GroupId
    )

    begin {

    }
    process {

        $whoAmI = Invoke-CR -Object "debug" -Path "whoami.json" -Method GET #-Verbose

        $whoAmI

    }

    end {

    }

}



