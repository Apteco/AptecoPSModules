

function Get-Response {

    [CmdletBinding()]
    param (
        #[Parameter(Mandatory=$false)][Hashtable] $InputHashtable
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

        $moduleName = "GETRESPONSE"

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
        <#
        #$script:debug = $InputHashtable
        $uploadOnly = $false
        
        # TODO add an option to turn off tagging for upload only

        If ( "" -eq $InputHashtable.MessageName ) {
            #Write-Log "A"

            $uploadOnly = $true
            $mailing = [Mailing]::new(999, "UploadOnly")
        } else {
            #Write-Log "B"

            $mailing = [Mailing]::new($InputHashtable.MessageName)
            Write-Log "Got chosen message entry with id '$( $mailing.mailingId )' and name '$( $mailing.mailingName )'"
        }
        #>


        #-----------------------------------------------
        # DEFAULT VALUES
        #-----------------------------------------------
        
        <#
        $uploadSize = $Script:settings.upload.uploadSize
        Write-Log "Got UploadSize of $( $uploadSize ) rows/objects" #-Severity WARNING
        If ($uploadSize -gt 1000 ) {
            Write-Log "UploadSize has been set to more than 1000 rows. Using max of 1000 now!" -Severity WARNING
            $uploadSize = 1000
        }

        # Currently CleverReach support 40 attributes
        $maxAttributesCount = 40
        #>


        #-----------------------------------------------
        # CHECK INPUT FILE
        #-----------------------------------------------

        <#
        # Checks input file automatically
        $file = Get-Item -Path $InputHashtable.Path
        Write-Log -Message "Got a file at $( $file.FullName )"

        # Add note in log file, that the file is a converted file
        if ( $file.FullName -match "\.converted$") {
            Write-Log -message "Be aware, that the exports are generated in Codepage 1252 and not UTF8. Please change this in the Channel Editor." -severity ( [LogSeverity]::WARNING )
        }

        # Count the rows
        # [ ] if this needs to much performance, this is not needed
        If ( $Script:settings.upload.countRowsInputFile -eq $true ) {
            $rowsCount = Measure-Rows -Path $file.FullName -SkipFirstRow 
            Write-Log -Message "Got a file with $( $rowsCount ) rows"
        } else {
            Write-Log -Message "RowCount of input file not activated"
        }
        #throw [System.IO.InvalidDataException] $msg
        
        Write-Log -Message "Debug Mode: $( $Script:debugMode )"
        #>

        #-----------------------------------------------
        # TIMESTAMPS FOR LOADING MAILING REPORTS AND RESPONSES
        #-----------------------------------------------

        # The end of request is now!
        $endTimestamp = Get-Unixtime

        # Load the response timestamp if available
        If ( $Script:settings.responses.saveLastTimestamp -eq $true -and (Test-Path $Script:settings.responses.saveLastTimestampFile) -eq $true ) {
            $lastTimestamp = Get-Content -Path $Script:settings.responses.saveLastTimestampFile -Encoding UTF8 -raw | convertfrom-json
            $responseStartTimestamp = $lastTimestamp.lastResponseDownload
            Write-Log "Using last saved timestamp for responses: $( $responseStartTimestamp )"
        } else {
            $responseStartTimestamp = Get-Unixtime -timestamp ([DateTime]::Now.AddDays( $Script:settings.responses.responsePeriod *-1 ))
            Write-Log "Using this timestamp for responses start: $( $responseStartTimestamp )"

        }

        # Settings for messages
        $messageStartTimestamp = Get-Unixtime -timestamp ([DateTime]::Now.AddDays( $Script:settings.responses.messagePeriod *-1 ))
        Write-Log "Using this timestamp for messages start: $( $messageStartTimestamp )"

        Write-Log "Using this timestamp for end: $( $endTimestamp )"


        #-----------------------------------------------
        # DETAILS DEFINITION
        #-----------------------------------------------

        $cleverreachDetailsBinaryValues = [Hashtable]@{
            events = 1
            orders = 2
            tags = 4
        }


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

        #Write-Log -Message "Debug Mode: $( $Script:debugMode )"

        
    }
    
    process {


        try {
            

            #-----------------------------------------------
            # WORKOUT THE NEEDED DETAIL BINARY VALUE FOR RECEIVERS
            #-----------------------------------------------

            $cleverReachDetailsBinary = 0
            $cleverreachDetailsBinaryValues.Keys | ForEach {
                if ( $Script:settings.loadDetails.($_) -eq $true ) {
                    $cleverReachDetailsBinary += $cleverreachDetailsBinaryValues[$_]
                }
            }


            #-----------------------------------------------
            # DOWNLOAD BLOCKLIST
            #-----------------------------------------------

            <#
            Write-Log -message "Downloading Blocklist"

            # write the block list
            $blocklist = @( Get-Blocklist ) #-Paging

            Write-Log -message "Found $( $blocklist.Count ) blocklist entries"
            #>

            #-----------------------------------------------
            # DOWNLOAD GLOBAL UNSUBSCIBES
            #-----------------------------------------------

            <#
            Write-Log -message "Downloading global unsubscribes/deactivated"

            $globalUnsubscribed = @( Get-GlobalDeactivated )

            Write-Log -message "Found $( $globalUnsubscribed.Count ) global unsubscribed/deactivated"
            #>


            #-----------------------------------------------
            # DOWNLOAD BOUNCES
            #-----------------------------------------------

            <#
            Write-Log -message "Downloading the bounces"

            # write the black list
            #$bounced = Invoke-RestMethod -Method Get -Uri "$( $settings.base)receivers/bounced.json" -Headers $header
            $bounced = @( Get-Bounces ) #Invoke-CR -Object "bounces" -Method GET -Verbose -Paging
            # we can work out the bounces for specific mailings with: get-bounces | where { $_.type -eq "mailing" } and then read type_id with mailing/report id and then read expires_by as timestamp
            Write-Log -message "Found $( $bounced.Count ) bounces"
            #>
            
            #-----------------------------------------------
            # DOWNLOAD GLOBAL ATTRIBUTES
            #-----------------------------------------------

            $globalUrnAttribute = $false
            $globalAttributes = @( (Invoke-CR -Object "attributes" -Method "GET" -Verbose ) )
            $urnField = @( $globalAttributes | Where-Object { $_.name -eq $Script:settings.responses.urnFieldName } )
            If ( $urnField.count -eq 0 ) {
                Write-Log -message "Looks like the urn is not on global level. It tries to load it from local attributes"
            } elseif ( $urnField.count -eq 1 ) {
                $globalUrnAttribute = $true
                Write-Log -message "Looks like the urn is on global level named $( $urnField.description )"
            } else {
                Write-Log -message "There are multiple urnfields on global level!? Please check" -severity WARNING
            }


            #-----------------------------------------------
            # DOWNLOAD REPORTS
            #-----------------------------------------------

            Write-Log -message "Downloading reports"

            $reportsQuery = [PSCustomObject]@{
                start = $messageStartTimestamp
                end = $endTimestamp
            }
            $reports = @( Invoke-CR -Object "reports" -Query $reportsQuery -Method "GET" -Verbose -Paging -Pagesize 80 )

            Write-Log -message "Found $( $reports.Count ) reports for the last $( $Script:settings.responses.messagePeriod ) days"

    
            ################################################
            #
            # DOWNLOAD ALL REPORTS RECEIVERS
            #
            ################################################

            <#

            IMPORTANT HINT

            The events attached to a receiver are only the last 250 entries... this is the reason why we need for every state, every mailing and every link

            #>
            
            $responseTypes = [Hashtable]@{
                sent = $Script:settings.responses.loadSent
                opened = $Script:settings.responses.loadOpens
                clicked = $Script:settings.responses.loadClicks
                notopened = $false
                notclicked = $false
                bounced = $Script:settings.responses.loadBounces
                unsubscribed = $Script:settings.responses.loadUnsubscribes
            }

            
            #$from = Get-Unixtime $currentTimestampDateTime.AddDays(-30)
            #$to = Get-Unixtime $currentTimestampDateTime
            #$allResponses = [System.Collections.ArrayList]@()

            # Going through all response types like opens and clicks
            $responseCounts = [PSCustomObject]@{}
            $allLinks = [System.Collections.ArrayList]@()
            $responseTypes.Keys | ForEach-Object {

                # response type like sent, opened, ...
                $responseType = $_

                # check if this response type should be downloaded
                if ( $responseTypes[$responseType] -eq $true ) {
                    
                    # create an array to put the results in
                    $responses = [System.Collections.ArrayList]@()

                    # go through every mailing of last n days and check for responses
                    $reports | ForEach-Object {

                        $reportId = $_.id

                        Write-Log -message "Downloading report id '$( $reportId )' and response type '$( $responseType )'"

                        # load links for this report that are clicked more than 0 and add them to the all links collection
                        $iLink = 0
                        if ( $responseType -eq "clicked" ) {
                            #https://rest.cleverreach.com/v3/reports.json/8148376/stats/links
                            $links = @( (Invoke-CR -Object "reports" -Path "/$( $reportId )/stats/links" | where { $_.links.total_clicks -gt 0 }).links )
                            #$links = @( Invoke-CR -Object "mailings" -Path "/$( $reportId )/links" -Method "GET" -Verbose ) #Invoke-RestMethod -Method Get -Uri "$( $settings.base)mailings.json/$( $reportId )/links" -Headers $header
                            $allLinks.AddRange($links)
                        }            

                        Do {

                            # Add some parameters for loading details
                            $query = [PSCustomObject]@{
                                "detail" = $cleverReachDetailsBinary
                                "from" = $responseStartTimestamp
                                "to" = $endTimestamp
                            }
                            
                            # Ask for a specific link id
                            if ( $responseType -eq "clicked" ) {                                    
                                $linkId = $links[$iLink].id
                                #$attachLink = "&linkid=$( $linkId )"
                                $query | Add-Member -MemberType NoteProperty -Name "linkid" -Value $linkId
                                $iLink += 1
                                Write-Log -message "  Downloading link $( $linkId )"
                            }

                            $result = @( Invoke-CR -Object "reports" -Path "/$( $reportId )/receivers/$( $responseType )" -Query $query -Method "GET" -Verbose -Paging )
                            #$script:pluginDebug = $result
                            If ( $result.count -gt 0 ) {
                                $responses.AddRange(@( $result | Select @{name="state";expression={ $responseType }},@{name="report";expression={ $reportId }},@{name="linkid";expression={ $linkId }}, * ))
                                #$allResponses.AddRange(@( $result | Select @{name="state";expression={ $responseType }},@{name="report";expression={ $reportId }},@{name="linkid";expression={ $linkId }}, * ))
                            }
                            Write-Log -message "  Got $( $result.count ) results"
                            
                        # Do another round if there are links left because we need to ask for every link
                        } while ( $iLink -lt ( $links.count ) -and $responseType -eq "clicked" )


                    }

                    # Now save the reactions directly into a file
                    $responsesResolved = [System.Collections.ArrayList]@()
                    $responses | foreach-object {

                        $r = $_

                        # Work out the urn: global -> local -> crID
                        $urn = ""
                        If ( $globalUrnAttribute -eq $true ) {
                            $urn = $r.global_attributes.( $Script:settings.responses.urnFieldName )
                        } else {
                            $urn = $r.attributes.( $Script:settings.responses.urnFieldName )
                        }

                        # Fallback for id
                        If ($urn -eq $null -or $urn.length -eq 0) {
                            $urn = $r.id
                        }

                        # The minimum of the object to report
                        $responseObj = [PSCustomObject]@{
                            #"MessageType" = $responseType
                            "urn" = $urn # TODO think about urn column in $Script:settings.responses.urnFieldName
                            "email" = $r.email
                            "mailingId" = $r.report
                            "mailingName" = ($reports | Where-Object { $_.id -eq $r.report }).name
                            "timestamp" = 0 # default value that can be overriden
                            #"communicationkey" = $r.attributes."$( $Script:setttings.responses.communicationKeyAttributeName )" # not used now as the matching should be done through email address and broadcast id
                        }

                        # work out the filter for the events of this receiver                        
                        Switch ( $responseType ) {

                            "sent" {
                                <#
                                {
                                    "stamp": 1688027454,
                                    "type": "mail_send",
                                    "type_id": "8157881",
                                    "value": "",
                                    "mailing_id": "8157881",
                                    "groups_id": "0"
                                }
                                #>
                                $type = "Send" #Open, Click, Bounce, Unsubscription, Send
                                $events = @( $r.events | Where-Object { $_.type -eq "mail_send" -and $_.mailing_id -eq $r.report } )
                                $responseObj.timestamp = ( $reports | Where-Object { $_.id -eq $r.report } ).finished # TODO maybe convert into other datetime format
                            }

                            "opened" {
                                <#
                                {
                                    "stamp": 1674205127,
                                    "type": "mail_open",
                                    "type_id": "8071313",
                                    "value": "95.223.77.119",
                                    "mailing_id": "8071313",
                                    "groups_id": "0"
                                }
                                #>
                                $type = "Open" #Open, Click, Bounce, Unsubscription, Send
                                $events = @( $r.events | Where-Object { $_.type -eq "mail_open" -and $_.mailing_id -eq $r.report } )
                                
                            }

                            "clicked" {
                                <#
                                {
                                    "stamp": 1674204151,
                                    "type": "mail_click",
                                    "type_id": "41412194",
                                    "value": "40.94.94.6",
                                    "mailing_id": "8071313",
                                    "groups_id": "0"
                                }
                                #>
                                $type = "Click" #Open, Click, Bounce, Unsubscription, Send
                                $events = @( $r.events | Where-Object { $_.type -eq "mail_click" -and $_.mailing_id -eq $r.report -and $_.type_id -eq $r.linkid } ) # possibly filter on stamp -gt $responsestartdate 
                                $responseObj | Add-Member -MemberType NoteProperty -Name "link" -Value ( $allLinks | where { $_.id -eq $r.linkid } ).link
                            }

                            "bounced" {
                                <#
                                {
                                    "stamp": 1688027464,
                                    "type": "mail_bounce",
                                    "type_id": "hardbounce",
                                    "value": "smtp; 550 5.4.1 Recipient address rejected: Access denied. AS(201806281) [HE1EUR01FT103.eop-EUR01.prod.protection.outlook.com 2023-06-29T08:30:52.649Z 08DB7741F2946D97]",
                                    "mailing_id": "8157881",
                                    "groups_id": "0"
                                }
                                #>

                                $type = "Bounce" #Open, Click, Bounce, Unsubscription, Send
                                $events = @( $r.events | Where-Object { $_.type -eq "mail_bounce" -and $_.mailing_id -eq $r.report } ) # possibly filter on stamp -gt $responsestartdate                                

                            }

                            "unsubscribed" {
                                <#
                                {
                                    "stamp": 1688028443,
                                    "type": "user_unsubscribe",
                                    "type_id": "228563",
                                    "value": "34.219.234.42",
                                    "mailing_id": "8157881",
                                    "groups_id": "1146810"
                                }
                                #>
                                $type = "Unsubscription" #Open, Click, Bounce, Unsubscription, Send
                                $events = @( $r.events | Where-Object { $_.type -eq "user_unsubscribe" -and $_.mailing_id -eq $r.report } ) # possibly filter on stamp -gt $responsestartdate                                
                            }

                        }

                        # Now add the type, readable for FERGE
                        $responseObj | Add-Member -MemberType NoteProperty -Name "MessageType" -Value $type

                        # add at minimum one entry to the collection
                        If ( $events.count -ge 1 ) {

                            # There is 1 or multiple events available, so copy the current receivers object and add all of the events like multiple clicks
                            $events | ForEach-Object {
                                $e = $_
                                $eventObj = $responseObj.psobject.copy()
                                $eventObj.timestamp = $e.stamp # TODO convert into other datetime format ?

                                If ($responseType -eq "bounced") {
                                    $eventObj | Add-Member -MemberType NoteProperty -Name "bouncetype" -Value $e.type_id
                                    $eventObj | Add-Member -MemberType NoteProperty -Name "bouncereason" -Value $e.value
                                }

                                If ($responseType -eq "unsubscribed") {
                                    $eventObj | Add-Member -MemberType NoteProperty -Name "groupid" -Value $e.groups_id
                                }

                                [void]$responsesResolved.add($eventObj)
                            }

                        } else {
                            # No event available, just add it with timestamp of mailing
                            [void]$responsesResolved.add($responseObj)
                        }

                    }

                    # Export as a file per response type
                    If ( $responsesResolved.Count -gt 0 ) {
                        $responsesResolved | Export-Csv -path ".\$( $Script:settings.responses.filePrefix )$( $responseType ).csv" -Delimiter "`t" -Encoding UTF8 -NoTypeInformation -Append
                    }

                    # Add results counts to a variable
                    $responseCounts | Add-Member -MemberType NoteProperty -Name $responseType -Value $responsesResolved.count

                }
            }

            Write-Log -message "Done with downloading responses"
            $totalResponses = 0
            $responseCounts.psobject.properties | ForEach-Object {
                Write-Log -message "  $( $_.Name ): $( $_.Value )"
                $totalResponses += $_.Value
            }
            #$script:pluginDebug = $allResponses


            ################################################
            #
            # WRAP UP
            #
            ################################################

            Write-Log -message "Exporting the data into CSV and creating a folder with the id $( $processId )"

            # Save the response timestamp
            If ( $Script:settings.responses.saveLastTimestamp -eq $true ) {
                $tsExp = [PSCustomObject]@{
                    lastResponseDownload = $endTimestamp
                }
                ConvertTo-Json -InputObject $tsExp -Depth 99 | Set-content -path $Script:settings.responses.saveLastTimestampFile -Encoding UTF8
                Write-Log "Saved the timestamp $( $endTimestamp ) for the next execution of response download"
            }

            # TODO test this
            # Trigger FERGE if there are responses
            If ( $Script:settings.responses.triggerFerge -eq $true -and $totalResponses -gt 0 ) {
                Write-Log "Triggering FERGE to bring responses into the database"
                Start-Process $Script:settings.responses.fergePath -WorkingDirectory "."
                Start-Process -FilePath $Script:settings.responses.fergePath -ArgumentList $Script:settings.responses.fergeConfigurationXml

            }


        } catch {

            $msg = "Error during uploading data. Abort!"
            Write-Log -Message $msg -Severity ERROR -WriteToHostToo $false
            Write-Log -Message $_.Exception -Severity ERROR
            throw $_.Exception

        } finally {


            # Close the file reader, if open
            # If the variable is not already declared, that shouldn't be a problem
            try {
                $reader.Close()
            } catch {
            }

            #-----------------------------------------------
            # STOP TIMER
            #-----------------------------------------------

            $processEnd = [datetime]::now
            $processDuration = New-TimeSpan -Start $processStart -End $processEnd
            Write-Log -Message "Needed $( [int]$processDuration.TotalSeconds ) seconds in total"

            #Write-Host "Uploaded $( $j ) record. Confirmed $( $tagcount ) receivers with tag '$( $tags )'"

        }
        

    }
    
    end {

    }

}




