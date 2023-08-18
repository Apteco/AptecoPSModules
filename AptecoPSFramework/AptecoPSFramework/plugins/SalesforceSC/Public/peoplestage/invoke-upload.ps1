



function Invoke-Upload{

    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$false)][Hashtable] $InputHashtable
    )

    begin {


        #-----------------------------------------------
        # START TIMER
        #-----------------------------------------------

        $processStart = [datetime]::now
        #$inserts = 0


        #-----------------------------------------------
        # LOG
        #-----------------------------------------------

        $moduleName = "UPLOAD"

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
        # DEBUG MODE
        #-----------------------------------------------

        Write-Log "Debug Mode: $( $Script:debugMode )"


        #-----------------------------------------------
        # PARSE MESSAGE
        #-----------------------------------------------

        #$script:debug = $InputHashtable
        $uploadOnly = $false

        # TODO add an option to turn off tagging for upload only

        If ( "" -eq $InputHashtable.MessageName ) {
            #Write-Log "A"

            $uploadOnly = $true
            $mailing = [Mailing]::new(999, "UploadOnly")

        } else {
            #Write-Log "B"

            Write-Log "Parsing message: '$( $InputHashtable.MessageName )' with '$( $Script:settings.nameConcatChar )' as separator"
            $mailing = [Mailing]::new($InputHashtable.MessageName)
            Write-Log "Got chosen message entry with id '$( $mailing.mailingId )' and name '$( $mailing.mailingName )'"

            #$mailing = [Mailing]::new($InputHashtable.MessageName)
            #Write-Log "Got chosen message entry with id '$( $mailing.mailingId )' and name '$( $mailing.mailingName )'"

        }



        #-----------------------------------------------
        # CHECK INPUT FILE
        #-----------------------------------------------

        # Checks input file automatically
        $file = Get-Item -Path $InputHashtable.Path
        Write-Log -Message "Got a file at $( $file.FullName )"

        # Add note in log file, that the file is a converted file
        if ( $file.FullName -match "\.converted$") {
            Write-Log -message "Be aware, that the exports are generated in Codepage 1252 and not UTF8. Please change this in the Channel Editor." -severity ( [LogSeverity]::WARNING )
        }

        # Count the rows
        $rowsCount = 0
        # [ ] if this needs to much performance, this is not needed
        If ( $Script:settings.upload.countRowsInputFile -eq $true ) {
            $rowsCount = Measure-Rows -Path $file.FullName -SkipFirstRow
            Write-Log -Message "Got a file with $( $rowsCount ) rows"
        } else {
            Write-Log -Message "RowCount of input file not activated"
        }
        #throw [System.IO.InvalidDataException] $msg

        #Write-Log -Message "Debug Mode: $( $Script:debugMode )"


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

        #Write-Log -Message "Debug Mode: $( $Script:debugMode )"
#>

    }

    process {


        try {


            #-----------------------------------------------
            # CREATE GROUP IF NEEDED
            #-----------------------------------------------

            # If lists contains a concat character (id+name), use the list id
            # if no concat character is present, take the whole string as name for a new list and search for it... if not present -> new list!
            # if no list is present, just take the current date and time

            # If listname is valid -> contains an id, concatenation character and and a name -> use the id
            <#
            try {

                $createNewGroup = $false # No need for the group creation now
                $list = [MailingList]::new($InputHashtable.ListName)
                $listName = $list.mailingListName
                $groupId = $list.mailingListId
                Write-Log "Got chosen list/group entry with id '$( $list.mailingListId )' and name '$( $list.mailingListName )'"

                # Asking for details and possibly throw an exception
                $g = Invoke-CR -Object "groups" -Path "/$( $groupId )" -Method GET -Verbose

            } catch {

                # Listname is the same as the message means nothing was entered -> check the name
                if ( $InputHashtable.ListName -ne $InputHashtable.MessageName ) {

                    # Try to search for that group and select the first matching entry or throw exception
                    $groups =  Invoke-CR -Object "groups" -Method "GET" -Verbose

                    # Check how many matches are available
                    $matchingGroups = @( $groups | where-object { $_.name -eq $InputHashtable.ListName } ) # put an array around because when the return is one object, it will become a pscustomobject
                    switch ( $matchingGroups.Count ) {

                        # No match -> new group
                        0 {
                            $createNewGroup = $true
                            $listName = $InputHashtable.ListName
                            Write-Log -message "No matched group -> create a new one" -severity INFO
                        }

                        # One match -> use that one!
                        1 {
                            $createNewGroup = $false # No need for the group creation now
                            $listName = $matchingGroups.name
                            $groupId = $matchingGroups.id
                            Write-Log -message "Matched one group -> use that one" -severity INFO
                        }

                        # More than one match -> throw exception
                        Default {
                            $createNewGroup = $false # No need for the group creation now
                            Write-Log -message "More than one match -> throw exception" -severity ERROR
                            throw [System.IO.InvalidDataException] "More than two groups with that name. Please choose a unique list."
                        }
                    }

                # String is empty, create a generic group name
                } else {
                    $createNewGroup = $true
                    $listName = [datetime]::Now.ToString("yyyyMMdd_HHmmss")
                    Write-Log -message "Create a new group with a timestamp" -severity INFO
                }

            }

            # Create a new group (if needed)
            if ( $createNewGroup -eq $true ) {

                $body = [PSCustomObject]@{
                    "name" = "$( $listName )"
                }
                $newGroup = Invoke-CR -Object "groups" -Body $body -Method "POST" -Verbose
                $groupId = $newGroup.id
                Write-Log -message "Created a new group with id $( $groupId )" -severity INFO

            }
            #>

            #-----------------------------------------------
            # CHECK CAMPAIGN
            #-----------------------------------------------

            # TODO [ ] put into docs, that I need a idlookup field that simply mirrors the id field
            $campaignId = $mailing.mailingId

            $campaign = Invoke-SFSCQuery -Query "Select Id, Name, idlookup__c from Campaign where idlookup__c like '%$( $campaignId.substring(0,$campaignId.length-3) )%'"

            Write-Log "Using salesforce campaign '$( $campaign.Name )' with id '$( $campaign.id )'"


            #-----------------------------------------------
            # CHECK CAMPAIGN MEMBER STATUS
            #-----------------------------------------------

            $list = [MailingList]::new($InputHashtable.ListName)
            $listName = $list.mailingListName
            $listId = $list.mailingListId

            #$campaignMemberStatus = Invoke-SFSCQuery -Query "Select Id, Label from CampaignMemberStatus where Name = '$( $listname )' and CampaignId = '$( $campaign.Id )'"

            #Write-Log "Using salesforce campaign member status '$( $campaignMemberStatus.Label )' with id '$( $campaignMemberStatus.Id )'"
            Write-Log "Using salesforce campaign member status '$( $listName )'"
            

            #-----------------------------------------------
            # DEFINE DATA
            #-----------------------------------------------

            <# 

            # COLUMN NAMES

            For a standard field, use the Field Name value as the field column header in your CSV file.
            For a custom field, use the API Name value as the field column header in a CSV file or the field name identifier in an XML or JSON file. (To find the API Name, click the field name.)

            # PARENT ENTRIES

            You can use a child-to-parent relationship, but you can't use a parent-to-child relationship.
            You can use a child-to-parent relationship, but you can't extend it to use a child-to-parent-grandparent relationship.
            You can only use indexed fields on the parent object. A custom field is indexed if its External ID field is selected. A standard field is indexed if its idLookup property is set to true. See the Field Properties column in the field table for each standard object.

            #>


            #-----------------------------------------------
            # CREATE JOB
            #-----------------------------------------------

            <#

            # REFERENCE

            https://developer.salesforce.com/docs/atlas.en-us.api_asynch.meta/api_asynch/create_job.htm

            # EXTERNAL ID

            (Copied from the SF Help)

            Confirm that your object is using an external ID field.

            Upserting records requires an external ID field on the object involved in the job. Bulk API 2.0 uses the external ID field to determine whether a record is used to update an existing record or create a record.
            This example assumes that the external ID field customExtIdField__c has been added to the Account object.
            To add this custom field in your org with Object Manager, use these properties.

                Data Type—text
                Field Label—customExtIdField
                Select External ID

            #>

            $jobDetails = [PSCustomObject]@{
                #"assignmentRuleId" = ""
                "object" = "CampaignMember"     # Single object per job
                "contentType" = "CSV"           # CSV - No more options available
                "operation" = "insert"          # insert|delete|hardDelete|update|upsert
                "lineEnding" = "CRLF"           # LF (Linux) and CRLF (Windows)
                "columnDelimiter" = "TAB"     # BACKQUOTE|CARET|COMMA|PIPE|SEMICOLON|TAB
                #"externalIdFieldName" = ""      # Required for upsert, something like customExtIdField__c
            }

            # curl https://MyDomainName.my.salesforce.com/services/data/v58.0/jobs/ingest/ -H 'Authorization: Bearer 00DE0X0A0M0PeLE!AQcAQH0dMHEXAMPLEzmpkb58urFRkgeBGsxL_QJWwYMfAbUeeG7c1EXAMPLEDUkWe6H34r1AAwOR8B8fLEz6nEXAMPLE' -H "Content-Type: application/json" -H "Accept: application/json" -H "X-PrettyPrint:1" -d @newinsertjob.json -X POST
            #$jobDetailsJson = ConvertTo-Json $jobDetails
            #$job = Invoke-RestMethod -URI "$( $base )/services/data/v$( $version )/jobs/ingest/" -Method POST -verbose -ContentType $contentType -Headers $headers -body $jobDetailsJson

            $job = Invoke-SFSC -Service "data" -Object "jobs" -Path "/ingest/" -Method "POST" -Body $jobDetails

            #return
            <#

            { "id" : "7505fEXAMPLE4C2AAM",​
            "operation" : "insert",​
            "object" : "Account",​
            "createdById" : "0055fEXAMPLEtG4AAM",​
            "createdDate" : "2022-01-02T21:33:43.000+0000",​
            "systemModstamp" : "2022-01-02T21:33:43.000+0000",​
            "state" : "Open",​
            "concurrencyMode" : "Parallel",​
            "contentType" : "CSV",​
            "apiVersion" : 58.0,​
            "contentUrl" : "services/data/58.0/jobs/ingest/7505fEXAMPLE4C2AAM/batches",​
            "lineEnding" : "LF",​ "columnDelimiter" : "COMMA" }

            #>

            Write-Log "Created job with id '$( $job.id )'"


            #-----------------------------------------------
            # TRANSFORM THE DATA
            #-----------------------------------------------

            # TODO [ ] maybe scale this up in future or think about multipart upload
            # TODO [ ] check if ContactID or LeadID is present

            $sfFields = Get-SFSCObjectField -Object "CampaignMember"

            $csv = @( Import-csv -Delimiter "`t" -Path $file.FullName -Encoding UTF8 )

            $newCsv = [System.Collections.ArrayList]@()
            $csv | ForEach-Object {
                $row = $_
                $line = [PSCustomObject]@{
                    "CampaignID" = $campaign.id
                    "Status" = $list.mailingListId
                }
                $row.psobject.properties | ForEach-Object {
                    $prop = $_
                    If ( $sfFields.name -contains $prop.name ) {
                        $line | Add-Member -MemberType NoteProperty -Name $prop.name -Value $prop.value
                    }
                }
                [void]$newCsv.add($line)
            }
            Write-Log "Converted $( $newCsv.count ) lines"


            $nf = "$( $Env:TEMP )\$( [guid]::NewGuid().toString() ).csv" #New-TemporaryFile
            Write-Log "Using temporary file $( $nf )"
            # TODO [ ] Not the best way when you have quotes in values
            $newCsvContent = $newCsv | convertto-csv -NoTypeInformation -Delimiter "`t" | % {$_ -replace '"',''} 
            #$newCsvContent | set-content -Path $nf -Encoding UTF8

            [IO.File]::WriteAllLines($nf, $newCsvContent)

            Write-Log "File is written"


            #-----------------------------------------------
            # UPLOAD THE DATA
            #-----------------------------------------------

            # MAX 150M after Base64 encoding
            # curl https://MyDomainName.my.salesforce.com/services/data/v58.0/jobs/ingest/7505fEXAMPLE4C2AAM/batches/ -H 'Authorization: Bearer 00DE0X0A0M0PeLE!AQcAQH0dMHEXAMPLEzmpkb58urFRkgeBGsxL_QJWwYMfAbUeeG7c1EXAMPLEDUkWe6H34r1AAwOR8B8fLEz6nEXAMPLE' -H "Content-Type: text/csv" -H "Accept: application/json" -H "X-PrettyPrint:1" --data-binary @bulkinsert.csv -X PUT

            #$upload = Invoke-RestMethod -URI "$( $base )/services/data/v$( $version )/jobs/ingest/$( $job.id )/batches/" -Method PUT -verbose -ContentType "text/csv" -Headers $headers -body $accountsCsv
            $upload = Invoke-SFSC -Service "data" -Object "jobs" -Path "/ingest/$( $job.id )/batches/" -Method "PUT" -ContentType "text/csv" -InFile $nf #$file.FullName

            Write-Log "Did the upload"


            #-----------------------------------------------
            # SET STATE COMPLETE
            #-----------------------------------------------

            # curl https://MyDomainName.my.salesforce.com/services/data/v58.0/jobs/ingest/7505fEXAMPLE4C2AAM/ -H 'Authorization: Bearer 00DE0X0A0M0PeLE!AQcAQH0dMHEXAMPLEzmpkb58urFRkgeBGsxL_QJWwYMfAbUeeG7c1EXAMPLEDUkWe6H34r1AAwOR8B8fLEz6nEXAMPLE' -H "Content-Type: application/json; charset=UTF-8" -H "Accept: application/json" -H "X-PrettyPrint:1" --data-raw '{ "state" : "UploadComplete" }' -X PATCH
            # $patchDetails = [PSCustomObject]@{
            #     "state" = "UploadComplete"
            # }
            # $patchedJob = Invoke-RestMethod -URI "$( $base )/services/data/v$( $version )/jobs/ingest/$( $job.id )/" -Method PATCH -verbose -ContentType $contentType -Headers $headers -body $patchDetails
            $patchedJob = Invoke-SFSC -Service "data" -Object "jobs" -Path "/ingest/$( $job.id )/" -Method "PATCH" -body ( [PSCustomObject]@{ "state" = "UploadComplete" } )
            
            Write-Log "Patched the job to state 'UploadComplete'"

            <#

            { "id" : "7505fEXAMPLE4C2AAM",​
            "operation" : "insert",​
            "object" : "Account",​
            "createdById" : "0055fEXAMPLEtG4AAM",​
            "createdDate" : "2022-01-02T21:33:43.000+0000",​
            "systemModstamp" : "2022-01-02T21:33:43.000+0000",​
            "state" : "UploadComplete",​
            "concurrencyMode" : "Parallel",​
            "contentType" : "CSV",​
            "apiVersion" : 58.0 }

            #>

            #-----------------------------------------------
            # CHECK JOB STATUS ASYNC
            #-----------------------------------------------


            # curl https://MyDomainName.my.salesforce.com/services/data/v58.0/jobs/ingest/7505fEXAMPLE4C2AAM/ -H 'Authorization: Bearer 00DE0X0A0M0PeLE!AQcAQH0dMHEXAMPLEzmpkb58urFRkgeBGsxL_QJWwYMfAbUeeG7c1EXAMPLEDUkWe6H34r1AAwOR8B8fLEz6nEXAMPLE' -H "Accept: application/json" -H "X-PrettyPrint:1" -X GET
            Do {
                #$jobStatus = Invoke-RestMethod -URI "$( $base )/services/data/v$( $version )/jobs/ingest/$( $job.id )/" -Method GET -verbose -ContentType $contentType -Headers $headers
                $jobStatus = Invoke-SFSC -Service "data" -Object "jobs" -Path "/ingest/$( $job.id )/" -Method "GET"
                Write-Log "Job status: $( $jobStatus.state )"
                #$jobStatus.state
                Start-Sleep -seconds 10
            } Until ( @("Failed", "JobComplete") -contains $jobStatus.state)
            # TODO [ ] add a timer like in CleverReach at the end of the broadcast


            #-----------------------------------------------
            # GET RESULTS
            #-----------------------------------------------

            # curl https://MyDomainName.my.salesforce.com/services/data/v58.0/jobs/ingest/7505fEXAMPLE4C2AAM/successfulResults/ -H 'Authorization: Bearer 00DE0X0A0M0PeLE!AQcAQH0dMHEXAMPLEzmpkb58urFRkgeBGsxL_QJWwYMfAbUeeG7c1EXAMPLEDUkWe6H34r1AAwOR8B8fLEz6nEXAMPLE' -H "Content-Type: application/json" -H "Accept: text/csv" -H "X-PrettyPrint:1" -X GET
            # failedResults
            # unprocessedRecords
<#
            $csvHeaders = $headers.Clone()
            $csvHeaders.Accept = "text/csv"

            $success = Invoke-RestMethod -URI "$( $base )/services/data/v$( $version )/jobs/ingest/$( $job.id )/successfulResults/" -Method GET -verbose -ContentType $contentType -Headers $csvHeaders
            $failed = Invoke-RestMethod -URI "$( $base )/services/data/v$( $version )/jobs/ingest/$( $job.id )/failedResults/" -Method GET -verbose -ContentType $contentType -Headers $csvHeaders
            $unprocessed = Invoke-RestMethod -URI "$( $base )/services/data/v$( $version )/jobs/ingest/$( $job.id )/unprocessedRecords/" -Method GET -verbose -ContentType $contentType -Headers $csvHeaders
#>
            $jobResults = Invoke-SFSC -Service "data" -Object "jobs" -Path "/ingest/$( $job.id )/" -method get
            $processed = $jobResults.numberRecordsProcessed 
            $failed = $jobResults.numberRecordsFailed
            $successful = $processed - $failed

            Write-Log "$( $processed ) processed records" -severity INFO
            Write-Log "$( $failed ) failed" -severity INFO

        } catch {

            $msg = "Error during uploading data. Abort!"
            Write-Log -Message $msg -Severity ERROR -WriteToHostToo $false
            Write-Log -Message $_.Exception -Severity ERROR
            throw $_.Exception

        } finally {


            # Close the file reader, if open
            # If the variable is not already declared, that shouldn't be a problem
            # try {
            #     $reader.Close()
            # } catch {

            # }

            #-----------------------------------------------
            # STOP TIMER
            #-----------------------------------------------

            $processEnd = [datetime]::now
            $processDuration = New-TimeSpan -Start $processStart -End $processEnd
            Write-Log -Message "Needed $( [int]$processDuration.TotalSeconds ) seconds in total"

            #Write-Host "Uploaded $( $j ) record. Confirmed $( $tagcount ) receivers with tag '$( $tags )'"

        }


        #-----------------------------------------------
        # RETURN VALUES TO PEOPLESTAGE
        #-----------------------------------------------

        # count the number of successful upload rows
        $recipients = $successful #$dataCsv.Count # TODO work out what to be saved

        # put in the source id as the listname
        $transactionId = $job.id #$Script:processId #$targetGroup.targetGroupId # TODO or try to log the used tag?

        # return object
        $return = [Hashtable]@{

            # Mandatory return values
            "Recipients"=$recipients
            "TransactionId"=$transactionId

            # General return value to identify this custom channel in the broadcasts detail tables
            "CustomProvider"= $Script:settings.providername
            "ProcessId" = $Script:processId

            # More values for broadcast
            #"Tag" = ( $tags -join ", " )
            #"GroupId" = $groupId
            #"PreheaderIsSet" = $preheaderIsSet

            # Some more information for the broadcasts script
            #"EmailFieldName"= $params.EmailFieldName
            #"Path"= $params.Path
            #"UrnFieldName"= $params.UrnFieldName
            #"TargetGroupId" = $targetGroup.targetGroupId

            # More information about the different status of the import
            #"RecipientsIgnored" = $status.report.total_ignored
            #"RecipientsQueued" = $recipients
            #"RecipientsSent" = $status.report.total_added + $status.report.total_updated

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




