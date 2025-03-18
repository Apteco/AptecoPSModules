function Get-Channel {


    [CmdletBinding()]
    param (
         [Parameter(Mandatory = $true)][string]$Name        # Give the channel a name, this is the "identifier for this channel"
    )

    begin {

    }

    process {

        # Check if the telegram channel exists
        $channel = $null
        Get-NotificationChannels | Where-Object { $_.Name -eq $Name } | ForEach-Object {
            $channel = $_
        }

        If ( $null -eq $channel ) {
            throw "Channel $( $Name ) not found!"
        }

        # Return
        $channel

    }

    end {

    }
}