


function Get-Table {

    [CmdletBinding()]
    param (
        #[Parameter(Mandatory=$false)][Hashtable] $InputHashtable
        #[Parameter(Mandatory=$false)][String] $GroupId
    )

    begin {

    }
    process {

        $tables = @( Invoke-Dynamics -Method "Get" )

        # $objects = Invoke-SFSC -Object "sobjects" -Method "Get"

        # #$objects = Invoke-RestMethod -URI "$( $base )/services/data/v$( $version )/sobjects/" -Method Get -verbose -ContentType $contentType -Headers $headers
        # $obj = $objects.sobjects | where { $_.createable -eq $true } | Select-Object name, label | Out-GridView -PassThru

        $tables.value

    }

    end {

    }

}

