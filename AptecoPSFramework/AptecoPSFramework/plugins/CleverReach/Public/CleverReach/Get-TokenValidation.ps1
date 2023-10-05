
function Get-TokenValidation {

    [CmdletBinding()]
    param (
        #[Parameter(Mandatory=$false)][Hashtable] $InputHashtable
        #[Parameter(Mandatory=$false)][String] $GroupId
    )

    begin {

    }
    process {

        $validation = Invoke-CR -Object "debug" -Path "validate.json" -Method GET -Verbose

        $validation

    }

    end {

    }

}




