



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
            $groups = @( Get-CRGroups )  #Invoke-CR -Object "groups" -Method GET -Verbose

            Write-Log "Got $( $groups.count ) groups"
            $script:debug = $groups
            $previewGroups = [array]@( $groups | where-object { $_.name -eq $Script:settings.preview.previewGroupName } )
            #$script:debug = $previewGroups

            If ( $previewGroups.count -eq 1 ) {
                # Use that group
                $previewGroup = $previewGroups | select -first 1
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


            #-----------------------------------------------
            # CLEAR THAT GROUP
            #-----------------------------------------------

            #delete /v3/groups.json/{id}/clear 
            $clearedGroup = Invoke-CR -Object "groups" -Path "/$( $group.id )/clear" -Method DELETE

            Write-Log "Cleared the group '$( $group.name )' with id '$( $group.id )'"


            #-----------------------------------------------
            # CLEAR THAT GROUP
            #-----------------------------------------------

            #delete /v3/groups.json/{id}/clear 
            $clearedGroup = Invoke-CR -Object "groups" -Path "/$( $group.id )/clear" -Method DELETE

            Write-Log "Cleared the group '$( $group.name )' with id '$( $group.id )'"


            #-----------------------------------------------
            # PARSE RECEIVER
            #-----------------------------------------------

            # Parse recipient
            $testRecipient = Convertfrom-Json -InputObject $InputHashtable.TestRecipient

            # Add dummy urn field, if not avaiable
            $urnFieldName = "urn"
            $urnFieldCheck = $testRecipient.PsObject.Properties | where { $_.name -contains $urnFieldName }
            If ( $urnFieldCheck.Count -eq 0 ) {
                $testRecipient | Add-Member -MemberType NoteProperty -Name $urnFieldName -Value "123456789"
            } 
            

            #-----------------------------------------------
            # SYNCHRONISE ATTRIBUTES
            #-----------------------------------------------

            $requiredFields = @( "Email" , $urnFieldName) # not sure how to handle urn like $InputHashtable.UrnFieldName
            $reservedFields = @( $Script:settings.upload.reservedFields ) #@("tags")
            $headers = @( $requiredFields + $testRecipient.Personalisation.PsObject.Properties.Name )

            $attributeParam = [Hashtable]@{
                "reservedFields" = $reservedFields
                "requiredFields" = $requiredFields
                "csvAttributesNames" =  $headers #@( $requiredFields + $testRecipient.Personalisation.PsObject.Properties.Name ) #$csvAttributesNames
                "csvUrnFieldname" = $urnFieldName
                "responseUrnFieldname" = $Script:settings.responses.urnFieldName
                "groupId" = $group.id
            }
            
            $attributes = Sync-Attributes @attributeParam


            #-----------------------------------------------
            # PUT PREVIEW RECEIVER IN THAT GROUP
            #-----------------------------------------------

            $uploadEntry = [PSCustomObject]@{
                "email" = $testRecipient.Email
                "global_attributes" = [PSCustomObject]@{}
                "attributes" = [PSCustomObject]@{}
                "tags" = [Array]@()
            }

            $attributes.global | Where-Object { $_.name -in $headers } | ForEach-Object {

                $attrName = $_.name # using description now rather than name, because the comparison is made on descriptions
                $attrDescription = $_.description
                $value = $null

                $nameIndex = $headers.IndexOf($attrName)
                $descriptionIndex = $headers.IndexOf($attrDescription)
                # If nothing found, the index is -1
                If ( $nameIndex -ge 0) {
                    $value = $testRecipient.Personalisation.($attrName) #$values[$nameIndex]
                } elseif ( $descriptionIndex -ge 0 ) {
                    $value = $testRecipient.Personalisation.($attrDescription) #$values[$descriptionIndex]
                }

                If( $null -ne $value ) {
                    $uploadEntry.global_attributes | Add-Member -MemberType NoteProperty -Name $attrName -Value $value
                }

            }

            # New local attributes
            $attributes.new | ForEach-Object {

                $attrName = $_.name # using description now rather than name, because the comparison is made on descriptions
                $attrDescription = $_.description
                $value = $null

                $nameIndex = $headers.IndexOf($attrName)
                $descriptionIndex = $headers.IndexOf($attrDescription)
                # If nothing found, the index is -1
                If ( $nameIndex -ge 0) {
                    $value = $testRecipient.Personalisation.($attrName) #$values[$nameIndex]
                } elseif ( $descriptionIndex -ge 0 ) {
                    $value = $testRecipient.Personalisation.($attrDescription) #$values[$descriptionIndex]
                }

                If( $null -ne $value ) {
                    $uploadEntry.attributes | Add-Member -MemberType NoteProperty -Name $attrName -Value $value
                }
            }

            # Existing local attributes
            $usedAttributes = [System.Collections.ArrayList]@()
            $attributes.local | ForEach-Object {

                $attrName = $_.name # using description now rather than name, because the comparison is made on descriptions
                $attrDescription = $_.description
                $value = $null

                $nameIndex = $headers.IndexOf($attrName)
                $descriptionIndex = $headers.IndexOf($attrDescription)
                # If nothing found, the index is -1
                If ( $nameIndex -ge 0) {
                    $value = $testRecipient.Personalisation.($attrName) #$values[$nameIndex]
                } elseif ( $descriptionIndex -ge 0 ) {
                    $value = $testRecipient.Personalisation.($attrDescription) #$values[$descriptionIndex]
                }

                If( $null -ne $value ) {
                    [void]$usedAttributes.add($attrName)
                    $uploadEntry.attributes | Add-Member -MemberType NoteProperty -Name $attrName -Value $value
                }

            }
            
            #-----------------------------------------------
            # REMOVE ATTRIBUTES THAT ARE NOT NEEDED
            #-----------------------------------------------

            $localAttributes = @( (Invoke-CR -Object "attributes" -Method "GET" -Verbose -Query ( [PSCustomObject]@{ "group_id" = $group.id } )) )
            $notNeededAttributes = @( $localAttributes | where { $_.name -notin $usedAttributes } )
            #$script:plugindebug = $notNeededAttributes.name

            If ( $notNeededAttributes.count -gt 0 ) {

                Write-Log "Removing attributes, if not needed"
                $notNeededAttributes | ForEach-Object {

                    $att = $_
                    Write-Log "  $( $att.name ) ($( $att.id ))"
                    $del += Invoke-CR -Object "attributes" -Method "DELETE" -Verbose -Path "/$( $att.id )"

                }

            }
            
            
            

            #-----------------------------------------------
            # UP- AND DOWNLOAD RECEIVER
            #-----------------------------------------------

            # TODO Implement downloading the receiver
            $uploadBody = @( $uploadEntry )
            #$script:plugindebug = $uploadBody
                        
            # Output the request body for debug purposes
            Write-Log -Message "Debug Mode: $( $Script:debugMode )"
            If ( $Script:debugMode -eq $true ) {
                $tempFile = ".\$( $i )_$( [guid]::NewGuid().tostring() )_request.txt"
                Set-Content -Value ( ConvertTo-Json $uploadBody -Depth 99 ) -Encoding UTF8 -Path $tempFile
            }
            
            # As a response we get the full profiles of the receiver back
            $upload = @( Invoke-CR -Object "groups" -Path "/$( $group.id )/receivers/upsertplus" -Method POST -Verbose -Body $uploadBody )
            
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
            #$testRecipient = $upload #Convertfrom-Json -InputObject $InputHashtable.TestRecipient
            #$script:debug = $InputHashtable
            $previewParameters = [PSCustomObject]@{
                "subject" = $templateSource.subject #"&quot;Gleich 4 neue Whitepaper auf einen Schlag für dich, {FIRSTNAME}!&quot;"
                "html" = $templateSource.body_html #"<html><body>Hello {FIRSTNAME}</body></html>"
                "text" = $templateSource.body_text #""
                "receiver" = $upload[0] # Get the first element as we should not send an array
            }
            $previewParametersJson = Convertto-json -InputObject $previewParameters -Depth 99
            #$script:plugindebug = $previewParametersJson

            #$renderedPreview = Invoke-CR -Object "gomailer" -Path "/preview" -Method POST -Verbose -body $previewParameters
            $renderedPreview = Invoke-RestMethod -Uri "https://rest.cleverreach.com/gomailer/preview" -ContentType $Script:settings.contentType -body $previewParametersJson -Verbose -Method POST

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




