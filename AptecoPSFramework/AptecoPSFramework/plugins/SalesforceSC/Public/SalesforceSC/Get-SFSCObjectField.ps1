




function Get-SFSCObjectField {

    [CmdletBinding()]
    param (
        #[Parameter(Mandatory=$false)][Hashtable] $InputHashtable
        [Parameter(Mandatory=$true)][String] $Object
    )

    begin {

    }
    process {


        $fields = Invoke-SFSC -Service "data" -Object "sobjects" -Path "$( $Object )/describe/" -Method "Get" 

        #$objects = Invoke-RestMethod -URI "$( $base )/services/data/v$( $version )/sobjects/" -Method Get -verbose -ContentType $contentType -Headers $headers
        
        #return 
        $fields.fields #| where-object { $_.createable -eq $true } | Select-Object name, label | Out-GridView -PassThru
        
    }

    end {

    }

}


