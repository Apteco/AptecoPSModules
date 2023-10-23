


function Get-Contact {

    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$false)][Switch] $ResolveLookups = $false
        #[Parameter(Mandatory=$false)][String] $GroupId
    )

    begin {

    }
    process {

        # If ( $ResolveLookups -eq $true ) {
        #     $header = [Hashtable]@{
        #         "Prefer" = 'odata.include-annotations="*"'
        #     }
        #     $contacts = @( Invoke-Dynamics -Path "contacts" -Method "Get" -Headers $header )
        # } else {
        #     $contacts = @( Invoke-Dynamics -Path "contacts" -Method "Get" )
        # }

        $callParams = [Hashtable]@{
            "Path"="contacts"
        }

        If ( $ResolveLookups -eq $true ) {
            $callParams.Add("ResolveLookups",$true)
        }

        $contacts = Get-Record @callParams -ResolveLookups

        # TODO implement limit and id lookup

        $contacts

    }

    end {

    }

}

