function Get-Channel {

    [CmdletBinding()]
    param (

         [Parameter(Mandatory = $true)]
         [String]$Name        # Give the channel a name, this is the "identifier for this channel"

    )

    process {

        # Check if the telegram channel exists
        $channel = $null
        Get-NotificationChannel | Where-Object { $_.Name -like $Name } | ForEach-Object {
            $channel = $_
        }

        If ( $null -eq $channel ) {
            throw "Channel $( $Name ) not found!"
        }

        # Return
        $channel

    }

}