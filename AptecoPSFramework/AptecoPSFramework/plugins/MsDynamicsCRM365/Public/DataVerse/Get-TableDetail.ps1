




function Get-TableDetail {

    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)][String[]] $TableName
        #[Parameter(Mandatory=$false)][String] $GroupId
    )

    begin {

    }
    process {

        # Read more details: https://learn.microsoft.com/de-de/power-apps/developer/data-platform/webapi/query-metadata-web-api
        
        $tables = Get-Record -TableName EntityDefinitions -filter "Microsoft.Dynamics.CRM.In(PropertyName='EntitySetName',PropertyValues=['$(( $TableName -join "','" ))'])"

        $tables

    }

    end {

    }

}



