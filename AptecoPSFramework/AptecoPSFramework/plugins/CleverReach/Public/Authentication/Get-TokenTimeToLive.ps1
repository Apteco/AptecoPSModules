

function Get-TokenTimeToLive {

    [CmdletBinding()]
    param (
        #[Parameter(Mandatory=$false)][Hashtable] $InputHashtable
        #[Parameter(Mandatory=$false)][String] $GroupId
    )

    begin {

    }
    process {

        $ttl = Invoke-CR -Object "debug" -Path "ttl.json" -Method GET #-Verbose

        $ttl

    }

    end {

    }

}



