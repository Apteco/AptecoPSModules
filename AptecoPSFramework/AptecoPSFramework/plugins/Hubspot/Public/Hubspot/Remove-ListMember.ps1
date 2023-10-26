

function Remove-ListMember {

    [CmdletBinding(DefaultParameterSetName='SingleProps')]
    param (
         [Parameter(Mandatory=$true)][String]$ListId                            # The ILS-List-ID
        ,[Parameter(Mandatory=$true)][Array]$RemoveMemberships = [Array]@()        # Array of IDs to remove of the marketing list
    )

    begin {

    }

    process {


        #-----------------------------------------------
        # UPLOAD THE DATA
        #-----------------------------------------------

        $records = Invoke-Hubspot -Method PUT -Object "crm" -Path "lists/$( $ListId )/memberships/remove" -Body $RemoveMemberships


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
