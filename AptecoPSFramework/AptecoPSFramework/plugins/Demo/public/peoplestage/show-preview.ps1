



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

        $mailing = [Mailing]::new($InputHashtable.MessageName)
        Write-Log "Got chosen message entry with id '$( $mailing.mailingId )' and name '$( $mailing.mailingName )'"

        $templateId = $mailing.mailingId


        #-----------------------------------------------
        # CHECK INPUT RECEIVER
        #-----------------------------------------------



        #-----------------------------------------------
        # CHECK CLEVERREACH CONNECTION
        #-----------------------------------------------

        try {

            Test-CleverReachConnection

        } catch {

            #$msg = "Failed to connect to CleverReach, unauthorized or token is expired"
            #Write-Log -Message $msg -Severity ERROR
            Write-Log -Message $_.Exception -Severity ERROR
            throw [System.IO.InvalidDataException] $msg
            exit 0

        }





    }

    process {


        try {

            #-----------------------------------------------
            # CHECK IF A PREVIEW GROUP IS ALREADY EXISTING
            #-----------------------------------------------

            # get all groups
            $groups = Invoke-CR -Object "groups" -Method GET -Verbose

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
                throw "Too many preview groups. Please check!"
            }

            # Get that groups details
            $group = Invoke-CR -Object "groups" -Path "/$( $previewGroup.id )" -Method GET -Verbose


            #-----------------------------------------------
            # CLEAR THAT GROUP
            #-----------------------------------------------

            #delete /v3/groups.json/{id}/clear
            $clearedGroup = Invoke-CR -Object "groups" -Path "/$( $previewGroup.id )/clear" -Method DELETE

            Write-Log "Cleared the group '$( $group.name )' with id '$( $group.id )'"


            #-----------------------------------------------
            # PUT PREVIEW RECEIVER IN THAT GROUP
            #-----------------------------------------------

            #upsert


            #-----------------------------------------------
            # LOAD UPLOADED RECEIVER
            #-----------------------------------------------

            # TODO Implement downloading the receiver


            # Example

            #$InputHashtable.TestRecipient = '{"Email":"reply@apteco.de","Sms":null,"Personalisation":{"Kunden ID":"","email":"florian.von.bracht@apteco.de","Vorname":"","Communication Key":"93d02a55-9dda-4a68-ae5b-e8423d36fc20"}}'


            #-----------------------------------------------
            # READ MAILING DETAILS
            #-----------------------------------------------

            # get details of mailing
            $templateSource = Invoke-CR -Object "mailings" -Path "/$( $templateId )" -Method GET -Verbose
            #$newMailingName = "$( $templateSource.name ) - $( $processStart.ToString("yyyyMMddHHmmss") )"
            Write-Log -message "Looked up the mailing '$( $templateId )' with name '$( $templateSource.Name )'"
            #Write-Log -message "New mailing name: '$( $newMailingName )'"


            #-----------------------------------------------
            # CREATE A RENDERED PREVIEW
            #-----------------------------------------------


            # NOT DOCUMENTED, but works

            <#
            $j = '{
                "subject": "&quot;Gleich 4 neue Whitepaper auf einen Schlag für dich, {FIRSTNAME}!&quot;",
                "html": "<html><body>Hello {FIRSTNAME}</body></html>",
                "text": "",
                "receiver": {
                    "id": "999",
                    "email": "test@example.com",
                    "attributes": {
                        "acc_branchen_kombiniert": "Data Owner Service Providers",
                        "communication_key": "5d8691e0-c4b9-ed11-ac33-3cecef223d6e"
                    },
                    "global_attributes": {
                        "firstname": "Martin",
                        "lastname": "Bowe",
                        "anrede": "Herr"
                    },
                    "tags": [
                        "AktionsDashboard",
                        "AnalytischesDashboard",
                        "DashboardStyles",
                        "ManagementDashboard"
                    ]
                }
            }'
            #>
            #Write-Host -message "Using first name: '$( $InputHashtable.TestRecipient.Personalisation.Vorname )'"
            $testRecipient = Convertfrom-Json -InputObject $InputHashtable.TestRecipient
            #$script:debug = $InputHashtable
            $previewParameters = [PSCustomObject]@{
                "subject" = "&quot;Gleich 4 neue Whitepaper auf einen Schlag für dich, {FIRSTNAME}!&quot;"
                "html" = "<html><body>Hello {FIRSTNAME}</body></html>"
                "text" = ""
                "receiver" = [PSCustomObject]@{
                    "id" = "123"
                    "email" = "test@example.com"
                    "attributes" = [PSCustomObject]@{}
                    "global_attributes" = [PSCustomObject]@{
                        "firstname" = $testRecipient.Personalisation.Vorname # Exchange this
                    }
                    "tags" = [Array]@()
                }
            }
            $previewParmetersJson = Convertto-json -InputObject $previewParameters -Depth 99

            #$renderedPreview = Invoke-CR -Object "gomailer" -Path "/preview" -Method POST -Verbose -body $previewParameters
            $renderedPreview = Invoke-RestMethod -Uri "https://rest.cleverreach.com/gomailer/preview" -ContentType $Script:settings.contentType -body $previewParmetersJson -Verbose -Method POST


            #Invoke-RestMethod -Method Post -Uri "https://rest.cleverreach.com/gomailer/preview" -Body $j

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
            "FromAddress"=$templateSource.sender_email
            "FromName"=$templateSource.sender_name
            "Html"=$renderedPreview.html
            "ReplyTo"=""
            "Subject"=$renderedPreview.subject
            "Text"=$renderedPreview.text

            # General return value to identify this custom channel in the broadcasts detail tables
            "CustomProvider"= $moduleName
            "ProcessId" = $Script:processId

        }

        # log the return object
        Write-Log -message "RETURN:"
        $return.Keys | ForEach-Object {
            $param = $_
            Write-Log -message "    $( $param ) = '$( $return[$param] )'" -writeToHostToo $false
        }

        # return the results
        $return


    }

    end {

    }

}




