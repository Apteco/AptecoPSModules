
function Get-List {

    [CmdletBinding()]
    param (
         [Parameter(Mandatory=$false)][String]$Query = ""               # Search strings for list names
        ,[Parameter(Mandatory=$false)][Array]$Properties = [Array]@()   # Load single properties
        ,[Parameter(Mandatory=$false)][int]$Count = 100                 # Limit the number of lists in this result
        ,[Parameter(Mandatory=$false)][int]$Offset = 0                  # Used to paginate
        ,[Parameter(Mandatory=$false)][Switch]$LoadAllLists = $false    # To just load all records, us this flag -> this uses paging
    )

    begin {


        #-----------------------------------------------
        # NOTES
        #-----------------------------------------------

        <#
        Properties to use
            hs_list_size
            hs_last_record_added_at
            hs_last_record_removed_at
            hs_folder_name
            hs_list_reference_count
            hs_list_size_week_delta
        #>
        

        #-----------------------------------------------
        # CREATE THE BASIC BODY FIRST
        #-----------------------------------------------

        $body = [PSCustomObject]@{
            "count" = $Count
            "offset" = $Offset
        }

        If ( $Properties.Count -gt 0 ) {
            $body | Add-Member -MemberType NoteProperty -Name "properties" -Value $Properties
        }

        If ( $Query -ne "" ) {
            $body | Add-Member -MemberType NoteProperty -Name "query" -Value $Query
        }
        

    }
    process {

        # This paging is different than to all other objects, so doing it here directly
        $result = [System.Collections.ArrayList]@()
        Do {
            $records = Invoke-Hubspot -Method "POST" -Body $body -Object "crm" -Path "lists/search"
            [void]$result.addrange( $records.lists )
            $body.offset += $Count
        } while ( $records.hasMore -eq $true -and $LoadAllLists -eq $true)

        # return
        $result

    }

    end {

    }

}
