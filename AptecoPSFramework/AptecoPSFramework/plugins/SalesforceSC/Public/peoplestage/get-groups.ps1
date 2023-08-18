

function Get-Groups {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$false)][Hashtable] $InputHashtable
        #[Parameter(Mandatory=$false)][Switch] $DebugMode = $false
    )

    begin {


        #-----------------------------------------------
        # LOG
        #-----------------------------------------------

        $moduleName = "GETGROUPS"

        # Start the log
        Write-Log -message $Script:logDivider
        Write-Log -message $moduleName -Severity INFO

        # Log the params, if existing
        Write-Log -message "INPUT:"
        if ( $InputHashtable ) {
            $InputHashtable.Keys | ForEach-Object {
                $param = $_
                Write-Log -message "    $( $param ) = '$( $InputHashtable[$param] )'" -writeToHostToo $false
            }
        }

        #-----------------------------------------------
        # DEPENDENCIES
        #-----------------------------------------------

        #Import-Module MeasureRows
        #Import-Module SqlServer
        #Import-Module ConvertUnixTimestamp
        #Import-Lib -IgnorePackageStructure

    }

    process {

        # Load campaign member status data from Salesforce
        #$campaignMembers = @( Invoke-SFSCQuery -Query "Select Id, Label, CampaignId from CampaignMemberStatus where IsDeleted = false" )
        #$groups = $campaignMembers |  where-object { $_.CampaignId -ne "7010O000001CuXxQAK" } | group-object Label | Select-Object @{name="id";expression={ $lbyte=[System.Text.Encoding]::UTF8.GetBytes($_.Name);[Convert]::ToBase64String($lbyte) }}, Name
        $groups = ( Get-SFSCObjectField -Object "CampaignMember" | where-object { $_.Name -eq "Status" } ).picklistValues | where-object { $_.active -eq $true }

        Write-Log "Loaded $( $groups.Count ) status from Salesforce" -severity INFO #-WriteToHostToo $false

        # Load and filter list into array of mailings objects
        $groupsList = [System.Collections.ArrayList]@()
        $groups | ForEach-Object {
            $group = $_
            [void]$groupsList.add(
                [MailingList]@{
                    "mailingListId" = $group.value #$group.Id.replace("=","") #Prefix 01Y0O00000 for status id, prefix 7010O000001 for campaign
                    "mailingListName" = $group.label
                }
            )
        }

        # Transform the mailings array into the needed output format
        $columns = @(
            @{
                name="id"
                expression={ $_.mailingListId }
            }
            @{
                name="name"
                expression={ $_.toString() }
            }
        )

        $lists = [System.Collections.ArrayList]@()
        [void]$lists.AddRange(@( $groupsList | Select-Object $columns ))

        If ( $lists.count -gt 0 ) {

            Write-Log "Loaded $( $lists.Count ) lists/groups" -severity INFO #-WriteToHostToo $false

        } else {

            $msg = "No lists loaded -> please check!"
            Write-Log -Message $msg -Severity ERROR
            throw [System.IO.InvalidDataException] $msg

        }

        # Return
        $lists

    }

    end {

    }

}

