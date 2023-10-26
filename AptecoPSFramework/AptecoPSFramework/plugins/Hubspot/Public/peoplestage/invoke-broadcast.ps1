



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


    }

    process {


        try {




        } catch {

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
        $recipients = 0

        # put in the source id as the listname
        $transactionId = $InputHashtable.ProcessId

        # return object
        $return = [Hashtable]@{

            # Mandatory return values
            "Recipients"=$recipients
            "TransactionId"=$transactionId

            # General return value to identify this custom channel in the broadcasts detail tables
            "CustomProvider"=  $Script:settings.providername
            "ProcessId" = $InputHashtable.ProcessId #$Script:processId

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




