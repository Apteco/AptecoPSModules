function Get-TelegramChannel {


    [CmdletBinding()]
    param (
         [Parameter(Mandatory = $true)][string]$Name        # Give the channel a name, this is the "identifier for this channel"
    )

    begin {

    }

    process {

        # Check if the telegram channel exists
        $channel = $null
        Get-Channel -Name $Name | Where-Object { $_.Type -eq "Telegram" } | ForEach-Object {
            $channel = $_
        }

        If ( $null -eq $channel ) {
            throw "Channel $( $Name ) not found!"
        }

        $channel

    }

    end {

    }

}