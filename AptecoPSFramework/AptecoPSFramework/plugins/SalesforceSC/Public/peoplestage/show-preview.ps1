



function Show-Preview {

    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$false)][Hashtable] $InputHashtable
    )

    begin {


        #-----------------------------------------------
        # START TIMER
        #-----------------------------------------------

        $processStart = [datetime]::now


        #-----------------------------------------------
        # LOG
        #-----------------------------------------------

        $moduleName = "PREVIEW"

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
        # PARSE MESSAGE
        #-----------------------------------------------

        Write-Log "Parsing message: '$( $InputHashtable.MessageName )' with '$( $Script:settings.nameConcatChar )'"
        $mailing = [Mailing]::new($InputHashtable.MessageName)
        Write-Log "Got chosen message entry with id '$( $mailing.mailingId )' and name '$( $mailing.mailingName )'"


        $templateId = $mailing.mailingId


        #-----------------------------------------------
        # CHECK INPUT RECEIVER
        #-----------------------------------------------



        #-----------------------------------------------
        # CHECK CLEVERREACH CONNECTION
        #-----------------------------------------------
        <#
        try {

            Test-CleverReachConnection

        } catch {

            #$msg = "Failed to connect to CleverReach, unauthorized or token is expired"
            #Write-Log -Message $msg -Severity ERROR
            Write-Log -Message $_.Exception -Severity ERROR
            throw [System.IO.InvalidDataException] $msg
            exit 0

        }

        #>



    }

    process {


        try {

            $fields = Get-SFSCObjectField -Object "CampaignMember"          

            $fieldRows = [System.Collections.ArrayList]@()

            $fields | ForEach-Object {
                $field = $_

                $pl = [System.Collections.ArrayList]@()
                if ( $field.picklistValues.count -gt 0 ) {                    
                    $field.picklistValues | ForEach-Object {
                        $plv = $_
                        [void]$pl.add("$( $plv.label ) ($( $plv.value ))")
                    }
                }

                [void]$fieldRows.add(@"
                <tr>
                    <td>$( $field.name )</td>
                    <td>$( $field.label )</td>
                    <td>$( $field.type )</td>
                    <td>$( $field.length )</td>
                    <td>$( $field.defaultValue )</td>
                    <td>$( $field.custom )</td>
                    <td>$( $field.createable )</td>
                    <td>$( $pl -join "<br/>" )</td>
                </tr>
"@
                )
            }

            $html = @"

            <html>
            <meta http-equiv="content-type" content="text/html; charset=utf-8">
            <head>
                <style>
                table, th, td {
                    border: 1px solid black;
                    border-collapse: collapse;
                    padding: 5px;
                }
                </style>
            </head>
            <body>
                <div id="scoped-content">
                    <style type="text/css" scoped>
                        table, th, td {
                            border: 1px solid black;
                            border-collapse: collapse;
                            padding: 5px;
                        }
                        td {
                            letter-spacing: 0;
                            font-family: Roboto,Helvetica,Arial,sans-serif;
                            font-size: 14px;
                            font-weight: 400;
                        }
                    </style>
                </div>
                <table>
                    <tr>
                        <td><b>Name</b></td>
                        <td><b>Label</b></td>
                        <td><b>Type</b></td>
                        <td><b>Length</b></td>
                        <td><b>defaultValue</b></td>
                        <td><b>custom</b></td>
                        <td><b>createable</b></td>
                        <td><b>picklistValues</b></td>
                    </tr>

                    $( $fieldRows -join " " )

                </table>
            </body>
            </html>

"@


            #-----------------------------------------------
            # CHECK IF A PREVIEW GROUP IS ALREADY EXISTING
            #-----------------------------------------------
            <#
            # get all groups
            $groups = @( Get-CRGroups )  #Invoke-CR -Object "groups" -Method GET -Verbose

            Write-Log "Got $( $groups.count ) groups"
            $script:debug = $groups
            $previewGroups = [array]@( $groups | where-object { $_.name -eq $Script:settings.preview.previewGroupName } )
            #$script:debug = $previewGroups

            If ( $previewGroups.count -eq 1 ) {
                # Use that group
                $previewGroup = $previewGroups | Select-Object -first 1
                Write-log -message "Using existing group '$( $previewGroup.mame )' with id '$( $previewGroup.id )'"
            } elseif ( $previewGroups.count -eq 0 ) {
                # Create a new group
                $newGroupBody = [PSCustomObject]@{
                    "name" = $Script:settings.preview.previewGroupName
                    "receiver_info" = "Preview Group for rendering mailings"
                    "locked" = $false
                    "backup" = $false
                }
                $previewGroup = Invoke-CR -Object "groups" -Method POST -Verbose -body $newGroupBody
                Write-log -message "Created a new group '$( $previewGroup.mame )' with id '$( $previewGroup.id )'"
            } else {
                # There is a problem, because multiple previewgroups are existing
                Write-Log "Too many preview groups. Please check!" -Severity Error
                throw "Too many preview groups. Please check!"
            }

            # Get that groups details
            $group = Invoke-CR -Object "groups" -Path "/$( $previewGroup.id )" -Method GET -Verbose
            #>




        } catch {

            $msg = "Error during rendering preview. Abort!"
            Write-Log -Message $msg -Severity ERROR
            Write-Log -Message $_.Exception -Severity ERROR
            throw [System.IO.InvalidDataException] $msg

        } finally {

        }


        #-----------------------------------------------
        # STOP TIMER
        #-----------------------------------------------

        $processEnd = [datetime]::now
        $processDuration = New-TimeSpan -Start $processStart -End $processEnd
        Write-Log -Message "Needed $( [int]$processDuration.TotalSeconds ) seconds in total"


        #-----------------------------------------------
        # RETURN VALUES TO PEOPLESTAGE
        #-----------------------------------------------

        # return object
        $return = [Hashtable]@{

            "Type" = "Email" #Email|Sms
            "FromAddress"="test@example.com"
            "FromName"="Apteco"
            "Html"=$html
            "ReplyTo"=""
            "Subject"="Preview"
            "Text"=$text

            # General return value to identify this custom channel in the broadcasts detail tables
            "CustomProvider"= $moduleName
            "ProcessId" = $Script:processId

        }

        # log the return object -> just don't do it to put all the html and text into the log
        <#
        Write-Log -message "RETURN:"
        $return.Keys | ForEach-Object {
            $param = $_
            Write-Log -message "    $( $param ) = '$( $return[$param] )'" -writeToHostToo $false
        }
        #>

        # return the results
        $return


    }

    end {

    }

}




