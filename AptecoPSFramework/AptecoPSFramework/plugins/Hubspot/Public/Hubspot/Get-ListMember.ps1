

function Get-ListMember {

    [CmdletBinding(DefaultParameterSetName='SingleProps')]
    param (
         [Parameter(Mandatory=$true)][String]$ListId                            # The ILS-List-ID
        ,[Parameter(Mandatory=$false)][int]$Limit = 100                         # Limit the number of records in this result
        ,[Parameter(Mandatory=$false)][Switch]$LoadAllRecords = $false          # To just load all records, us this flag -> this uses paging
        #,[Parameter(Mandatory=$true)][Array]$AddMemberships = [Array]@()        # Array of IDs to add to the marketing list
    )

    begin {

        #-----------------------------------------------
        # BUILD THE QUERY
        #-----------------------------------------------

        $query = [PSCustomObject]@{
            "limit" = $Limit
        }

    }

    process {

        
        #-----------------------------------------------
        # LOAD THE DATA
        #-----------------------------------------------

        If ( $LoadAllRecords -eq $true ) {
            $records = Invoke-Hubspot -Method GET -Object "crm" -Path "lists/$( $ListId )/memberships" -Query $query -paging
        } else {
            $records = Invoke-Hubspot -Method GET -Object "crm" -Path "lists/$( $ListId )/memberships" -Query $query
        }
        

        #-----------------------------------------------
        # RETURN
        #-----------------------------------------------

        # If ( $AddWrapper -eq $true ) {
        #     $records.results
        # } else {
        #     $records.results.properties
        # }
        $records.results

    }

    end {

    }

}
