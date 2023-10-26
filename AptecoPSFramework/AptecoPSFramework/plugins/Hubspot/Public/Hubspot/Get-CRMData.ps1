

function Get-CRMData {

    [CmdletBinding(DefaultParameterSetName='SingleProps')]
    param (
        #[Parameter(Mandatory=$false)][Hashtable] $InputHashtable
         [Parameter(Mandatory=$true)][String]$Object                            # Which object to load like contacts
        ,[Parameter(Mandatory=$false)][int]$Limit = 100                         # Limit the number of records in this result
        ,[Parameter(Mandatory=$false)][Switch]$Archived = $false                # Load also archived records
        ,[Parameter(Mandatory=$false)][Switch]$LoadAllRecords = $false          # To just load all records, us this flag -> this uses paging
        ,[Parameter(Mandatory=$false)][Switch]$AddWrapper = $false              # Include the wrapper with id, properties, createdAt, updatedAt, archived and optionally associations
        ,[Parameter(Mandatory=$false)][Array]$Associations = [Array]@()         # e.g. Companies,Contacts to get connections to other objects/tables
        ,[Parameter(Mandatory=$false)][Array]$Filter = [Array]@()               # An Array of [Ordered]@{"propertyName"="hubspotscore";"operator"="GTE";"value"="0"}
        ,[Parameter(Mandatory=$false)][Array]$Sort = [Array]@()                 # An Array of properties names to use for sorting
        ,[Parameter(Mandatory=$false,ParameterSetName='SingleProps')][Array]$Properties = [Array]@()    # Load single properties
        ,[Parameter(Mandatory=$false,ParameterSetName='AllProps')][Switch]$LoadAllProperties = $false   # OR load all properties of this object/table
    )

    begin {

        #-----------------------------------------------
        # CREATE AN EMPTY BODY FIRST
        #-----------------------------------------------

        $body = [PSCustomObject]@{}


        #-----------------------------------------------
        # DECIDE TO LOAD ARCHIVED
        #-----------------------------------------------

        $loadArchived = $false
        If ( $Archived -eq $true ) {
            $loadArchived = $true
        }


        #-----------------------------------------------
        # HANDLE PROPERTIES TO LOAD
        #-----------------------------------------------

        $propertiesString = ""
        Switch ( $PSCmdlet.ParameterSetName ) {

            "AllProps" {

                If ( $LoadAllProperties -eq $true ) {
                    $propertiesArray = ( get-property -Object contacts ).name
                } else {
                    throw "No properties used" # In theory this case shouldn't happen
                }

            }

            "SingleProps" {
                $propertiesArray = $Properties
            }

        }


        #-----------------------------------------------
        # BUILD THE QUERY
        #-----------------------------------------------

        # TODO after is a parameter for paging
        # TODO if $LoadAllRecords then use paging
        $query = [PSCustomObject]@{
            "archived" = $loadArchived
            "properties" = $propertiesArray -join "," #$propertiesString
            "limit" = $Limit
        }


        #-----------------------------------------------
        # ADD ASSOCIATIONS
        #-----------------------------------------------

        If ( $Associations.Count -gt 0 ) {
            $query | Add-Member -MemberType NoteProperty -Name "associations" -Value ( $Associations -join "," )
        }


        #-----------------------------------------------
        # TRANSFORM FILTER
        #-----------------------------------------------

        # If a filter is used, we need to send the parameters in the body unformatted instead of strings in the url query
        If ( $Filter.Count -gt 0 ) {

            # Copy the query parameters and empty the query
            $body = $query.PSObject.copy()
            $query = [PSCustomObject]@{}

            # Set some parameters new
            $body.properties = $propertiesArray # send this unformatted because it will be translated in json later
            If ( $Associations.Count -gt 0 ) {
                $body.associations = $Associations
            }
            #$body.PSObject.Properties.Remove("archived")

            # Add sort and filter
            $body | Add-Member -MemberType NoteProperty -Name "sorts" -Value $Sort # TODO maybe put this in the invoke for paging?
            $body | Add-Member -MemberType NoteProperty -Name "filterGroups" -Value (
                [Array]@(
                    [PSCustomObject]@{
                        "filters" = $Filter
                    }
                )
            )

            #Write-Verbose ( $body | convertto-json -depth 99 ) -verbose

        }

    }

    process {


        #-----------------------------------------------
        # LOAD THE DATA
        #-----------------------------------------------

        If ( $LoadAllRecords -eq $true ) {
            $usePaging = $true
        } else {
            $usePaging = $false
        }

        $requestParams = [Hashtable]@{
            "Object" = "crm"
            "Paging" = $usePaging
        }

        If ( $body.PSObject.Properties.Count -gt 0 ) {
            $requestParams.Add("Path", "objects/$( $Object )/search")
            $requestParams.Add("Body", $body)
            $requestParams.Add("Method", "POST")
        } else {
            $requestParams.Add("Path", "objects/$( $Object )")
            $requestParams.Add("Query", $query)
            $requestParams.Add("Method", "GET")
        }

        $records = @( Invoke-Hubspot @requestParams )


        #-----------------------------------------------
        # RETURN
        #-----------------------------------------------

        If ( $AddWrapper -eq $true ) {
            $records.results
        } else {
            $records.results.properties
        }


    }

    end {

    }

}
