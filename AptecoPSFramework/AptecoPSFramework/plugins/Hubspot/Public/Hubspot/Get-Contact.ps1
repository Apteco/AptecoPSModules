

function Get-Contact {

    [CmdletBinding()]
    param (
        #[Parameter(Mandatory=$false)][Hashtable] $InputHashtable
         [Parameter(Mandatory=$false)][int]$Limit = 10
        ,[Parameter(Mandatory=$false)][Array]$Properties = [Array]@()
        ,[Parameter(Mandatory=$false)][Switch]$Archived = $false
        ,[Parameter(Mandatory=$false)][Switch]$LoadAllRecords = $false
        ,[Parameter(Mandatory=$false)][Switch]$LoadAllProperties = $false
    )

    begin {

    }
    process {

        # $loadArchived = $false
        # If ( $Archived -eq $true ) {
        #     $loadArchived = $true
        # }

        $crmParam = [Hashtable]@{
            "Object" = "contacts"
            "Limit" = $Limit
            "Properties" = $Properties
            "Archived" = $Archived
            "LoadAllRecords" = $LoadAllRecords
            "LoadAllProperties" = $LoadAllProperties
        }


        $records = @( Get-CRMData @crmParam )

        $records

    }

    end {

    }

}
