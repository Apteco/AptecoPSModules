

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


    }

    process {


        #-----------------------------------------------
        # LOAD MAILINGS
        #-----------------------------------------------

        # TODO load this later from the settings.json
        # This collection could be loaded from an ESP through REST
        $msg = [System.Collections.ArrayList]::new()
        [void]$msg.add(
            [PSCustomObject]@{
                id = "1"
                name = "Message 1"
            }
        )
        [void]$msg.add(
            [PSCustomObject]@{
                id = "2"
                name = "Message 2"
            }
        )
        [void]$msg.add(
            [PSCustomObject]@{
                id = "3"
                name = "Message 3"
            }
        )

        Write-Log "Loaded $( $msg.Count ) mailing drafts from Dummy" -severity INFO #-WriteToHostToo $false


        #-----------------------------------------------
        # FILTER LOADED MAILINGS AND TRANSFORM
        #-----------------------------------------------

        # Load and filter list into array of mailings objects
        $mailingsList = [System.Collections.ArrayList]::new()
        $msg | ForEach-Object {
            $mailing = $_
            [void]$mailingsList.add(
                [Mailing]@{
                    mailingId=$mailing.id
                    mailingName=$mailing.name
                }
            )
        }


        #-----------------------------------------------
        # FORMAT FOR OUTPUT INTO APTECO
        #-----------------------------------------------

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

        $messages = [System.Collections.ArrayList]::new()
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

