

function Get-CRMData {

    [CmdletBinding()]
    param (
        #[Parameter(Mandatory=$false)][Hashtable] $InputHashtable
         [Parameter(Mandatory=$true)][String]$Object
        ,[Parameter(Mandatory=$false)][int]$Limit = 10
        ,[Parameter(Mandatory=$false)][Array]$Properties = [Array]@()
        ,[Parameter(Mandatory=$false)][Switch]$Archived = $false
        ,[Parameter(Mandatory=$false)][Switch]$LoadAllRecords = $false
        ,[Parameter(Mandatory=$false)][Switch]$LoadAllProperties = $false
    )

    begin {

    }
    process {

        $loadArchived = $false
        If ( $Archived -eq $true ) {
            $loadArchived = $true
        }

        If ( $LoadAllProperties -eq $true ) {

        }

        # TODO after is a parameter for paging
        # TODO if $LoadAllRecords then use paging

        $query = [PSCustomObject]@{
            "archived" = $loadArchived
            "properties" = $Properties -join ","
            "limit" = $Limit
        }

        $records = @( Invoke-Hubspot -Object "crm" -Path "objects/$( $Object )" -Query $query -Method GET )

        $records.results

    }

    end {

    }

}
