function Test-SFSCConnection {
    [CmdletBinding()]
    param (
    )

    begin {

    }

    process {

        try {

            $ttl = Invoke-CR -Object "debug" -Path "/ttl.json" -Method "GET" -Verbose

            Write-Log "Token is still valid for $( [math]::floor( $ttl.ttl/60/60 ) ) hours"

            If ( $ttl.ttl -le $Script:settings.login.refreshTtl ) {
                Write-Log "Token is less seconds valid than the defined threshold of $( $Script:settings.login.refreshTtl ) seconds!" -Severity WARNING
            }



        } catch {

            $msg = "Failed to connect to CleverReach, unauthorized or token is expired"
            Write-Log -Message $msg -Severity ERROR
            #Write-Log -Message $_.Exception -Severity ERROR
            throw [System.IO.InvalidDataException] $msg

            # TODO is exit needed here?

        }

    }

    end {

    }

}