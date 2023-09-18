# $params =[Hashtable]@{
#     "Uri" = "https://requestly.dev/api/mockv2/helloworld?rq_uid=UyRFxSA8PHPgJg6VKNz2tQZYlI23"
# }

# TODO maybe put all http functions into one module

<#
$wr = @( Invoke-RestMethodWithErrorHandling -Params $params )
#>

function Invoke-RestMethodWithErrorHandling {
    [CmdletBinding()]
    param (
         [Parameter(Mandatory=$true)][Hashtable]$Params
        ,[Parameter(Mandatory=$false)][Array]$RetryHttpErrorList = [Array]@(502)    # http errors that should used for $maxTriesSpecific
        ,[Parameter(Mandatory=$false)][int]$MaxTriesSpecific = 3                    # Specific http errors that are catched, see $RetryHttpErrorList
        ,[Parameter(Mandatory=$false)][int]$MaxTriesGeneric = 1                     # Generic errors that are not specifically catched
        ,[Parameter(Mandatory=$false)][int]$MillisecondsDelay = 200                 # Delay for the case of an exception
    )

    begin {

        # Clear the error object
        $Error.Clear()
        $completed = $false

    }

    process {

        $response = $null
        while ($completed -ne $true) {

            try {

                $response = Invoke-RestMethod @Params -ErrorAction Stop
                $completed = $true

            } catch {

                $e = $_

                # parse the response code and body
                $errResponse = $e.Exception.Response
                $errBody = Import-ErrorForResponseBody -Err $e

                #$errResponse.StatusCode.value__ #= 502
                #$errResponse.StatusCode.ToString() # = "BadGateway"
                #$errResponse.ReasonPhrase # = "Bad Gateway"

                # retry if a specific http error happens
                if ( $RetryHttpErrorList -contains $errResponse.StatusCode.value__ ) {

                    # Exceeded all retries
                    if ($Error.Count -ge $MaxTriesSpecific) {
                        Write-Log -Message "Request $( $Error.Count ) failed with $( $errResponse.StatusCode.value__ ) $( $errResponse.StatusCode.ToString() ). Command failed the maximum number of $( $MaxTriesSpecific ) times."  -Severity WARNING
                        #Write-Log -Message $_.Exception.Message -Severity ERROR
                        Write-Log -Message "RESPONSE: $( ConvertTo-Json -InputObject $errBody -Depth 99 -Compress)" -Severity WARNING
                        throw $_.Exception

                    # Not all generic tries used yet, repeat
                    } else {
                        Write-Log -Message "Request $( $Error.Count ) failed with $( $errResponse.StatusCode.value__ ) $( $errResponse.StatusCode.ToString() ). Retrying in $( $MillisecondsDelay ) milliseconds." 
                        Start-Sleep -Milliseconds $MillisecondsDelay
                        Continue
                    }

                # generic problems
                } else {

                    # Exceeded all retries
                    if ($Error.Count -ge $MaxTriesGeneric) {
                        Write-Log -Message "Request $( $Error.Count ) failed. Command failed the maximum number of $( $MaxTriesGeneric ) times." -Severity WARNING
                        #Write-Log -Message $_.Exception.Message -Severity ERROR
                        Write-Log -Message "RESPONSE: $( ConvertTo-Json -InputObject $errBody -Depth 99 -Compress)"
                        throw $_.Exception

                    # Not all generic tries used yet, repeat
                    } else {
                        Write-Log -Message "Request $( $Error.Count ) failed. Retrying in $( $MillisecondsDelay ) milliseconds." -Severity WARNING
                        Start-Sleep -Milliseconds $MillisecondsDelay
                        Continue
                    }

                }

            }

        }

    }

    end {

        # Clear the error object
        $Error.Clear()

        # Return: Make sure it is not really null to imitate Invoke-RestMethod
        If ( $response -eq $null ) {
            [Array]@()
        } else {
            $response
        }

    }

}

#Invoke-RestMethodWithErrorHandling -Params $params