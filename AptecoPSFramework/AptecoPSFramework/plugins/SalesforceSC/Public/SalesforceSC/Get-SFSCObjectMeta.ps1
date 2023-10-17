




function Get-SFSCObjectMeta {

    [CmdletBinding()]
    param (
        #[Parameter(Mandatory=$false)][Hashtable] $InputHashtable
        [Parameter(Mandatory=$true)][String] $Object
    )

    begin {

    }
    process {

        $meta = Invoke-SFSC -Service "data" -Object "sobjects" -Path "$( $Object )" -Method "Get"
        #$objects = Invoke-RestMethod -URI "$( $base )/services/data/v$( $version )/sobjects/" -Method Get -verbose -ContentType $contentType -Headers $headers

        #return
        $meta.objectDescribe

    }

    end {

    }

}


