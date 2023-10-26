



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
        # DEFAULT VALUES
        #-----------------------------------------------

        $uploadSize = 2 # TODO put this later into settings and increase it


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
        # [ ] if this needs to much performance, this is not needed
        If ( $Script:settings.upload.countRowsInputFile -eq $true ) {
            $rowsCount = Measure-Rows -Path $file.FullName -SkipFirstRow
            Write-Log -Message "Got a file with $( $rowsCount ) rows"
        } else {
            Write-Log -Message "RowCount of input file not activated"
        }
        #throw [System.IO.InvalidDataException] $msg

        #Write-Log -Message "Debug Mode: $( $Script:debugMode )"


    }

    process {


        try {


            #-----------------------------------------------
            # CREATE GROUP IF NEEDED
            #-----------------------------------------------

            $listId = $InputHashtable.ListName


            #-----------------------------------------------
            # LOAD HEADER AND FIRST ROWS
            #-----------------------------------------------

            # Read first 100 rows
            $deliveryFileHead = Get-Content -Path $file.FullName -ReadCount 100 -TotalCount 201 -Encoding utf8
            $deliveryFileCsv =  ConvertFrom-Csv $deliveryFileHead -Delimiter "`t"

            $headers = [Array]@( $deliveryFileCsv[0].psobject.properties.name )


            #-----------------------------------------------
            # EXAMPLE FOR USING DIFFERENT MODES
            #-----------------------------------------------

            <#
            Switch ( $InputHashtable.mode ) {

                "taggingOnly" {
                    #$tags = ,$params.MessageName -split ","
                    $tags = [Array]@(,$mailing.mailingName) # TODO only allow one tag for the moment, but can easily be extended to multiple ones
                }

                Default {

                    # Combination of a source, a random letter, 7 more random characters and a timestamp
                    $tag = [System.Text.StringBuilder]::new()
                    [void]$tag.Append( $Script:settings.upload.tagSource )
                    [void]$tag.Append( "." )
                    [void]$tag.Append(( Get-RandomString -length 1 -ExcludeSpecialChars -ExcludeUpperCase -ExcludeNumbers ))
                    [void]$tag.Append(( Get-RandomString -length 7 -ExcludeSpecialChars -ExcludeUpperCase ))
                    [void]$tag.Append( "_" )
                    [void]$tag.Append( $processStart.toString("yyyyMMddHHmmss") )

                    If ( ($uploadOnly -eq $true -and $Script:settings.upload.useTagForUploadOnly -eq $true) -or $uploadOnly -eq $false ) {
                        $tags = [Array]@(, $tag.ToString() )
                    } else {
                        $tags = [Array]@()
                    }

                }

            }

            Write-Log -Message "Using the tag: $( $tags -join ", " )"
            #>


            #-----------------------------------------------
            # GO THROUGH FILE IN PARTS
            #-----------------------------------------------

            # Start stream reader
            $reader = [System.IO.StreamReader]::new($file.FullName, [System.Text.Encoding]::UTF8)
            [void]$reader.ReadLine() # Skip first line.

            $emailIndex = $headers.IndexOf($InputHashtable.EmailFieldName)
            $i = 0  # row counter
            $v = 0  # valid counter
            $j = 0  # uploaded entries counter
            $k = 0  # upload batches counter
            $checkObject = [System.Collections.ArrayList]@()
            $uploadObject = [System.Collections.ArrayList]@()
            while ($reader.Peek() -ge 0) {

                #-----------------------------------------------
                # CREATE THE OBJECT/ROW TO UPLOAD
                #-----------------------------------------------

                # raw empty receivers template: https://rest.cleverreach.com/explorer/v3/#!/groups-v3/upsertplus_post
                $uploadEntry = [PSCustomObject]@{
                    #"registered"
                    #"activated"
                    #"deactivated"
                    "email" = "" #$dataCsv[$i].email
                    #"global_attributes" = [PSCustomObject]@{}
                    #"attributes" = [PSCustomObject]@{}
                    #"tags" = [Array]@()
                }

                # values of current row
                $values = $reader.ReadLine().split("`t")

                # put in email address
                $uploadEntry.email = ($values[$emailIndex]).ToLower()

                # Add entry to the check object
                [void]$checkObject.Add( $uploadEntry )


                #-----------------------------------------------
                # VALIDATE AND CHECK ROWS EVERY N ROWS OR AT END
                #-----------------------------------------------

                # Do an validation every n records when threshold is reached or if it is the last row
                $i += 1
                if ( ( $i % $uploadSize ) -eq 0 -or $reader.EndOfStream -eq $true ) {

                    Write-Log "CHECK at row $( $i )"

                    # Load IDs to receivers
                    Write-Log "Validate email addresses"
                    Write-Log "  $( $checkObject.count ) rows"

                    $filter = [Array](
                        [Ordered]@{
                            "propertyName"="email"
                            "operator"="IN"
                            "values"= [Array]@( $checkObject.email.ToLower() )
                        }
                    )

                    $validatedAddresses = @(, ( get-crmdata -Object contacts -Filter $filter )) #-properties email, firstname, lastname
                    $v += $validatedAddresses.count                    
                    
                    # Transform the result
                    $checkedObject = [Array]@( $validatedAddresses.hs_object_id )

                    Write-Log "  $( $checkedObject.count ) left rows"

                    # Add checked objects to uploadobject
                    [void]$uploadObject.AddRange( $checkedObject )

                    # Clear the current object completely
                    $checkObject.Clear()

                }


                #-----------------------------------------------
                # UPLOAD ROWS EVERY N ROWS OR AT END
                #-----------------------------------------------

                # Do an upload when threshold is reached
                if ( $uploadObject.Count -ge $uploadSize -or $reader.EndOfStream -eq $true ) { # Commit, when size is reached

                    $uploadFinished = $false

                    Write-Log "UPLOAD at row $( $i )"
                    Write-Log "  $( $uploadObject.count ) objects ready for upload"

                    Do {

                        Write-Log "  $( ( $uploadObject[0..$uploadSize] ).count ) objects/rows will be uploaded"

                        $uploadBody = $uploadObject[0..( $uploadSize - 1 )]

                        If ( $uploadBody.count -gt 0 ) {

                            # Output the request body for debug purposes
                            #Write-Log -Message "Debug Mode: $( $Script:debugMode )"
                            If ( $Script:debugMode -eq $true ) {
                                $tempFile = ".\$( $i )_$( [guid]::NewGuid().tostring() )_request.txt"
                                Set-Content -Value ( ConvertTo-Json $uploadBody -Depth 99 ) -Encoding UTF8 -Path $tempFile
                            }

                            # As a response we get the id of added/removed members back
                            Switch ( $mailing.mailingId ) {

                                "add" {
                                    $upload = @( Add-ListMember -ListId 355 -AddMemberships $uploadObject )
                                    $j += $upload.recordsIdsAdded.count
                                }

                                "del" {
                                    $upload = @( Remove-ListMember -ListId 355 -RemoveMemberships $uploadObject )
                                    $j += $upload.recordIdsRemoved.count
                                }

                                default {
                                    throw "This upload mode is not supported yet"   # should not happen!
                                }

                            }
                            
                            # Count the batches
                            $k += 1

                            # Output the response body for debug purposes
                            If ( $Script:debugMode -eq $true ) {
                                $script:debug += $upload
                                $tempFile = ".\$( $i )_$( [guid]::NewGuid().tostring() )_response.txt"
                                Set-Content -Value ( ConvertTo-Json $upload -Depth 99 ) -Encoding UTF8 -Path $tempFile
                            }

                            $uploadObject.RemoveRange(0,$uploadBody.Count)

                        } else {

                            Write-Log "No more data to upload"

                        }

                        # Do an extra round for remaining records AND if it is the last row
                        If ( $uploadObject.count -gt 0 -and $reader.EndOfStream -eq $true) {
                            $uploadFinished = $true
                        } else {
                            $uploadFinished = $true # Otherwise always do only one upload
                        }

                    } Until ( $uploadFinished -eq $true )

                }

            }

            Write-Log "Stats for upload"
            Write-Log "  checked $( $i ) rows"
            Write-Log "  $( $v ) valid rows"
            Write-Log "  $( $j ) uploaded records"
            Write-Log "  $( $k ) uploaded batches"


        } catch {

            $msg = "Error during uploading data in line $( $_.InvocationInfo.ScriptLineNumber ). Abort!"
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


            #-----------------------------------------------
            # SEND STATUS TO ORBIT
            #-----------------------------------------------

            Switch ( $mailing.mailingId ) {

                "add" {
                    Write-Log "Added $( $j ) records in $( $k ) batches." -severity INFO
                }

                "del" {
                    Write-Log "Removed $( $j ) records in $( $k ) batches." -severity INFO                }

            }
            
        }


        #-----------------------------------------------
        # RETURN VALUES TO PEOPLESTAGE
        #-----------------------------------------------

        # count the number of successful upload rows
        $recipients = $j #$dataCsv.Count # TODO work out what to be saved

        # put in the source id as the listname
        $transactionId = Get-ProcessId

        # return object
        $return = [Hashtable]@{

            # Mandatory return values
            "Recipients"=$recipients
            "TransactionId"=$transactionId

            # General return value to identify this custom channel in the broadcasts detail tables
            "CustomProvider"= $Script:settings.providername
            "ProcessId" = Get-ProcessId #$Script:processId

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




