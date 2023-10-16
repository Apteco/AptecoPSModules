

function Register-NewTokenViaApi {

    [CmdletBinding()]
    param (
        #[Parameter(Mandatory=$false)][Hashtable] $InputHashtable
        #[Parameter(Mandatory=$false)][String] $GroupId
    )

    begin {

    }

    process {

        $oAuthIntrospect = Invoke-SFSC -Service "oauth2" -Object "introspect" -Method "Post"        

        # $objects = Invoke-SFSC -Object "sobjects" -Method "Get"        

        # #$objects = Invoke-RestMethod -URI "$( $base )/services/data/v$( $version )/sobjects/" -Method Get -verbose -ContentType $contentType -Headers $headers
        # $obj = $objects.sobjects | where { $_.createable -eq $true } | Select-Object name, label | Out-GridView -PassThru

        $oAuthIntrospect

    }

    end {

    }

}



