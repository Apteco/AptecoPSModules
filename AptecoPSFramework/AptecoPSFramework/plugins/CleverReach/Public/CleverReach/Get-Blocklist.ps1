

function Get-Blocklist {

    [CmdletBinding()]
    param (
        #[Parameter(Mandatory=$false)][Hashtable] $InputHashtable
        #[Parameter(Mandatory=$false)][String] $GroupId
    )

    begin {

    }
    process {

        $blocklist = Invoke-CR -Object "blacklist" -Method GET -Verbose

        $blocklist

    }

    end {

    }

}



