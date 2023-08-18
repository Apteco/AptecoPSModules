

function Get-SFSCObjectData {

    [CmdletBinding()]
    param (
        #[Parameter(Mandatory=$false)][Hashtable] $InputHashtable
        [Parameter(Mandatory=$true)][String] $Object
        ,[Parameter(Mandatory=$false)][String[]] $Fields = [Array]@() # If not defined, all fields are loaded like *
        ,[Parameter(Mandatory=$false)][int] $limit = 100
    )

    begin {

    }
    process {
        
        # curl https://MyDomainName.my.salesforce.com/services/data/v58.0/query/?q=SELECT+name+from+Account -H "Authorization: Bearer token"

        If ( $fields.count -eq 0 ) {

            # Get all fields
            $fieldsResult = Get-SFSCObjectField -Object $Object
            $fieldList = ( $fields | select-object name ) -join ", "

        } else {
            $fieldList = $Fields -join ", "
        }

        $query = "SELECT $( $fieldList ) FROM $( $Object ) LIMIT $( $limit )"

        $result = @( Invoke-SFSCQuery -Query $query -IncludeAttributes ) #Invoke-SFSC -Service "data" -Object "query" -Path "$( $Object )" -Query $query -Method "Get" 

        #$objects = Invoke-RestMethod -URI "$( $base )/services/data/v$( $version )/sobjects/" -Method Get -verbose -ContentType $contentType -Headers $headers
        <#
        $result = [Array]@(
            [PSCustomObject]@{
                Id = "a"
                Name = "asdfasd"
            }
            [PSCustomObject]@{
                Id = "b"
                Name = "gdfgfg"
            }
        )
        #>

        #return 
        $result #| where-object { $_.createable -eq $true } | Select-Object name, label | Out-GridView -PassThru
        
    }

    end {

    }

}