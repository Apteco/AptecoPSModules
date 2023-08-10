



function Invoke-Broadcast{

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
        # VALUES FROM UPLOAD
        #-----------------------------------------------

        Set-ProcessId -Id $InputHashtable.ProcessId
        $tag = ( $InputHashtable.Tag -split ", " )
        $groupId = $InputHashtable.GroupId


        #-----------------------------------------------
        # LOG
        #-----------------------------------------------

        $moduleName = "BROADCAST"

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
        # CHECK CLEVERREACH CONNECTION
        #-----------------------------------------------

        try {

            Test-CleverReachConnection

        } catch {

            Write-Log -Message $_.Exception -Severity ERROR
            throw [System.IO.InvalidDataException] $msg
            exit 0

            # TODO is exit needed here?

        }

    }

    process {


        try {

            #-----------------------------------------------
            # CHECK THE CURRENT SENDING MODE
            #-----------------------------------------------

            $doRelease = $false
            Switch ( $InputHashtable.mode ) {

                "taggingOnly" {

                    # broadcast is not needed
                    Write-Log -Message "Mode 'taggingOnly'. Triggering the broadcast script is not needed. Please change your settings to 'Upload Only'" -Severity WARNING
                    exit 0 # leave the script now

                }

                "prepare" {

                    # broadcast is not needed
                    Write-Log -Message "Mode 'prepare'. Everything gets prepared, but not sending takes place" -Severity WARNING
                    $doRelease = $false

                }

                Default {

                    Write-Log -Message "No specific upload mode defined in the channel. Proceeding triggering a mailing."
                    $doRelease = $true

                }

            }


            #-----------------------------------------------
            # GET GENERAL STATISTICS FOR LIST
            #-----------------------------------------------

            # Write-Log "Getting stats for group $( $groupId ):"

            # #$groupStats = Invoke-CR -Object "groups" -Path "/$( $groupId )/stats" -Method GET -Verbose
            # $groupStats = Get-GroupStatsByRuntime -GroupId $groupId #-IncludeMetrics -IncludeLastChanged -Verbose


            # <#
            # {
            #     "total_count": 4,
            #     "inactive_count": 0,
            #     "active_count": 4,
            #     "bounce_count": 0,
            #     "avg_points": 69.5,
            #     "quality": 3,
            #     "time": 1685545449,
            #     "order_count": 0
            # }
            # #>

            # $groupStats.psobject.properties | ForEach-Object {
            #     Write-Log "  $( $_.Name ): $( $_.Value )"
            # }


            #-----------------------------------------------
            # GET STATISTICS FOR TAGS
            #-----------------------------------------------

            $tag | ForEach-Object {

                $t = $_

                Write-Log "Getting tag stats for tag $( $t ) for group $( $groupId )"

                $tagQuery = [PSCustomObject]@{
                    "tag" = $t
                    "group_id" = $groupId
                    "active" = $true
                }
                $tagCount = Invoke-CR -Object "tags" -Path "/count" -Method GET -Verbose -Query $tagQuery

                Write-Log "Got $( $tagCount ) receivers for tag $( $t ) in group $( $groupId )"

            }


            #-----------------------------------------------
            # READ MAILING DETAILS
            #-----------------------------------------------

            # get details of mailing
            $templateSource = Invoke-CR -Object "mailings" -Path "/$( $templateId )" -Method GET -Verbose
            $newMailingName = "$( $templateSource.name ) - $( $processStart.ToString("yyyyMMddHHmmss") )"
            Write-Log -message "Looked up the mailing '$( $templateId )' with name '$( $templateSource.Name )'"
            Write-Log -message "New mailing name: '$( $newMailingName )'"


            #-----------------------------------------------
            # CREATE SEGMENT FOR THE BROADCAST
            #-----------------------------------------------

            Write-Log "Creating a new filter/segment on group '$( $groupId )'"

            $rules = [System.Collections.ArrayList]@() #[ArrayList]@()

            # Add the first part to the rules
            [void]$rules.add(
                [PSCustomObject]@{
                    "operator"= ""
                    "field"= "("
                    "logic"= ""
                    "condition"= ""
                }
            )

            # Add all tag rules - they are combined together, so you need to have all tags in combination
            $tag | ForEach-Object {
                $t = $_
                [void]$rules.add(
                    [PSCustomObject]@{
                        "operator"= "AND"
                        "field" = "tags"
                        "logic" = "CONTAINS"
                        "condition" = $t
                    }
                )
            }

            # End of the first part
            [void]$rules.add(
                [PSCustomObject]@{
                    "operator"= ""
                    "field"= ")"
                    "logic"= ""
                    "condition"= ""
                }
            )

            # Now add the rules, that are used always
            [void]$rules.addrange([array]@(,
                [PSCustomObject]@{
                    "operator"= "AND"
                    "field"= "("
                    "logic"= ""
                    "condition"= ""
                }
                [PSCustomObject]@{
                    "operator"= "AND"
                    "field" = "activated"
                    "logic" = "bg"
                    "condition" = "1"
                }
                [PSCustomObject]@{
                    "operator"= "AND"
                    "field" = "deactivated"
                    "logic" = "eq"
                    "condition" = "0"
                }
                [PSCustomObject]@{
                    "operator"= "AND"
                    "field" = "bounced"
                    "logic" = "eq"
                    "condition" = "0"
                }
                [PSCustomObject]@{
                    "operator"= ""
                    "field"= ")"
                    "logic"= ""
                    "condition"= ""
                }
            ))

            $filterBody = [PSCustomObject]@{
                "name" = "$( $Script:settings.upload.tagSource ).$( $newMailingName )"
                #"operator" = "AND"
                "rules" = $rules
            }

            $segment = Invoke-CR -Object "groups" -Path "/$( $groupId )/filters" -Method POST -Verbose -Body $filterBody

            #$script:debug = $segment

            # We are gettting the 'id' and 'success' back
            If ( $segment.success -eq $true ) {
                Write-Log "Created a new filter/segment with id '$( $segment.id )' and name '$( $newMailingName )'"
            } else {
                throw "There was a problem creating the segment"
            }


            #-----------------------------------------------
            # COUNT SEGMENT
            #-----------------------------------------------

            $segmentCount = Invoke-CR -Object "groups" -Path "/$( $groupId )/filters/$( $segment.id )/count" -Method GET -Verbose

            If ( $segmentCount -gt 0 ) {
                Write-Log "Count of this segment: $( $segmentCount )"
            } else {
                throw "Not able to count segment '$( $segment.id )'. Stopping here!"
            }


            #-----------------------------------------------
            # ADDING A PREHEADER IF DEFINED
            #-----------------------------------------------

            # The cleverreach preheader looks like
            # <div id="CR-PRHEADER" style="display:none;font-size:1px;line-height:1px;max-height:0px;max-width:0px;opacity:0;overflow:hidden;mso-hide:all;">...</div>

            # This needs to be the first element after the body of
            # $templateSource.body_html
            # So doing a replace after the body tag
            # This will just place a variable that needs to be defined in the receivers entry with "preheader"

            # TODO Think about putting this into the settings
            #$preheaderTemplate = '<div style="font-size:0px;line-height:1px;mso-line-height-rule:exactly;display:none;max-width:0px;max-height:0px;opacity:0;overflow:hidden;mso-hide:all;">[PREHEADER]</div>'
            $preheaderVariable = $Script:settings.broadcast.preheaderFieldname.ToUpper()
            $preheaderTemplate = @"
                <div style="display:none;font-size:1px;line-height:1px;max-height:0px;max-width:0px;opacity:0;overflow:hidden;mso-hide:all;">{$( $preheaderVariable )}&zwnj;&nbsp;&zwnj;&nbsp;&zwnj;&nbsp;&zwnj;&nbsp;&zwnj;&nbsp;&zwnj;&nbsp;&zwnj;&nbsp;&zwnj;&nbsp;&zwnj;&nbsp;&zwnj;&nbsp;&zwnj;&nbsp;&zwnj;&nbsp;&zwnj;&nbsp;&zwnj;&nbsp;&zwnj;&nbsp;&zwnj;&nbsp;&zwnj;&nbsp;&zwnj;&nbsp;&zwnj;&nbsp;&zwnj;&nbsp;&zwnj;&nbsp;&zwnj;&nbsp;&zwnj;&nbsp;&zwnj;&nbsp;&zwnj;&nbsp;&zwnj;&nbsp;&zwnj;&nbsp;&zwnj;&nbsp;&zwnj;&nbsp;&zwnj;&nbsp;&zwnj;&nbsp;&zwnj;&nbsp;&zwnj;&nbsp;&zwnj;&nbsp;&zwnj;&nbsp;&zwnj;&nbsp;&zwnj;&nbsp;&zwnj;&nbsp;&zwnj;&nbsp;&zwnj;&nbsp;&zwnj;&nbsp;&zwnj;&nbsp;&zwnj;&nbsp;&zwnj;&nbsp;&zwnj;&nbsp;&zwnj;&nbsp;&zwnj;&nbsp;&zwnj;&nbsp;&zwnj;&nbsp;&zwnj;&nbsp;&zwnj;&nbsp;&zwnj;&nbsp;&zwnj;&nbsp;&zwnj;&nbsp;&zwnj;&nbsp;&zwnj;&nbsp;&zwnj;&nbsp;&zwnj;&nbsp;&zwnj;&nbsp;&zwnj;&nbsp;&zwnj;&nbsp;&zwnj;&nbsp;&zwnj;&nbsp;&zwnj;&nbsp;&zwnj;&nbsp;&zwnj;&nbsp;&zwnj;&nbsp;&zwnj;&nbsp;&zwnj;&nbsp;&zwnj;&nbsp;&zwnj;&nbsp;&zwnj;&nbsp;&zwnj;&nbsp;&zwnj;&nbsp;&zwnj;&nbsp;&zwnj;&nbsp;&zwnj;&nbsp;&zwnj;&nbsp;&zwnj;&nbsp;&zwnj;&nbsp;&zwnj;&nbsp;&zwnj;&nbsp;&zwnj;&nbsp;&zwnj;&nbsp;&zwnj;&nbsp;&zwnj;&nbsp;&zwnj;&nbsp;&zwnj;&nbsp;&zwnj;&nbsp;&zwnj;&nbsp;&zwnj;&nbsp;&zwnj;&nbsp;&zwnj;&nbsp;&zwnj;&nbsp;&zwnj;&nbsp;&zwnj;&nbsp;&zwnj;&nbsp;&zwnj;&nbsp;&zwnj;&nbsp;&zwnj;&nbsp;&zwnj;&nbsp;&zwnj;&nbsp;&zwnj;&nbsp;&zwnj;&nbsp;&zwnj;&nbsp;&zwnj;&nbsp;&zwnj;&nbsp;</div>
"@

            # Find the right place to insert after
            $bodyRegex = "<body[^\>]*>"

            # Regex to find the native cleverreach preheader
            $crPreheaderRegex = '<div.*id="CR-PRHEADER".*?/div>'

            <#
            $htmlText = @"
            <html>
            <header>
            </header>
            <body jay jay jay test="hello">
            Hello world
            </body>
            </html>
            "@

            $htmlText -replace $bodyRegex, "$( $matches[0] )$( $preheaderTemplate )"
            #>

            # This is the html of the mailing
            $htmlTemplate = $templateSource.body_html

            # Add the preheader, if wished
            If ( $Script:settings.broadcast.addPreheaderAfterBody -eq $true -and $InputHashtable.PreheaderIsSet -eq $true) {

                #$Script:plugindebug = $templateSource.body_html

                # Remove CR preheader, if needed
                $nativePreheaderRegexMatch = $htmlTemplate -match $crPreheaderRegex
                If ( $Script:settings.broadcast.removeNativePreheader -eq $true -and $nativePreheaderRegexMatch) {
                    $html = $htmlTemplate -replace $crPreheaderRegex, ""
                    Write-Log "Removed native CleverReach PreHeader"
                } else {
                    Write-Log "No native CleverReach PreHeader found"
                }

                # Replace the existing body tag with the body tag and the new preheader
                $regexMatch = $html -match $bodyRegex
                If ( $regexMatch -eq $true ) {
                    $matchedBodyTag = $matches[0]
                    $html = $html -replace $bodyRegex, "$( $matchedBodyTag )$( $preheaderTemplate )"
                    Write-Log "Added custom PreHeader with {$( $preheaderVariable )} variable/field"
                } else {
                    Write-Log "Body tag for inserting PreHeader not found"
                }

                $Script:plugindebug = $html

            } else {

                Write-Log "No replacement of preheader"
                $html = $htmlTemplate

            }


            #-----------------------------------------------
            # COPY/DUPLICATE THE MAILING AND USE SEGMENT
            #-----------------------------------------------

            Write-Log -message "Creating a copy of the mailing"

            $mailingSettings = [PSCustomObject]@{
                "name" = $newMailingName
                "subject" = $templateSource.subject
                "sender_name" = $templateSource.sender_name
                "sender_email" = $templateSource.sender_email
                "content" = [PSCustomObject]@{
                    "type" = $Script:settings.broadcast.defaultContentType
                    "html" = $html
                    "text" = $templateSource.body_text
                }
                "receivers" = [PSCustomObject]@{
                    #"groups" = [Array]@(, $groupId )
                    "filter" = $segment.id
                }
                "settings" = [PSCustomObject]@{
                    "editor" = $Script:settings.broadcast.defaultEditor
                    #"open_tracking" = $settings.broadcast.defaultOpenTracking
                    #"click_tracking" = $settings.broadcast.defaultClickTracking
                    #"category_id" = $templateSource.category_id
                    <#
                    link_tracking_url = "27.wayne.cleverreach.com"
                    link_tracking_type = "google" # google|intelliad|crconnect
                    unsubscribe_form_id = "23"
                    campaign_id = "52"
                    #>
                }
                "tags" = [Array]@( $templateSource.tags ) #[Array]@(, ($templateSource.tags | Where-Object { $_ -notin [Array]@( "cr-mailing-envelope" ) }))
            }

            # Category
            If ( $templateSource.category_id -gt 0 ) {
                $mailingSettings.settings | Add-Member -MemberType NoteProperty -Name "category_id" -Value $templateSource.category_id
            }

            # Tracking
            If ( $templateSource.is_trackable -eq $true ) {
                $mailingSettings.settings | Add-Member -MemberType NoteProperty -Name "open_tracking" -Value $Script:settings.broadcast.defaultOpenTracking
                $mailingSettings.settings | Add-Member -MemberType NoteProperty -Name "click_tracking" -Value $Script:settings.broadcast.defaultClickTracking
            }
            If ( $Script:settings.broadcast.defaultLinkTrackingUrl -ne "" ) {
                $mailingSettings.settings | Add-Member -MemberType NoteProperty -Name "link_tracking_url" -Value $Script:settings.broadcast.defaultLinkTrackingUrl
            }
            If ( $Script:settings.broadcast.defaultLinkTrackingType -ne "" ) {
                $mailingSettings.settings | Add-Member -MemberType NoteProperty -Name "link_tracking_type" -Value $Script:settings.broadcast.defaultLinkTrackingType
            }
            If ( $Script:settings.broadcast.defaultGoogleCampaignName -ne "" ) {
                $mailingSettings.settings | Add-Member -MemberType NoteProperty -Name "google_campaign_name" -Value $Script:settings.broadcast.defaultGoogleCampaignName
            }

            # Unsubscribe
            If ( $templateSource.unsubscribe_form_id -gt 0 ) {
                $mailingSettings.settings | Add-Member -MemberType NoteProperty -Name "unsubscribe_form_id" -Value $templateSource.unsubscribe_form_id
            }

            $script:debug = $mailingSettings

            # put it all together
            $copiedMailing = Invoke-CR -Object "mailings" -Method POST -Verbose -body $mailingSettings

            Write-Log -message "Created a copy of the mailing with the new id $( $copiedMailing.id )"


            #-----------------------------------------------
            # BROADCAST MAILING (IF ALLOWED BY CLEVERREACH)
            #-----------------------------------------------

            If ( $doRelease -eq $true ) {

                $releaseTimestamp = (Get-Unixtime) + $Script:settings.broadcast.defaultReleaseOffset
                $releaseBody = [PSCustomObject]@{
                    time  = [int]$releaseTimestamp
                }
                Invoke-CR -Object "mailings" -Path "/$( $copiedMailing.id )/release" -Method POST -Verbose -body $releaseBody

                Write-Log "Released mailing for unix timestamp at $( $releaseTimestamp )"

                # Wait until finished
                If ( $Script:settings.broadcast.waitUntilFinished -eq $true ) {

                    $maxWaitTime = [int]$Script:settings.broadcast.defaultReleaseOffset + [int]$Script:settings.broadcast.maxWaitForFinishedAfterOffset
                    $secondsToWait = 5
                    $i = 0
                    Do {

                        # Wait and count
                        Start-Sleep -Seconds $secondsToWait
                        $i += $secondsToWait

                        # Ask for the current status
                        $mailingStatus = Invoke-CR -Object "mailings" -Path "/$( $copiedMailing.id )" -Method GET -Verbose

                    } Until ( $i -gt $maxWaitTime -or $mailingStatus.state -eq "finished" )

                    # Log the exit of the loop
                    If ( $mailingStatus.state -eq "finished" ) {
                        # All good
                        Write-Log "Mailing finished successfully after $( $i ) seconds (Offset: $( [int]$Script:settings.broadcast.defaultReleaseOffset ))" -Severity INFO
                    } else {
                        # Something went wrong
                        Write-Log "Mailing exceeded the maximum wait time of $( $maxWaitTime ) seconds" -Severity WARNING
                    }

                }

            } else {

                Write-Log "Mailing not released"

            }


        } catch {

            #$msg = "Error during writing data. Abort!"
            #Write-Log -Message $msg -Severity ERROR
            #Write-Log -Message $_.Exception -Severity ERROR
            #throw [System.IO.InvalidDataException] $msg

            $msg = "Error during broadcasting data. Abort!"
            Write-Log -Message $msg -Severity ERROR -WriteToHostToo $false
            Write-Log -Message $_.Exception -Severity ERROR
            throw $_.Exception

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

        # count the number of successful upload rows
        $recipients = $tagCount

        # put in the source id as the listname
        $transactionId = $copiedMailing.id

        # return object
        $return = [Hashtable]@{

            # Mandatory return values
            "Recipients"=$recipients
            "TransactionId"=$transactionId

            # General return value to identify this custom channel in the broadcasts detail tables
            "CustomProvider"=  $Script:settings.providername
            "ProcessId" = $Script:processId

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




