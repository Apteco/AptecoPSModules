

function Get-Messages {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$false)][Hashtable] $InputHashtable
        #[Parameter(Mandatory=$false)][Switch] $DebugMode = $false
    )

    begin {


        #-----------------------------------------------
        # LOG
        #-----------------------------------------------

        $moduleName = "GETMESSAGES"

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

Switch ( $InputHashtable.mode ) {

    "taggingOnly" {

        # Load mailings data from CleverReach
        $param = [PSCustomObject]@{
            "group_id" = "0"
            "origin" = "*"
            "order_by" = "tag"
            "limit" = $Script:settings.mailingLimit
            "page" = 0
        }
        $tags = Invoke-CR -Object "tags" -Query $param -Method "GET" -Verbose
        Write-Log "Loaded $( $mailings.draft.Count ) tags from CleverReach" -severity INFO #-WriteToHostToo $false

        # Load and filter list into array of mailings objects
        $mailingsList = [System.Collections.ArrayList]@()
        $tags | ForEach-Object {
            $tag = $_
            [void]$mailingsList.add(
                [Mailing]@{
                    mailingId="$( $tag.origin ).$( $tag.tag )"
                    mailingName="$( $tag.origin ).$( $tag.tag )"
                }
            )
        }

    }

    default {

        # Load mailings data from CleverReach
        $param = [PSCustomObject]@{
            "state" = "draft"
            "limit" = $Script:settings.mailingLimit
        }
        $mailings = Invoke-CR -Object "mailings" -Query $param -Method "GET" -Verbose
        Write-Log "Loaded $( $mailings.draft.Count ) mailing drafts from CleverReach" -severity INFO #-WriteToHostToo $false

        # Load and filter list into array of mailings objects
        $mailingsList = [System.Collections.ArrayList]@()
        $mailings.draft | ForEach-Object {
            $mailing = $_
            [void]$mailingsList.add(
                [Mailing]@{
                    mailingId=$mailing.id
                    mailingName=$mailing.name
                }
            )
        }

    }

}





        # Transform the mailings array into the needed output format
        $columns = @(
            @{
                name="id"
                expression={ $_.mailingId }
            }
            @{
                name="name"
                expression={ $_.toString() }
            }
        )

        $messages = [System.Collections.ArrayList]@()
        [void]$messages.AddRange(@( $mailingsList | Select-Object $columns ))

        If ( $messages.count -gt 0 ) {

            Write-Log "Loaded $( $messages.Count ) messages" -severity INFO #-WriteToHostToo $false

        } else {

            $msg = "No messages loaded -> please check!"
            Write-Log -Message $msg -Severity ERROR
            throw [System.IO.InvalidDataException] $msg

        }

        # Return
        $messages

    }

    end {

    }

}

