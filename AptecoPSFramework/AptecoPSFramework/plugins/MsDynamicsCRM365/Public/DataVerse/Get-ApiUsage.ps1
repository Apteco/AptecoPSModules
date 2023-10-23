

function Get-ApiUsage {

    [CmdletBinding()]
    param (
        #[Parameter(Mandatory=$false)][Hashtable] $InputHashtable
        # [Parameter(Mandatory=$true)][String]$Object
        #,[Parameter(Mandatory=$false)][Switch]$Archived = $false
    )

    begin {

    }
    process {

        # Create a call if usage is not filled yet
        #If ( $Script:variableCache.Keys -notcontains "api_rate_limit" ) {
            #$usage = @( Invoke-Hubspot -Object "account-info" -Path "api-usage/daily" -Method GET )
        #}

        #https://api.hubapi.com/crm/v3/objects/contacts?limit=1&archived=false

        # Put a message on the console
        Write-Verbose "Remaining $( $Script:variableCache.api_rate_remaining )" -verbose

        # Return
        #$Script:variableCache.api_rate_remaining
        #$usage

    }

    end {

    }

}



