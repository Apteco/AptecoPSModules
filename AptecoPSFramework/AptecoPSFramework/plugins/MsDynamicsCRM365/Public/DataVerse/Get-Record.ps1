


function Get-Record {

    [CmdletBinding(DefaultParameterSetName='RecordSet')]
    param (
         [Parameter(Mandatory=$true)][String]$TableName
        ,[Parameter(Mandatory=$false)][Switch]$ResolveLookups = $false

        ,[Parameter(Mandatory=$false,ParameterSetName='RecordSet')][int]$Top = 0
        #,[Parameter(Mandatory=$false,ParameterSetName='RecordSet')][int]$Skip = 0
        ,[Parameter(Mandatory=$false,ParameterSetName='RecordSet')][String]$Filter = ""
        ,[Parameter(Mandatory=$false,ParameterSetName='RecordSet')][String]$Expand = ""
        #,[Parameter(Mandatory=$false,ParameterSetName='RecordSet')][String]$Search = ""
        ,[Parameter(Mandatory=$false,ParameterSetName='RecordSet')][String[]]$Select = ""
        ,[Parameter(Mandatory=$false,ParameterSetName='RecordSet')][String[]]$OrderBy = ""
        ,[Parameter(Mandatory=$false,ParameterSetName='RecordSet')][Switch]$Count = $false
        ,[Parameter(Mandatory=$false,ParameterSetName='RecordSet')][Switch]$Paging = $false
        ,[Parameter(Mandatory=$false,ParameterSetName='RecordSet')][Switch]$DeltaTracking = $false

        ,[Parameter(Mandatory=$false,ParameterSetName='RecordById')][String]$Id = ""
        #,[Parameter(Mandatory=$false,ParameterSetName='RecordsById')][String[]]$Id = ""

        ,[Parameter(Mandatory=$false,ParameterSetName='RecordByDelta')][Switch]$LoadDelta = $false


    )

    begin {

        #-----------------------------------------------
        # DEBUG / NOTES
        #-----------------------------------------------

        Write-Verbose $PSCmdlet.ParameterSetName -verbose

        <#

            TODO implement oData options https://learn.microsoft.com/en-us/odata/concepts/queryoptions-overview
            https://learn.microsoft.com/de-de/power-apps/developer/data-platform/webapi/query-data-web-api
            https://github.com/MicrosoftDocs/powerapps-docs/blob/main/powerapps-docs/developer/data-platform/webapi/web-api-query-data-sample.md
            [x] $filter
            [x] $select
            [x] $expand
            [x] $orderby
            [x] $top
            [x] $count
            [ ] $apply -> used to aggregate data, not needed now
            [x] $skip -> not supported in dynamics
            [x] $search -> not supported in dynamics


        #>

        #-----------------------------------------------
        # DEFAULT OUTPUT
        #-----------------------------------------------

        $records = [Array]@()


        #-----------------------------------------------
        # DEFAULT PARAMETERS
        #-----------------------------------------------

        $callParams = [Hashtable]@{
            "Method" = "GET"
        }
        $preferOptions = [System.Collections.ArrayList]@()

        # Resolve GUIDS with lookup values
        If ( $ResolveLookups -eq $true ) {
            [void]$preferOptions.add('odata.include-annotations="*"')
            #'odata.include-annotations="OData.Community.Display.V1.FormattedValue"'
            # also available: "Microsoft.Dynamics.CRM.associatednavigationproperty,Microsoft.Dynamics.CRM.lookuplogicalname"
        }

        If ( $Count -eq $true) {
            [void]$preferOptions.add("odata.maxpagesize=1")
        }

        If ( $Paging -eq $true ) {
            [void]$preferOptions.add("odata.maxpagesize=3")
        }

        If ( $DeltaTracking -eq $true ) {
            [void]$preferOptions.add("odata.track-changes")
        }

        If ( $preferOptions.count -gt 0 ) {
            $header = [Hashtable]@{
                "Prefer" = ( $preferOptions -join ", " ) #'odata.include-annotations="*", odata.maxpagesize=2'
                #"Prefer" = 'odata.include-annotations="OData.Community.Display.V1.FormattedValue"' # also available: "Microsoft.Dynamics.CRM.associatednavigationproperty,Microsoft.Dynamics.CRM.lookuplogicalname"
            }
            $callParams.Add("Headers", $header)
        }


        #-----------------------------------------------
        # GET DELTALINKS
        #-----------------------------------------------

        $deltaTrackingFile = ".\deltalinks.json" # TODO put this into settings?
        If ( $DeltaTracking -eq $true -or $PSCmdlet.ParameterSetName -eq "RecordByDelta") {

            # Load the file, if existing, otherwise create a new object
            If ( (Test-Path -Path $deltaTrackingFile) -eq $true ) {
                $deltaLinks = Get-Content -Path $deltaTrackingFile -Encoding UTF8 -Raw | convertfrom-json
            } else {
                $deltaLinks = [PSCustomObject]@{}
            }

        }


    }

    process {


        #-----------------------------------------------
        # LOAD RECORD(S)
        #-----------------------------------------------

        Switch ( $PSCmdlet.ParameterSetName ) {

            #-----------------------------------------------
            # LOAD RECORDSET
            #-----------------------------------------------

            # Load multiple records
            "RecordSet" {

                #-----------------------------------------------
                # BUILD THE QUERY
                #-----------------------------------------------

                $query = [PSCustomObject]@{}

                If ( $Top -ne 0 ) {
                    $query | Add-Member -MemberType NoteProperty -Name '$top' -Value $Top
                }

                # If ( $Skip -ne 0 ) {
                #     $query | Add-Member -MemberType NoteProperty -Name '$skip' -Value $Skip
                # }

                If ( $Filter -ne "" ) {
                    $query | Add-Member -MemberType NoteProperty -Name '$filter' -Value $Filter
                }

                If ( $Expand -ne "" ) {
                    $query | Add-Member -MemberType NoteProperty -Name '$expand' -Value $Expand
                }

                # If ( $Search -ne "" ) {
                #     $query | Add-Member -MemberType NoteProperty -Name '$search' -Value $Search
                # }

                If ( $Select -ne "" ) {
                    $query | Add-Member -MemberType NoteProperty -Name '$select' -Value ( $Select -join "," )
                }

                If ( $OrderBy -ne "" ) {
                    $query | Add-Member -MemberType NoteProperty -Name '$orderby' -Value ( $OrderBy -join ", " )
                }

                If ( $Count -eq $true ) {
                    $query | Add-Member -MemberType NoteProperty -Name '$count' -Value "true"
                }


                #-----------------------------------------------
                # BUILD QUERY
                #-----------------------------------------------

                If (( $query.psobject.properties ).count -gt 0 ) {
                    $callParams.Add("Query", $query)
                }


                #-----------------------------------------------
                # DEFINE THE PATH AND PAGING AND EXECUTE THE CALL
                #-----------------------------------------------

                # Add path
                $callParams.Add("Path", $TableName)

                # Activate paging, if used
                If ( $Paging -eq $true ) {
                    $callParams.Add("Paging", $true)
                }

                # Execute the call
                $records = Invoke-Dynamics @callParams #@( ( Invoke-Dynamics @callParams ).value )


                #-----------------------------------------------
                # CHOOSE WHICH DATA TO RETURN
                #-----------------------------------------------

                If ( $Count -eq $true ) {
                    $return = $records."@odata.count"
                } else {
                    $return = $records.value
                    # If ( $Paging -eq $true ) {
                    #     $return = $records
                    # } else {
                    #     $return = $records.value
                    # }
                }


                #-----------------------------------------------
                # SAVE DELTA LINK, IF USED
                #-----------------------------------------------

                If ( $DeltaTracking -eq $true ) {

                    # Overwrite existing value or create a new one
                    If ( $deltaLinks.PSObject.Properties.Name -contains $TableName ) {
                        $deltaLinks.$TableName = $records."@odata.deltaLink"
                    } else {
                        $deltaLinks | Add-Member -MemberType NoteProperty -Name $TableName -Value $records."@odata.deltaLink"
                    }

                    # Save that file
                    ConvertTo-Json -InputObject $deltaLinks | Set-Content -Path $deltaTrackingFile -Encoding UTF8

                }


            }


            #-----------------------------------------------
            # LOAD DELTA
            #-----------------------------------------------

            "RecordByDelta" {

                $query = [PSCustomObject]@{}

                #-----------------------------------------------
                # CHANGE PARAMETERS, IF WE USE DELTAS
                #-----------------------------------------------

                If ( $deltaLinks.psobject.properties.name -contains $TableName ) {

                    #@odata.deltaLink : [uri]'https://orgbdda5a9d.crm11.dynamics.com/api/data/v9.2/contacts?$select=fullname,lastname&$deltatoken=4949752%2110%2f20%2f2023%2014%3a55%3a21'
                    #$table = $u.segments[-1]
                    $deltalink = [uri]$deltaLinks.$TableName
                    $deltaQuery = [System.Web.HttpUtility]::ParseQueryString($deltalink.Query)

                    $query | Add-Member -MemberType NoteProperty -Name '$select' -Value $deltaQuery['$select']
                    $query | Add-Member -MemberType NoteProperty -Name '$deltatoken' -Value $deltaQuery['$deltatoken']

                    If (( $query.psobject.properties ).count -gt 0 ) {
                        $callParams.Add("Query", $query)
                    }

                    # Activate paging for deltaload
                    $callParams.Add("Paging", $true)

                } else {

                    $msg = "There is no deltalink for your table available"
                    Write-Log -severity ERROR -Message $msg
                    throw $msg

                }


                #-----------------------------------------------
                # DEFINE THE PATH AND PAGING AND EXECUTE THE CALL
                #-----------------------------------------------

                # Add path
                $callParams.Add("Path", $TableName)

                # Execute the call
                $records = Invoke-Dynamics @callParams #@( ( Invoke-Dynamics @callParams ).value )

                # Return value
                $return = $records.value
                #$Script:pluginDebug = $records

                #-----------------------------------------------
                # SAVE DELTA LINK, IF USED
                #-----------------------------------------------

                # Overwrite existing value or create a new one
                If ( $deltaLinks.PSObject.Properties.Name -contains $TableName ) {
                    $deltaLinks.$TableName = $records."@odata.deltaLink"
                } else {
                    $deltaLinks | Add-Member -MemberType NoteProperty -Name $TableName -Value $records."@odata.deltaLink"
                }

                # Save that file
                ConvertTo-Json -InputObject $deltaLinks | Set-Content -Path $deltaTrackingFile -Encoding UTF8


            }


            #-----------------------------------------------
            # LOAD SINGLE RECORD
            #-----------------------------------------------

            "RecordById" {

                #-----------------------------------------------
                # DEFINE THE PATH AND EXECUTE THE CALL
                #-----------------------------------------------

                $callParams.Add("Path", "$( $TableName )($( $Id ))")

                #If ( (Test-IsGuid -StringGuid $Id) -eq $true ) {
                    $return = Invoke-Dynamics @callParams
                #}

            }

            # "RecordsById" {
                # TODO not implemented yet
            # }

        }


        #-----------------------------------------------
        # RETURN
        #-----------------------------------------------

        $return


    }

    end {

    }

}

