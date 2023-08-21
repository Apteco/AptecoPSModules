



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

        $uploadSize = $Script:settings.upload.uploadSize
        Write-Log "Got UploadSize of $( $uploadSize ) rows/objects" #-Severity WARNING
        If ($uploadSize -gt 1000 ) {
            Write-Log "UploadSize has been set to more than 1000 rows. Using max of 1000 now!" -Severity WARNING
            $uploadSize = 1000
        }

        # Currently CleverReach support 40 attributes
        $maxAttributesCount = 40


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
            # CREATE GROUP IF NEEDED
            #-----------------------------------------------

            # If lists contains a concat character (id+name), use the list id
            # if no concat character is present, take the whole string as name for a new list and search for it... if not present -> new list!
            # if no list is present, just take the current date and time

            # If listname is valid -> contains an id, concatenation character and and a name -> use the id
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


            #-----------------------------------------------
            # GET GENERAL STATISTICS FOR LIST
            #-----------------------------------------------

            Write-Log "Getting stats for group $( $groupId )"

            #$groupStats = Invoke-CR -Object "groups" -Path "/$( $groupId )/stats" -Method GET -Verbose
            $groupStats = Get-GroupStats -GroupId $groupId

            <#
            {
                "total_count": 4,
                "inactive_count": 0,
                "active_count": 4,
                "bounce_count": 0,
                "avg_points": 69.5,
                "quality": 3,
                "time": 1685545449,
                "order_count": 0
            }
            #>

            $groupStats.psobject.properties | ForEach-Object {
                Write-Log "  $( $_.Name ): $( $_.Value )"
            }


            #-----------------------------------------------
            # LOAD HEADER AND FIRST ROWS
            #-----------------------------------------------

            # Read first 100 rows
            $deliveryFileHead = Get-Content -Path $file.FullName -ReadCount 1 -TotalCount 201 -Encoding utf8
            $deliveryFileCsv =  ConvertFrom-Csv $deliveryFileHead -Delimiter "`t"

            $headers = [Array]@( $deliveryFileCsv[0].psobject.properties.name )
            <#
            $headers | ForEach {

                $header = $_

                $sqliteParameterObject = $sqliteDeliveryInsertCommand.CreateParameter()
                $sqliteParameterObject.ParameterName = ":$( $header -replace '[^a-z0-9]', '' )"
                [void]$sqliteDeliveryInsertCommand.Parameters.Add($sqliteParameterObject)

                [void]$sqliteDeliveryCreateFields.Add( """$( $header )"" TEXT" )

            }#>

            $reservedFieldsCheck = Compare-Object -ReferenceObject $headers -DifferenceObject $Script:settings.upload.reservedFields -IncludeEqual
            If ( ( $reservedFieldsCheck | Where-Object { $_.SideIndicator -eq "==" } ).count -gt 0 ) {

                $msg = "You have used reserved fields:"
                Write-Log -Message $msg -Severity ERROR

                $reservedFieldsCheck | Where-Object { $_.SideIndicator -eq "==" } | ForEach-Object {
                    Write-Log -Message "  $( $_.InputObject )"
                }

                throw [System.IO.InvalidDataException] $msg
                exit 0

            }


            #-----------------------------------------------
            # CHECK ADDITIONAL TAGS
            #-----------------------------------------------

            $additionalTagging = $false
            If ( $headers.toLower() -contains "tags") {
                $additionalTagging = $true
                $tagsIndex = $headers.toLower().IndexOf("tags")
            }


            #-----------------------------------------------
            # CHECK ATTRIBUTES
            #-----------------------------------------------

            $requiredFields = @( $InputHashtable.EmailFieldName, $InputHashtable.UrnFieldName )
            $reservedFields = @( $Script:settings.upload.reservedFields ) #@("tags")
            Write-Log -message "Required fields: $( $requiredFields -join ", " )"
            Write-Log -message "Reserved fields: $( $reservedFields -join ", " )"

            $csvAttributesNames = $headers | Where-Object { $_.toLower() -notin $reservedFields }
            #$csvAttributesNames = Get-Member -InputObject $dataCsv[0] -MemberType NoteProperty | where { $_.Name -notin $reservedFields }
            Write-Log -message "Loaded csv attributes: $( $csvAttributesNames -join ", " )"

            $attributeParam = [Hashtable]@{
                "reservedFields" = $reservedFields  # TODO [ ] not used yet
                "requiredFields" = $requiredFields
                "csvAttributesNames" = $csvAttributesNames
                "csvUrnFieldname" = $InputHashtable.UrnFieldName
                "csvCommunicationKeyFieldName" = $InputHashtable.CommunicationKeyFieldName
                "responseUrnFieldname" = $Script:settings.responses.urnFieldName
                "groupId" = $groupId
            }

            # Logging attribute sync settings
            Write-Log "Attribute sync settings:"
            $attributeParam.Keys | ForEach-Object {
                $param = $_
                Write-Log -message "    $( $param ) = '$( $attributeParam[$param] )'" #-writeToHostToo $false
            }

            $attributes = Sync-Attribute @attributeParam


            #-----------------------------------------------
            # CHECK ATTRIBUTES FOR PREHEADER FIELD
            #-----------------------------------------------

            If ( $csvAttributesNames.toLower() -contains $Script:settings.broadcast.preheaderFieldname.toLower() ) {
                $preheaderIsSet = $true
            } else {
                $preheaderIsSet = $false
            }


            #-----------------------------------------------
            # BEGIN AN EXCLUSION LIST
            #-----------------------------------------------

            $exclusionList = [System.Collections.ArrayList]@()


            #-----------------------------------------------
            # LOAD DEACTIVATED/UNSUBSCRIBES
            #-----------------------------------------------

            # Load global inactive receivers (unsubscribed)
            If ( $Script:settings.upload.excludeGlobalDeactivated -eq $true ) {

                $globalDeactivated = @( Get-GlobalDeactivated ) # use a copy so the reference is not changed because it will used a second time
                #$script:debug = $globalDeactivated
                Write-Log -Message "Adding $( $globalDeactivated.count ) global inactive receivers to exclusion list"
                If ( $globalDeactivated.Count -gt 0 ) {
                    $exclusionList.AddRange( @( $globalDeactivated.email.toLower() ) )
                }

            }

            # Runtime filter with paging
            If ( $Script:settings.upload.excludeLocalDeactivated -eq $true ) {

                $localDeactivated = @( (Get-LocalDeactivated -GroupId $groupId) )
                Write-Log -Message "Adding $( $localDeactivated.count ) local inactive receivers to exclusion list"
                If ( $localDeactivated.count -gt 0 ) {
                    $exclusionList.AddRange( @( $localDeactivated.email.toLower() ) )
                }

            }


            #-----------------------------------------------
            # LOAD BOUNCES
            #-----------------------------------------------

            # Load global bounces as a list
            $bounced = [Array]@( Get-Bounces )

            # Log
            Write-Log -Message "There are currently $( $bounced.count ) bounces in your account"
            $c | Group-Object category | ForEach-Object {
                Write-Log -Message "  $( $_.Name ): $( $_.Count )"
            }

            # Add to list
            If ( $Script:settings.upload.excludeBounces -eq $true ) {
                Write-Log -Message "Adding $( $bounced.count ) bounced receivers to exclusion list"
                If ( $bounced.count -gt 0 ) {
                    [void]$exclusionList.AddRange( @( $bounced.email.toLower() ) )
                }
            }


            #-----------------------------------------------
            # CHECK EXCLUSION LIST
            #-----------------------------------------------

            Write-Log "There are $( $exclusionList.count ) entries on the exclusion list now"


            #-----------------------------------------------
            # BUILDING THE TAG TO USE
            #-----------------------------------------------

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


            #-----------------------------------------------
            # GO THROUGH FILE IN PARTS
            #-----------------------------------------------

            # Start stream reader
            $reader = [System.IO.StreamReader]::new($file.FullName, [System.Text.Encoding]::UTF8)
            [void]$reader.ReadLine() # Skip first line.

            #$Script:debug = $reader

            $globalAtts = @( $attributes.global | Where-Object { $_.name -in $headers } )
            $headersLower = @( $headers.tolower() )

            #$localAtts = $localAttributes | where { $_.name -in $headers }

            $i = 0  # row counter
            $v = 0  # valid counter
            $j = 0  # uploaded entries counter
            $k = 0  # upload batches counter
            $checkObject = [System.Collections.ArrayList]@()
            $uploadObject = [System.Collections.ArrayList]@()
            while ($reader.Peek() -ge 0) {

                # raw empty receivers template: https://rest.cleverreach.com/explorer/v3/#!/groups-v3/upsertplus_post
                $uploadEntry = [PSCustomObject]@{
                    #"registered"
                    #"activated"
                    #"deactivated"
                    "email" = "" #$dataCsv[$i].email
                    "global_attributes" = [PSCustomObject]@{}
                    "attributes" = [PSCustomObject]@{}
                    "tags" = [Array]@()
                }

                # values of current row
                $values = $reader.ReadLine().split("`t")

                # put in email address
                $emailIndex = $headers.IndexOf($InputHashtable.EmailFieldName)
                $uploadEntry.email = ($values[$emailIndex]).ToLower()

                # go through every header and fill it into the object
                <#
                For ( $x = 0; $x -lt $values.Count; $x++ ) {
                    Switch ( $header[$x] ) {

                        # Email address, normally email
                        $InputHashtable.EmailFieldName {
                            $uploadEntry."email" = $values[$x]
                            break
                        }

                        # Global attribute
                        ({ $globalAtts -contains $PSItem }) {
                            $uploadEntry."global_attributes" | Add-Member -MemberType NoteProperty -Name $header[$x] -Value $values[$x]
                            break
                        }

                        # Local attribute
                        ({ $localAtts -contains $PSItem }) {
                            $uploadEntry."attributes" | Add-Member -MemberType NoteProperty -Name $header[$x] -Value $values[$x]
                            break
                        }

                    }
                }

                $uploadEntry.tags = $tags
                #>

                # Global attributes
                $globalAtts | ForEach-Object {

                    $attrName = $_.name.toLower() # using description now rather than name, because the comparison is made on descriptions
                    $attrDescription = $_.description.toLower()
                    $value = $null

                    $nameIndex = $headersLower.IndexOf($attrName)
                    $descriptionIndex = $headersLower.IndexOf($attrDescription)
                    # If nothing found, the index is -1
                    If ( $nameIndex -ge 0) {
                        $value = $values[$nameIndex]
                    } elseif ( $descriptionIndex -ge 0 ) {
                        $value = $values[$descriptionIndex]
                    }

                    If( $null -ne $value ) {
                        $uploadEntry.global_attributes | Add-Member -MemberType NoteProperty -Name $attrName -Value $value
                    }

                }

                # New local attributes
                $attributes.new | ForEach-Object {

                    $attrName = $_.name.toLower() # using description now rather than name, because the comparison is made on descriptions
                    $attrDescription = $_.description.toLower()
                    $value = $null

                    $nameIndex = $headersLower.IndexOf($attrName)
                    $descriptionIndex = $headersLower.IndexOf($attrDescription)
                    # If nothing found, the index is -1
                    If ( $nameIndex -ge 0) {
                        $value = $values[$nameIndex]
                    } elseif ( $descriptionIndex -ge 0 ) {
                        $value = $values[$descriptionIndex]
                    }

                    If( $null -ne $value ) {
                        $uploadEntry.attributes | Add-Member -MemberType NoteProperty -Name $attrName -Value $value
                    }
                }

                # Existing local attributes
                $attributes.local | ForEach-Object {

                    # If ( $_.name -eq $InputHashtable.CommunicationKeyFieldName ) {
                    #     $attrName = $InputHashtable.CommunicationKeyFieldName.ToUpper().replace(" ","_")
                    # } else {
                    #     $attrName = $_.name # using description now rather than name, because the comparison is made on descriptions
                    # }
                    $attrName = $_.name.toLower() # using description now rather than name, because the comparison is made on descriptions
                    $attrDescription = $_.description.toLower()
                    $value = $null

                    $nameIndex = $headersLower.IndexOf($attrName)
                    $descriptionIndex = $headersLower.IndexOf($attrDescription)
                    # If nothing found, the index is -1
                    If ( $nameIndex -ge 0) {
                        $value = $values[$nameIndex]
                    } elseif ( $descriptionIndex -ge 0 ) {
                        $value = $values[$descriptionIndex]
                    }

                    If( $null -ne $value ) {
                        $uploadEntry.attributes | Add-Member -MemberType NoteProperty -Name $attrName -Value $value
                    }

                }

                # Communication Key if not present yet through local or new attributes
                $uploadProperties = [Array]@()
                $uploadProperties = [Array]@( $uploadEntry.attributes.psobject.properties.name )
                $normalisedCommkeyName = $InputHashtable.CommunicationKeyFieldName.toLower().replace(" ","_")
                If ( $uploadProperties -notcontains $InputHashtable.CommunicationKeyFieldName -or $uploadProperties -notcontains $normalisedCommkeyName) {
                    If ( $attributes.local.description -contains $normalisedCommkeyName) {
                        $attrName = $normalisedCommkeyName
                    } else {
                        $attrName = $InputHashtable.CommunicationKeyFieldName
                    }
                    $nameIndex = $headers.IndexOf($InputHashtable.CommunicationKeyFieldName)
                    $value = $values[$nameIndex]
                    $uploadEntry.attributes | Add-Member -MemberType NoteProperty -Name $attrName -Value $value
                }

                # Tags
                <#
                In the array of tags, prepend a "-" to the tag you want to be removed.
                To remove all tags with a specific origin, simply specify "*" instead of any tag name.
                #>
                If ( $additionalTagging -eq $true ) {
                    $additionalTags = @( $values[$tagsIndex] -split "," ).trim()
                    $uploadEntry.tags = @( @( $additionalTags ) + @( $tags ) )
                } else {
                    $uploadEntry.tags = @( $tags )
                }

                # AptecoPreheader
                <#
                Make sure the preheader is getting overwritten to an empty value if not set
                #>
                If ( $preheaderIsSet -eq $true ) {

                    # Find out if the preheader is global or local and change the value to ""
                    If ( @( $uploadEntry.attributes.psobject.properties.name.toLower() ) -contains $Script:settings.broadcast.preheaderFieldname.toLower() ) {
                        If ( "" -eq $uploadEntry.attributes.( $Script:settings.broadcast.preheaderFieldname ) -or "null" -eq $uploadEntry.attributes.( $Script:settings.broadcast.preheaderFieldname ) ) {
                            $uploadEntry.attributes.( $Script:settings.broadcast.preheaderFieldname ) = ""
                        }
                    } ElseIf ( @( $uploadEntry.global_attributes.psobject.properties.name.toLower() ) -contains $Script:settings.broadcast.preheaderFieldname.toLower() ) {
                        If ( "" -eq $uploadEntry.global_attributes.( $Script:settings.broadcast.preheaderFieldname ) -or "null" -eq $uploadEntry.global_attributes.( $Script:settings.broadcast.preheaderFieldname ) ) {
                            $uploadEntry.global_attributes.( $Script:settings.broadcast.preheaderFieldname ) = ""
                        }
                    }

                }


                # Add entry to the check object
                [void]$checkObject.Add( $uploadEntry )

                # Do an validation every n records when threshold is reached or if it is the last row
                $i += 1
                if ( ( $i % $uploadSize ) -eq 0 -or $reader.EndOfStream -eq $true) { # Commit every 50k records

                    Write-Log "CHECK at row $( $i )"

                    # Validate receivers
                    If ( $Script:settings.upload.validateReceivers -eq $true -and $createNewGroup -eq $false ) {
                        # TODO validate receivers through cleverreach, check abount bounces

                        Write-Log "Validate email addresses"
                        Write-Log "  $( $checkObject.count ) rows"

                        $validateObj = [PSCustomObject]@{
                            "emails" = [Array]@( $checkObject.email ).toLower()
                            "group_id" = $groupId
                            "invert" = $false
                        }
                        $validatedAddresses = @(, (Invoke-CR -Object "receivers" -Path "/isvalid" -Method POST -Verbose -Body $validateObj ))
                        #$Script:debug = $validatedAddresses
                        $v += $validatedAddresses.count

                        # Message for log
                        If ( $Script:settings.upload.excludeNotValidReceivers -eq $true) {
                            $strRemovingInvalid = "Removing invalid addresses"
                        } else {
                            $strRemovingInvalid = "Not removing invalid addresses"
                        }
                        Write-Log "  $( $validatedAddresses.count ) returned valid addresses ( $strRemovingInvalid )"

                        # Remove invalid addresses, when turned on
                        If ( $Script:settings.upload.excludeNotValidReceivers -eq $true) {
                            $checkObject = [System.Collections.ArrayList]@( $checkObject | Where-Object { $_.email -in $validatedAddresses } )
                        }

                    }

                    Write-Log "  $( $checkObject.count ) left rows"

                    $checkObject = [System.Collections.ArrayList]@( $checkObject | Where-Object { $_.email -notin $exclusionList } )

                    Write-Log "  $( $checkObject.count ) left rows after using exclusion list"

                    # Add checked objects to uploadobject
                    [void]$uploadObject.AddRange( $checkObject )

                    # Clear the current object completely
                    $checkObject.Clear()

                }

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

                            # As a response we get the full profiles of the receivers back
                            $upload = @( Invoke-CR -Object "groups" -Path "/$( $groupId )/receivers/upsertplus" -Method POST -Verbose -Body $uploadBody )

                            # Count the successful upserted profiles
                            $j += $upload.count
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


            #-----------------------------------------------
            # GET GENERAL STATISTICS FOR LIST
            #-----------------------------------------------

            If ( $Script:settings.upload.loadRuntimeStatistics -eq $true ) {

                Write-Log "Getting stats for group $( $groupId )"

                #$groupStats = Invoke-CR -Object "groups" -Path "/$( $groupId )/stats" -Method GET -Verbose
                $groupStats = Get-GroupStatsByRuntime -GroupId $groupId #-IncludeMetrics -IncludeLastChanged -Verbose

                # <#
                # {
                #     "total_count": 4,
                #     "inactive_count": 0,
                #     "active_count": 4,
                #     "bounce_count": 0,
                #     "avg_points": 69.5,
                #     "quality": 3,
                #     "time": 1685545449,
                # }
                # #>

                $groupStats.psobject.properties | ForEach-Object {
                    Write-Log "  $( $_.Name ): $( $_.Value )"
                }

            }


            #-----------------------------------------------
            # GET STATISTICS FOR TAG
            #-----------------------------------------------

            Write-Log "Getting tag stats for tag $( $tags ) for group $( $groupId )"

            $tagQuery = [PSCustomObject]@{
                "tag" = $tags
                "group_id" = $groupId
                "active" = $true
            }
            $tagCount = 0
            $tagCount += Invoke-CR -Object "tags" -Path "/count" -Method GET -Verbose -Query $tagQuery

            Write-Log "Got confirmed $( $tagCount ) receivers for tag $( $tags ) in group $( $groupId )"



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

            If ( $tags.length -gt 0 ) {
                Write-Log "Uploaded $( $j ) record. Confirmed $( $tagcount ) receivers with tag '$( $tags )'" -severity INFO
            }

        }


        #-----------------------------------------------
        # RETURN VALUES TO PEOPLESTAGE
        #-----------------------------------------------

        # count the number of successful upload rows
        $recipients = $j #$dataCsv.Count # TODO work out what to be saved

        # put in the source id as the listname
        $transactionId = "$( $groupId ) => $( $tags )" #$Script:processId #$targetGroup.targetGroupId # TODO or try to log the used tag?

        # return object
        $return = [Hashtable]@{

            # Mandatory return values
            "Recipients"=$recipients
            "TransactionId"=$transactionId

            # General return value to identify this custom channel in the broadcasts detail tables
            "CustomProvider"= $Script:settings.providername
            "ProcessId" = $Script:processId

            # More values for broadcast
            "Tag" = ( $tags -join ", " )
            "GroupId" = $groupId
            "PreheaderIsSet" = $preheaderIsSet

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




