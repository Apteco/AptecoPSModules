

function Add-ListMember {

    [CmdletBinding(DefaultParameterSetName='SingleProps')]
    param (
         [Parameter(Mandatory=$true)][String]$ListId                            # The ILS-List-ID
        ,[Parameter(Mandatory=$true)][Array]$AddMemberships = [Array]@()        # Array of IDs to add to the marketing list
    )

    begin {

    }

    process {

        
        #-----------------------------------------------
        # UPLOAD THE DATA
        #-----------------------------------------------
        
        $records = Invoke-Hubspot -Method PUT -Object "crm" -Path "lists/$( $ListId )/memberships/add" -Body $AddMemberships


        #-----------------------------------------------
        # RETURN
        #-----------------------------------------------

        # If ( $AddWrapper -eq $true ) {
        #     $records.results
        # } else {
        #     $records.results.properties
        # }
        $records

    }

    end {

    }

}
