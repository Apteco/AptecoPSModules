

function Get-CRMData {

    [CmdletBinding()]
    param (
        #[Parameter(Mandatory=$false)][Hashtable] $InputHashtable
         [Parameter(Mandatory=$true)][String]$Object
        ,[Parameter(Mandatory=$false)][int]$Limit = 10
        ,[Parameter(Mandatory=$false)][Switch]$Archived = $false
        ,[Parameter(Mandatory=$false)][Switch]$LoadAllRecords = $false
        ,[Parameter(Mandatory=$false,ParameterSetName='SingleProps')][Array]$Properties = [Array]@()
        ,[Parameter(Mandatory=$false,ParameterSetName='AllProps')][Switch]$LoadAllProperties = $false
    )

    begin {

    }
    process {

        $loadArchived = $false
        If ( $Archived -eq $true ) {
            $loadArchived = $true
        }

        $propertiesString = ""
        Switch ( $PSCmdlet.ParameterSetName ) {

            "AllProps" {

                If ( $LoadAllProperties -eq $true ) {
                    $propertiesString = ( get-property -Object contacts ).name -join ","
                } else {
                    throw "No properties used" # In theory this case shouldn't happen
                }

            }

            "SingleProps" {
                $propertiesString = $Properties -join ","
            }

        }


        # TODO after is a parameter for paging
        # TODO if $LoadAllRecords then use paging

        $query = [PSCustomObject]@{
            "archived" = $loadArchived
            "properties" = $propertiesString
            "limit" = $Limit
        }

        $records = @( Invoke-Hubspot -Object "crm" -Path "objects/$( $Object )" -Query $query -Method GET )

        $records.results

    }

    end {

    }

}
