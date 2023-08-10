

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

        # Load mailings data from CleverReach
        $param = [PSCustomObject]@{
            order = "changed DESC" # TODO put this maybe into settings
        }
        $groups = Invoke-CR -Object "groups" -Query $param -Method "GET" -Verbose
        Write-Log "Loaded $( $groups.Count ) groups from CleverReach" -severity INFO #-WriteToHostToo $false

        # Load and filter list into array of mailings objects
        $groupsList = [System.Collections.ArrayList]@()
        $groups | ForEach-Object {
            $group = $_
            [void]$groupsList.add(
                [MailingList]@{
                    mailingListId=$group.id
                    mailingListName=$group.name
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

