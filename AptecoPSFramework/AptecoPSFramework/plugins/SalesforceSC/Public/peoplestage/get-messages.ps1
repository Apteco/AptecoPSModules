

function Get-Messages {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$false)][Hashtable] $InputHashtable = [Hashtable]@{}
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

        #Switch ( $InputHashtable.mode ) {

            #default {

                # Load mailings data from SalesForce
                $campaigns = @( Get-SFSCObjectData -Object "Campaign" -Fields @("Id", "Name") -Limit 200 )
                #$campaigns = Invoke-SFSCQuery -query "select id, name from campaign" -IncludeAttributes
                # $queryObj = [PSCustomObject]@{
                #     "q" = "select id, name from campaign limit 100"
                # }
                # $campaignsRes = Invoke-SFSC -Service "data" -Object "query" -Query $queryObj -Method "Get"
                # $campaigns = $campaignsRes.records
                Write-Log "Loaded $( $campaigns.Count ) campaigns from Salesforce" -severity INFO #-WriteToHostToo $false

                # Load and filter list into array of mailings objects
                $mailingsList = [System.Collections.ArrayList]@()
                $campaigns | ForEach-Object {
                    $mailing = $_
                    $maxLength = $mailing.Name.length
                    If ($maxLength -lt 20) {
                        $l = $maxLength
                    } else {
                        $l = 20
                    }
                    [void]$mailingsList.add(
                        [Mailing]@{
                            "mailingId" = $mailing.Id.substring(11)
                            "mailingName" = $mailing.Name #.substring(0,$l)
                        }
                    )
                }

            #}

        #}


        # fields, id, name, status, type, StartDate, EndDate, ...
        # Get-SFSCObjectField -object "Campaign" | Out-GridView

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

