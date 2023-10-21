
function Get-LookupMappings {

    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)][String]$TableName
        #[Parameter(Mandatory=$false)][String] $GroupId
    )

    begin {

    }
    process {

        $metadata = @( Invoke-Dynamics -Method "Get" -Path "lookupmappings" )

        # $objects = Invoke-SFSC -Object "sobjects" -Method "Get"

        # #$objects = Invoke-RestMethod -URI "$( $base )/services/data/v$( $version )/sobjects/" -Method Get -verbose -ContentType $contentType -Headers $headers
        # $obj = $objects.sobjects | where { $_.createable -eq $true } | Select-Object name, label | Out-GridView -PassThru

        $metadata

    }

    end {

    }

}
